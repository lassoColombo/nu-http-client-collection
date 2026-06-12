# Auto-generated client for Together APIs v2.0.0
# Source: https://docs.together.ai/openapi.yaml
# Auth: --token flag or $env.TOGETHER_APIS_TOKEN

const BASE_URL = "https://api.together.ai/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TOGETHER_APIS_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.together.ai/v1" "https://api.together.ai/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def gpu-type-completer [] { ["b200-192gb" "h100-40gb-mig" "h100-80gb" "h200-140gb"] }
def output-format-completer [] { ["MP4" "WEBM"] }
def context-length-exceeded-behavior-completer [] { ["error" "truncate"] }
def reasoning-effort-completer [] { ["high" "low" "medium"] }
def accept-completer [] { ["application/json" "text/event-stream"] }
def model-type-completer [] { ["adapter" "model"] }
def response-format-completer [] { ["base64" "url"] }
def output-format-completer-1 [] { ["jpeg" "png"] }
def purpose-completer [] { ["batch-api" "eval" "fine-tune"] }
def file-type-completer [] { ["csv" "jsonl" "parquet"] }
def checkpoint-completer [] { ["adapter" "merged" "model_output_path"] }
def response-format-completer-1 [] { ["mp3" "raw" "wav"] }
def response-encoding-completer [] { ["pcm_alaw" "pcm_f32le" "pcm_mulaw" "pcm_s16le"] }
def bit-rate-completer [] { ["128000" "192000" "32000" "64000" "96000"] }
def accept-completer-1 [] { ["application/octet-stream" "audio/mpeg" "audio/wav" "text/event-stream"] }
def model-completer [] { ["cartesia/sonic-english" "hexgrad/Kokoro-82M"] }
def model-completer-1 [] { ["openai/whisper-large-v3"] }
def response-format-completer-2 [] { ["json" "verbose_json"] }
def cluster-type-completer [] { ["KUBERNETES" "SLURM"] }
def gpu-type-completer-1 [] { ["B200_SXM" "H100_SXM" "H100_SXM_INF" "H200_SXM" "L40_PCIE" "RTX_6000_PCI"] }
def billing-type-completer [] { ["ON_DEMAND" "RESERVED" "SCHEDULED_CAPACITY"] }
def type-completer [] { ["dedicated" "serverless"] }
def usage-type-completer [] { ["on-demand" "reserved"] }
def state-completer [] { ["STARTED" "STOPPED"] }
def language-completer [] { ["python"] }
def endpoint-completer [] { ["/v1/audio/transcriptions" "/v1/audio/translations" "/v1/chat/completions"] }
def type-completer-1 [] { ["classify" "compare" "score"] }
def input-audio-format-completer [] { ["pcm_s16le_16000"] }
def status-completer [] { ["MODEL_RESOURCES_STATUS_CREATING" "MODEL_RESOURCES_STATUS_DELETED" "MODEL_RESOURCES_STATUS_DELETING" "MODEL_RESOURCES_STATUS_ERROR" "MODEL_RESOURCES_STATUS_READY"] }
def type-completer-2 [] { ["SESSION_TYPE_TRAINER_AND_GENERATOR" "SESSION_TYPE_TRAINER_ONLY" "SESSION_TYPE_UNSPECIFIED"] }
def status-completer-1 [] { ["TRAINING_SESSION_STATUS_CREATING" "TRAINING_SESSION_STATUS_ERROR" "TRAINING_SESSION_STATUS_EXPIRED" "TRAINING_SESSION_STATUS_RUNNING" "TRAINING_SESSION_STATUS_STOPPED" "TRAINING_SESSION_STATUS_STOPPING" "TRAINING_SESSION_STATUS_UNSPECIFIED"] }
def variant-completer [] { ["CHECKPOINT_VARIANT_ADAPTER" "CHECKPOINT_VARIANT_MERGED" "CHECKPOINT_VARIANT_UNSPECIFIED"] }
def mode-completer [] { ["REMEDIATION_MODE_EVICT_WITHOUT_REPLACEMENT" "REMEDIATION_MODE_HOST_AWARE" "REMEDIATION_MODE_REBOOT_VM" "REMEDIATION_MODE_VM_ONLY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "deployments list" } } | get name | first)
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

# Get the list of deployments
#
# GET /deployments
export def "deployments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<args: list, autoscaling: any, command: list, cpu: float, created_at: string, description: string, desired_replicas: int, environment_variables: list, gpu_count: int, gpu_type: string, health_check_path: string, id: string, image: string, max_replicas: int, memory: float, min_replicas: int, name: string, object: any, port: int, ready_replicas: int, replica_events: record, status: record, storage: int, termination_grace_period_seconds: int, updated_at: string, volumes: list>, object: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new deployment
#
# POST /deployments
# --environment_variables item shape: {name: string, value?: string, value_from_secret?: string}
# --volumes item shape: {mount_path: string, name: string, version?: int}
export def "deployments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --args: list # Args overrides the container's CMD. Provide as an array of arguments (e.g., ["python", "app.py"])
  --autoscaling: any # Autoscaling configuration. Example: {"metric": "QueueBacklogPerWorker", "target": 1.01} to scale based on queue backlog. Omit or set to null to disable autoscaling
  --command: list # Command overrides the container's ENTRYPOINT. Provide as an array (e.g., ["/bin/sh", "-c"])
  --cpu: float # CPU is the number of CPU cores to allocate per container instance (e.g., 0.1 = 100 milli cores)
  --description: string # Description is an optional human-readable description of your deployment
  --environment-variables: list # EnvironmentVariables is a list of environment variables to set in the container. Each must have a name and either a value or value_from_secret — item shape: {name: string, value?: string, value_from_secret?: string}
  --gpu-count: int # GPUCount is the number of GPUs to allocate per container instance. Defaults to 0 if not specified
  gpu_type: string@gpu-type-completer # GPUType specifies the GPU hardware to use (e.g., "h100-80gb").
  --health-check-path: string # HealthCheckPath is the HTTP path for health checks (e.g., "/health"). If set, the platform checks this endpoint to determine container health.
  image: string # Image is the container image to deploy from registry.together.ai.
  --max-replicas: int # MaxReplicas is the maximum number of container instances. Defaults to MinReplicas if not set.
  --memory: float # Memory is the amount of RAM to allocate per container instance in GiB (e.g., 0.5 = 512MiB)
  --min-replicas: int # MinReplicas is the minimum number of container instances to run. Defaults to 1 if not specified
  name: string # Name is the unique identifier for your deployment. Must contain only alphanumeric characters, underscores, or hyphens (1-100 characters)
  --port: int # Port is the container port your application listens on (e.g., 8080 for web servers). Required if your application serves traffic
  --storage: int # Storage is the amount of ephemeral disk storage to allocate per container instance (e.g., 10 = 10GiB)
  --termination-grace-period-seconds: int # TerminationGracePeriodSeconds is the time in seconds to wait for graceful shutdown before forcefully terminating the replica
  --volumes: list # Volumes is a list of volume mounts to attach to the container. Each mount must reference an existing volume by name — item shape: {mount_path: string, name: string, version?: int}
]: any -> record<args: list<string>, autoscaling: any, command: list<string>, cpu: float, created_at: string, description: string, desired_replicas: int, environment_variables: table<name: string, value: string, value_from_secret: string>, gpu_count: int, gpu_type: string, health_check_path: string, id: string, image: string, max_replicas: int, memory: float, min_replicas: int, name: string, object: any, port: int, ready_replicas: int, replica_events: record, status: record, storage: int, termination_grace_period_seconds: int, updated_at: string, volumes: table<mount_path: string, name: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments")
  let body = {args: $args, autoscaling: $autoscaling, command: $command, cpu: $cpu, description: $description, environment_variables: $environment_variables, gpu_count: $gpu_count, gpu_type: $gpu_type, health_check_path: $health_check_path, image: $image, max_replicas: $max_replicas, memory: $memory, min_replicas: $min_replicas, name: $name, port: $port, storage: $storage, termination_grace_period_seconds: $termination_grace_period_seconds, volumes: $volumes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a deployment
#
# DELETE /deployments/{id}
export def "deployments delete" [
  id: string
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
  let full_url = (build-url $base $"/deployments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a deployment by ID or name
#
# GET /deployments/{id}
export def "deployments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<args: list<string>, autoscaling: any, command: list<string>, cpu: float, created_at: string, description: string, desired_replicas: int, environment_variables: table<name: string, value: string, value_from_secret: string>, gpu_count: int, gpu_type: string, health_check_path: string, id: string, image: string, max_replicas: int, memory: float, min_replicas: int, name: string, object: any, port: int, ready_replicas: int, replica_events: record, status: record, storage: int, termination_grace_period_seconds: int, updated_at: string, volumes: table<mount_path: string, name: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a deployment
#
# PATCH /deployments/{id}
# --environment_variables item shape: {name: string, value?: string, value_from_secret?: string}
# --volumes item shape: {mount_path: string, name: string, version?: int}
export def "deployments patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --args: list # Args overrides the container's CMD. Provide as an array of arguments (e.g., ["python", "app.py"])
  --autoscaling: any # Autoscaling configuration for the deployment. Set to {} to disable autoscaling
  --command: list # Command overrides the container's ENTRYPOINT. Provide as an array (e.g., ["/bin/sh", "-c"])
  --cpu: float # CPU is the number of CPU cores to allocate per container instance (e.g., 0.1 = 100 milli cores)
  --description: string # Description is an optional human-readable description of your deployment
  --environment-variables: list # EnvironmentVariables is a list of environment variables to set in the container. Replaces all existing environment variables. — item shape: {name: string, value?: string, value_from_secret?: string}
  --gpu-count: int # GPUCount is the number of GPUs to allocate per container instance
  --gpu-type: string@gpu-type-completer # GPUType specifies the GPU hardware to use (e.g., "h100-80gb")
  --health-check-path: string # HealthCheckPath is the HTTP path for health checks (e.g., "/health"). Set to empty string to disable health checks
  --image: string # Image is the container image to deploy from registry.together.ai.
  --max-replicas: int # MaxReplicas is the maximum number of replicas that can be scaled up to.
  --memory: float # Memory is the amount of RAM to allocate per container instance in GiB (e.g., 0.5 = 512MiB)
  --min-replicas: int # MinReplicas is the minimum number of replicas to run
  --name: string # Name is the new unique identifier for your deployment. Must contain only alphanumeric characters, underscores, or hyphens (1-100 characters)
  --port: int # Port is the container port your application listens on (e.g., 8080 for web servers)
  --storage: int # Storage is the amount of ephemeral disk storage to allocate per container instance (e.g., 10 = 10GiB)
  --termination-grace-period-seconds: int # TerminationGracePeriodSeconds is the time in seconds to wait for graceful shutdown before forcefully terminating the replica
  --volumes: list # Volumes is a list of volume mounts to attach to the container. Replaces all existing volumes. — item shape: {mount_path: string, name: string, version?: int}
]: any -> record<args: list<string>, autoscaling: any, command: list<string>, cpu: float, created_at: string, description: string, desired_replicas: int, environment_variables: table<name: string, value: string, value_from_secret: string>, gpu_count: int, gpu_type: string, health_check_path: string, id: string, image: string, max_replicas: int, memory: float, min_replicas: int, name: string, object: any, port: int, ready_replicas: int, replica_events: record, status: record, storage: int, termination_grace_period_seconds: int, updated_at: string, volumes: table<mount_path: string, name: string, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($id)")
  let body = {args: $args, autoscaling: $autoscaling, command: $command, cpu: $cpu, description: $description, environment_variables: $environment_variables, gpu_count: $gpu_count, gpu_type: $gpu_type, health_check_path: $health_check_path, image: $image, max_replicas: $max_replicas, memory: $memory, min_replicas: $min_replicas, name: $name, port: $port, storage: $storage, termination_grace_period_seconds: $termination_grace_period_seconds, volumes: $volumes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get logs for a deployment
#
# GET /deployments/{id}/logs
export def "deployments-logs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --replica-id: string
  --version: string
  --revision: string
]: nothing -> record<lines: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replica_id" $replica_id "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "revision" $revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/($id)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of project secrets
#
# GET /deployments/secrets
export def "deployments-secrets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<created_at: string, created_by: string, description: string, id: string, last_updated_by: string, name: string, object: any, updated_at: string>, object: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments/secrets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new secret
#
# POST /deployments/secrets
export def "deployments-secrets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description is an optional human-readable description of the secret's purpose (max 500 characters)
  name: string # Name is the unique identifier for the secret. Can contain alphanumeric characters, underscores, hyphens, forward slashes, and periods (1-100 characters)
  --project-id: string # ProjectID is ignored - the project is automatically determined from your authentication
  value: string # Value is the sensitive data to store securely (e.g., API keys, passwords, tokens). Encrypted at rest.
]: any -> record<created_at: string, created_by: string, description: string, id: string, last_updated_by: string, name: string, object: any, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments/secrets")
  let body = {description: $description, name: $name, project_id: $project_id, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a secret
#
# DELETE /deployments/secrets/{id}
export def "deployments-secrets delete" [
  id: string
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
  let full_url = (build-url $base $"/deployments/secrets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a secret by ID or name
#
# GET /deployments/secrets/{id}
export def "deployments-secrets get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, created_by: string, description: string, id: string, last_updated_by: string, name: string, object: any, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/secrets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a secret
#
# PATCH /deployments/secrets/{id}
export def "deployments-secrets patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description is an optional human-readable description of the secret's purpose (max 500 characters)
  --name: string # Name is the new unique identifier for the secret. Can contain alphanumeric characters, underscores, hyphens, forward slashes, and periods (1-100 characters)
  --project-id: string # ProjectID is ignored - the project is automatically determined from your authentication
  --value: string # Value is the new sensitive data to store securely. Updating this replaces the existing secret value.
]: any -> record<created_at: string, created_by: string, description: string, id: string, last_updated_by: string, name: string, object: any, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/secrets/($id)")
  let body = {description: $description, name: $name, project_id: $project_id, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Download a file
#
# GET /deployments/storage/{filename}
export def "deployments-storage get" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/storage/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a file download URL
#
# GET /deployments/storage/{filename}/url
export def "deployments-storage-url get" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/storage/($filename)/url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of project volumes
#
# GET /deployments/storage/volumes
export def "deployments-storage-volumes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<content: record, created_at: string, current_version: int, id: string, mounted_by: list, name: string, object: string, type: string, updated_at: string, version_history: record>, object: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments/storage/volumes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new volume
#
# POST /deployments/storage/volumes
export def "deployments-storage-volumes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: any # Content specifies the content configuration for this volume
  name: string # Name is the unique identifier for the volume within the project
  type: any # Type is the volume type (currently only "readOnly" is supported)
]: any -> record<content: record<files: list<record>, source_prefix: string, type: string>, created_at: string, current_version: int, id: string, mounted_by: list<string>, name: string, object: string, type: string, updated_at: string, version_history: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments/storage/volumes")
  let body = {content: $content, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a volume
#
# DELETE /deployments/storage/volumes/{id}
export def "deployments-storage-volumes delete" [
  id: string
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
  let full_url = (build-url $base $"/deployments/storage/volumes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a volume by ID or name
#
# GET /deployments/storage/volumes/{id}
export def "deployments-storage-volumes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int
]: nothing -> record<content: record<files: list<record>, source_prefix: string, type: string>, created_at: string, current_version: int, id: string, mounted_by: list<string>, name: string, object: string, type: string, updated_at: string, version_history: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployments/storage/volumes/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a volume
#
# PATCH /deployments/storage/volumes/{id}
export def "deployments-storage-volumes patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: any # Content specifies the new content to preload to this volume.
  --name: string # Name is the new unique identifier for the volume within the project
  --type: any # Type is the new volume type (currently only "readOnly" is supported)
]: any -> record<content: record<files: list<record>, source_prefix: string, type: string>, created_at: string, current_version: int, id: string, mounted_by: list<string>, name: string, object: string, type: string, updated_at: string, version_history: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/storage/volumes/($id)")
  let body = {content: $content, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch available voices for each model
#
# GET /voices
# operationId: fetchVoices
export def "voices fetchVoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<model: string, voices: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/voices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch video metadata
#
# GET /videos/{id}
# operationId: retrieveVideo
export def "videos retrieveVideo" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: any, model: string, status: string, created_at: float, completed_at: float, size: string, seconds: string, error: record<code: string, message: string>, outputs: record<cost: int, video_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.together.ai/v2")
  let full_url = (build-url $base $"/videos/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create video
#
# POST /videos
# operationId: createVideo
# --media shape: {frame_images?: list, frame_videos?: list, reference_images?: list, reference_videos?: list, source_video?: any, audio_inputs?: list}
# --frame_images item shape: {input_image: string, frame?: any}
@deprecated --flag frame-images
@deprecated --flag reference-images
export def "videos createVideo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  model: string # The model to be used for the video creation request.
  --prompt: string # Text prompt that describes the video to generate.
  --height: int
  --width: int
  --resolution: string # Video resolution.
  --ratio: string # Aspect ratio of the video.
  --seconds: string # Clip duration in seconds.
  --fps: int # Frames per second. Defaults to 24.
  --steps: int # The number of denoising steps the model performs during video generation. More steps typically result in higher quality output but require longer processing time.
  --seed: int # Seed to use in initializing the video generation.  Using the same seed allows deterministic video generation.  If not provided a random seed is generated for each request.
  --guidance-scale: int # Controls how closely the video generation follows your prompt. Higher values make the model adhere more strictly to your text description, while lower values allow more creative freedom. guidence_scale affects both visual content and temporal consistency.Recommended range is 6.0-10.0 for most video models. Values above 12 may cause over-guidance artifacts or unnatural motion patterns.
  --output-format: string@output-format-completer
  --output-quality: int # Compression quality. Defaults to 20.
  --negative-prompt: string # Similar to prompt, but specifies what to avoid instead of what to include
  --generate-audio: oneof<nothing, bool> # Whether to generate audio for the video.
  --media: record # Contains all media inputs for video generation. Accepted fields depend on the model type. — shape: {frame_images?: list, frame_videos?: list, reference_images?: list, reference_videos?: list, source_video?: any, audio_inputs?: list}
  --frame-images: list # Deprecated: use media.frame_images instead. Array of images to guide video generation, similar to keyframes. (DEPRECATED, e.g. [[{input_image: aac49721-1964-481a-ae78-8a4e29b91402, frame: 0}, {input_image: c00abf5f-6cdb-4642-a01d-1bfff7bc3cf7, frame: 48}, {input_image: 3ad204c3-a9de-4963-8a1a-c3911e3afafe, frame: last}]]) — item shape: {input_image: string, frame?: any}
  --reference-images: list # Deprecated: use media.reference_images instead. Unlike frame_images which constrain specific timeline positions, reference images guide the general appearance that should appear consistently across the video. (DEPRECATED)
]: any -> record<id: string, object: any, model: string, status: string, created_at: float, completed_at: float, size: string, seconds: string, error: record<code: string, message: string>, outputs: record<cost: int, video_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.together.ai/v2")
  let full_url = (build-url $base "/videos")
  let body = {model: $model, prompt: $prompt, height: $height, width: $width, resolution: $resolution, ratio: $ratio, seconds: $seconds, fps: $fps, steps: $steps, seed: $seed, guidance_scale: $guidance_scale, output_format: $output_format, output_quality: $output_quality, negative_prompt: $negative_prompt, generate_audio: $generate_audio, media: $media, frame_images: $frame_images, reference_images: $reference_images} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create chat completion
#
# POST /chat/completions
# operationId: chat-completions
# --tools item shape: {type?: string, function?: record}
# --reasoning shape: {enabled?: bool}
export def "chat-completions chat-completions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  messages: list # A list of messages comprising the conversation so far.
  model: string # The name of the model to query.<br> <br> [See all of Together AI's chat models](https://docs.together.ai/docs/serverless-models#chat-models)
  --max-tokens: int # The maximum number of tokens to generate.
  --stop: list # A list of string sequences that truncate (stop) inference text output. For example, "</s>" stops generation as soon as the model generates the given token.
  --temperature: float # A decimal number from 0-1 that determines the degree of randomness in the response. A temperature less than 1 favors more correctness and is appropriate for question answering or summarization. A value closer to 1 introduces more randomness in the output. (format: float)
  --top-p: float # A percentage (also called the nucleus parameter) that's used to dynamically adjust the number of choices for each predicted token based on the cumulative probabilities. It specifies a probability threshold below which all less likely tokens are filtered out. This technique helps maintain diversity and generate more fluent and natural-sounding text. (format: float)
  --top-k: int # An integer that's used to limit the number of choices for the next predicted word or token. It specifies the maximum number of tokens to consider at each step, based on their probability of occurrence. This technique helps to speed up the generation process and can improve the quality of the generated text by focusing on the most likely options. (format: int32)
  --context-length-exceeded-behavior: string@context-length-exceeded-behavior-completer # Defines the behavior of the API when max_tokens exceed the maximum context length of the model. When set to 'error', the API returns 400 with an appropriate error message. When set to 'truncate', overrides max_tokens with the maximum context length of the model. (default: error)
  --repetition-penalty: float # A number that controls the diversity of generated text by reducing the likelihood of repeated sequences. Higher values decrease repetition.
  --stream: oneof<nothing, bool> # If true, stream tokens as Server-Sent Events as the model generates them instead of waiting for the full model response. The stream terminates with `data: [DONE]`. If false, return a single JSON object containing the results.
  --logprobs: int # An integer between 0 and 20 of the top k tokens to return log probabilities for at each generation step, instead of only the sampled token. Log probabilities help assess model confidence in token predictions.
  --echo: oneof<nothing, bool> # If true, the response contains the prompt. Can be used with `logprobs` to return prompt logprobs.
  --n: int # The number of completions to generate for each prompt.
  --min-p: float # A number between 0 and 1 that can be used as an alternative to top_p and top-k. (format: float)
  --presence-penalty: float # A number between -2.0 and 2.0 where a positive value increases the likelihood of a model talking about new topics. (format: float)
  --frequency-penalty: float # A number between -2.0 and 2.0 where a positive value decreases the likelihood of repeating tokens that have already been mentioned. (format: float)
  --logit-bias: record # Adjusts the likelihood of specific tokens appearing in the generated output. (e.g. {105: 21.4, 1024: -10.5})
  --seed: int # Seed value for reproducibility. (e.g. 42)
  --function-call: any
  --response-format: any # An object specifying the format that the model must output.  Setting to `{ "type": "json_schema", "json_schema": {...} }` enables Structured Outputs which ensures the model will match your supplied JSON schema. Learn more in the [Structured Outputs guide](https://docs.together.ai/docs/json-mode).  Setting to `{ "type": "json_object" }` enables the older JSON mode, which ensures the message the model generates is valid JSON. Using `json_schema` is preferred for models that support it.
  --tools: list # A list of tools the model may call. Currently, only functions are supported as a tool. Use this to provide a list of functions the model may generate JSON inputs for. — item shape: {type?: string, function?: record}
  --tool-choice: any # Controls which (if any) function is called by the model. By default uses `auto`, which lets the model pick between generating a message or calling a function.
  --compliance: any
  --chat-template-kwargs: record # Additional configuration to pass to model engine.
  --safety-model: string # The name of the moderation model used to validate tokens. Choose from the available moderation models found [here](https://docs.together.ai/docs/inference-models#moderation-models). (e.g. safety_model_name)
  --reasoning-effort: string@reasoning-effort-completer # Controls the level of reasoning effort the model should apply when generating responses. Higher values may result in more thoughtful and detailed responses but may take longer to generate. (e.g. medium)
  --reasoning: record # For models that support toggling reasoning functionality, this object can be used to control that functionality. — shape: {enabled?: bool}
]: any -> record<id: string, choices: table<text: string, index: int, seed: int, finish_reason: string, message: record, logprobs: record, top_logprobs: record>, usage: record<prompt_tokens: int, completion_tokens: int, total_tokens: int>, created: int, model: string, prompt: table<text: string, logprobs: record>, object: any, warnings: table<message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat/completions")
  let body = {messages: $messages, model: $model, max_tokens: $max_tokens, stop: $stop, temperature: $temperature, top_p: $top_p, top_k: $top_k, context_length_exceeded_behavior: $context_length_exceeded_behavior, repetition_penalty: $repetition_penalty, stream: $stream, logprobs: $logprobs, echo: $echo, n: $n, min_p: $min_p, presence_penalty: $presence_penalty, frequency_penalty: $frequency_penalty, logit_bias: $logit_bias, seed: $seed, function_call: $function_call, response_format: $response_format, tools: $tools, tool_choice: $tool_choice, compliance: $compliance, chat_template_kwargs: $chat_template_kwargs, safety_model: $safety_model, reasoning_effort: $reasoning_effort, reasoning: $reasoning} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create completion
#
# POST /completions
# operationId: completions
export def "completions completions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  prompt: string # A string providing context for the model to complete. (e.g. <s>[INST] What is the capital of France? [/INST])
  model: string # The name of the model to query.<br> <br> [See all of Together AI's chat models](https://docs.together.ai/docs/serverless-models#chat-models)  (e.g. mistralai/Mixtral-8x7B-Instruct-v0.1)
  --max-tokens: int # The maximum number of tokens to generate.
  --stop: list # A list of string sequences that truncate (stop) inference text output. For example, "</s>" stops generation as soon as the model generates the given token.
  --temperature: float # A decimal number from 0-1 that determines the degree of randomness in the response. A temperature less than 1 favors more correctness and is appropriate for question answering or summarization. A value closer to 1 introduces more randomness in the output. (format: float)
  --top-p: float # A percentage (also called the nucleus parameter) that's used to dynamically adjust the number of choices for each predicted token based on the cumulative probabilities. It specifies a probability threshold below which all less likely tokens are filtered out. This technique helps maintain diversity and generate more fluent and natural-sounding text. (format: float)
  --top-k: int # An integer that's used to limit the number of choices for the next predicted word or token. It specifies the maximum number of tokens to consider at each step, based on their probability of occurrence. This technique helps to speed up the generation process and can improve the quality of the generated text by focusing on the most likely options. (format: int32)
  --repetition-penalty: float # A number that controls the diversity of generated text by reducing the likelihood of repeated sequences. Higher values decrease repetition. (format: float)
  --stream: oneof<nothing, bool> # If true, stream tokens as Server-Sent Events as the model generates them instead of waiting for the full model response. The stream terminates with `data: [DONE]`. If false, return a single JSON object containing the results.
  --logprobs: int # An integer between 0 and 20 of the top k tokens to return log probabilities for at each generation step, instead of only the sampled token. Log probabilities help assess model confidence in token predictions.
  --echo: oneof<nothing, bool> # If true, the response contains the prompt. Can be used with `logprobs` to return prompt logprobs.
  --n: int # The number of completions to generate for each prompt.
  --safety-model: string # The name of the moderation model used to validate tokens. Choose from the available moderation models found [here](https://docs.together.ai/docs/inference-models#moderation-models). (e.g. safety_model_name)
  --min-p: float # A number between 0 and 1 that can be used as an alternative to top-p and top-k. (format: float)
  --presence-penalty: float # A number between -2.0 and 2.0 where a positive value increases the likelihood of a model talking about new topics. (format: float)
  --frequency-penalty: float # A number between -2.0 and 2.0 where a positive value decreases the likelihood of repeating tokens that have already been mentioned. (format: float)
  --logit-bias: record # Adjusts the likelihood of specific tokens appearing in the generated output. (e.g. {105: 21.4, 1024: -10.5})
  --seed: int # Seed value for reproducibility. (e.g. 42)
]: any -> record<id: string, choices: table<text: string, seed: int, finish_reason: string, logprobs: record>, prompt: table<text: string, logprobs: record>, usage: record<prompt_tokens: int, completion_tokens: int, total_tokens: int>, created: int, model: string, object: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/completions")
  let body = {prompt: $prompt, model: $model, max_tokens: $max_tokens, stop: $stop, temperature: $temperature, top_p: $top_p, top_k: $top_k, repetition_penalty: $repetition_penalty, stream: $stream, logprobs: $logprobs, echo: $echo, n: $n, safety_model: $safety_model, min_p: $min_p, presence_penalty: $presence_penalty, frequency_penalty: $frequency_penalty, logit_bias: $logit_bias, seed: $seed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create embedding
#
# POST /embeddings
# operationId: embeddings
export def "embeddings embeddings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  model: string # The name of the embedding model to use.<br> <br> [See all of Together AI's embedding models](https://docs.together.ai/docs/serverless-models#embedding-models)  (e.g. togethercomputer/m2-bert-80M-8k-retrieval)
  input: any # e.g. Our solar system orbits the Milky Way galaxy at about 515,000 mph
]: any -> record<object: any, model: string, data: table<object: any, embedding: list, index: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/embeddings")
  let body = {model: $model, input: $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all models
#
# GET /models
# operationId: models
export def "models models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dedicated: oneof<nothing, bool>
]: nothing -> table<id: string, object: any, created: int, type: any, display_name: string, organization: string, link: string, license: string, context_length: int, pricing: record<base: float, finetune: float, hourly: float, input: float, output: float, cached_input: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dedicated" $dedicated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a custom model or adapter
#
# POST /models
# operationId: uploadModel
export def "models uploadModel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  model_name: string # The name to give to your uploaded model (e.g. Qwen2.5-72B-Instruct)
  model_source: string # The source location of the model (Hugging Face repo or S3 path) (e.g. unsloth/Qwen2.5-72B-Instruct)
  --model-type: string@model-type-completer # Whether the model is a full model or an adapter (default: model, e.g. model)
  --hf-token: string # Hugging Face token (if uploading from Hugging Face) (e.g. hf_examplehuggingfacetoken)
  --description: string # A description of your model (e.g. Finetuned Qwen2.5-72B-Instruct by Unsloth)
  --base-model: string # The base model to use for an adapter if setting it to run against a serverless pool.  Only used for model_type `adapter`. (e.g. Qwen/Qwen2.5-72B-Instruct)
  --lora-model: string # The lora pool to use for an adapter if setting it to run against, say, a dedicated pool.  Only used for model_type `adapter`. (e.g. my_username/Qwen2.5-72B-Instruct-lora)
]: any -> record<data: record<job_id: string, model_name: string, model_id: string, model_source: string>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/models")
  let body = {model_name: $model_name, model_source: $model_source, model_type: $model_type, hf_token: $hf_token, description: $description, base_model: $base_model, lora_model: $lora_model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get job status
#
# GET /jobs/{jobId}
# operationId: getJob
export def "jobs get" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, job_id: string, status: string, status_updates: table<status: string, message: string, timestamp: string>, args: record<description: string, modelName: string, modelSource: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jobs/($jobId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all jobs
#
# GET /jobs
# operationId: listJobs
export def "jobs listJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<type: string, job_id: string, status: string, status_updates: list, args: record, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jobs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create image
#
# POST /images/generations
# --image_loras item shape: {path: string, scale: float}
export def "images-generations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  prompt: string # A description of the desired images. Maximum length varies by model. (e.g. cat floating in space, cinematic)
  model: string # The model to use for image generation.<br> <br> [See all of Together AI's image models](https://docs.together.ai/docs/serverless-models#image-models)  (e.g. black-forest-labs/FLUX.1-schnell)
  --steps: int # Number of generation steps. (default: 20)
  --image-url: string # URL of an image to use for image models that support it.
  --seed: int # Seed used for generation. Can be used to reproduce image generations.
  --n: int # Number of image results to generate. (default: 1)
  --height: int # Height of the image to generate in number of pixels. (default: 1024)
  --width: int # Width of the image to generate in number of pixels. (default: 1024)
  --negative-prompt: string # The prompt or prompts not to guide the image generation.
  --response-format: string@response-format-completer # Format of the image response. Can be either a base64 string or a URL.
  --guidance-scale: float # Adjusts the alignment of the generated image with the input prompt. Higher values (e.g., 8-10) make the output more faithful to the prompt, while lower values (e.g., 1-5) encourage more creative freedom. (default: 3.5)
  --output-format: string@output-format-completer-1 # The format of the image response. Can be either be `jpeg` or `png`. Defaults to `jpeg`. (default: jpeg)
  --image-loras: list # An array of objects that define LoRAs (Low-Rank Adaptations) to influence the generated image. — item shape: {path: string, scale: float}
  --reference-images: list # An array of image URLs that guide the overall appearance and style of the generated image. These reference images influence the visual characteristics consistently across the generation.
  --disable-safety-checker: oneof<nothing, bool> # If true, disables the safety checker for image generation.
]: any -> record<id: string, model: string, object: any, data: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images/generations")
  let body = {prompt: $prompt, model: $model, steps: $steps, image_url: $image_url, seed: $seed, n: $n, height: $height, width: $width, negative_prompt: $negative_prompt, response_format: $response_format, guidance_scale: $guidance_scale, output_format: $output_format, image_loras: $image_loras, reference_images: $reference_images, disable_safety_checker: $disable_safety_checker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all files
#
# GET /files
export def "files list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string, object: any, created_at: int, filename: string, bytes: int, purpose: string, Processed: bool, FileType: string, processing_status: string, validation_report: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve file metadata
#
# GET /files/{id}
export def "files get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: any, created_at: int, filename: string, bytes: int, purpose: string, Processed: bool, FileType: string, processing_status: string, validation_report: record<valid: bool, dataset_format: string, dataset_has_sample_weights: bool, dataset_has_message_weights: bool, dataset_is_multimodal: bool, dataset_has_tools: bool, dataset_has_parallel_tool_calls: bool, dataset_has_reasoning: bool, nlines: int, file_id: string, error_type: string, error: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a file
#
# DELETE /files/{id}
export def "files delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get file contents
#
# GET /files/{id}/content
export def "files-content get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($id)/content")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a file
#
# POST /files/upload
export def "files-upload post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  purpose: string@purpose-completer # The purpose of the file (e.g. fine-tune)
  file_name: string # The name of the file being uploaded (e.g. dataset.csv)
  --file-type: string@file-type-completer # The type of the file (default: jsonl, e.g. jsonl)
  file: string # The content of the file being uploaded (format: binary)
]: any -> record<id: string, object: any, created_at: int, filename: string, bytes: int, purpose: string, Processed: bool, FileType: string, processing_status: string, validation_report: record<valid: bool, dataset_format: string, dataset_has_sample_weights: bool, dataset_has_message_weights: bool, dataset_is_multimodal: bool, dataset_has_tools: bool, dataset_has_parallel_tool_calls: bool, dataset_has_reasoning: bool, nlines: int, file_id: string, error_type: string, error: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files/upload")
  let body = {purpose: $purpose, file_name: $file_name, file_type: $file_type, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create job
#
# POST /fine-tunes
# --lr_scheduler shape: {lr_scheduler_type: "linear"|"cosine", lr_scheduler_args?: any}
# --training_method shape: {method?: "sft", train_on_inputs?: bool, dpo_beta?: float, rpo_alpha?: float, dpo_normalize_logratios_by_length?: bool, dpo_reference_free?: bool, simpo_gamma?: float}
# --training_type shape: {type?: "Full", lora_r?: int, lora_alpha?: int, lora_dropout?: float, lora_trainable_modules?: string}
# --multimodal_params shape: {train_vision?: bool}
@deprecated --flag train-on-inputs
export def "fine-tunes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  training_file: string # File-ID of a training file uploaded to the Together API
  --validation-file: string # File-ID of a validation file uploaded to the Together API
  --packing: oneof<nothing, bool> # Whether to use sequence packing for training. This flag has no effect if the training data is in Parquet format. (default: true)
  --max-seq-length: int # Maximum sequence length to use for training. If not specified, the maximum allowed for the model and training method will be used.
  model: string # Name of the base model to run fine-tune job on
  --n-epochs: int # Number of complete passes through the training dataset (higher values may improve results but increase cost and risk of overfitting) (default: 1)
  --n-checkpoints: int # Number of intermediate model versions saved during training for evaluation (default: 1)
  --n-evals: int # Number of evaluations to be run on a given validation set during training (default: 0)
  --batch-size: any # Number of training examples processed together (larger batches use more memory but may train faster). Defaults to "max". We use training optimizations like packing, so the effective batch size may be different than the value you set. (default: max)
  --gradient-accumulation-steps: int # Number of steps to accumulate gradients before performing a weight update. If omitted or set to 0, the model default is used.
  --learning-rate: float # Controls how quickly the model adapts to new information (too high may cause instability, too low may slow convergence) (format: float, default: 0.00001)
  --lr-scheduler: record # shape: {lr_scheduler_type: "linear"|"cosine", lr_scheduler_args?: any}
  --warmup-ratio: float # The percent of steps at the start of training to linearly increase the learning rate. (format: float, default: 0)
  --max-grad-norm: float # Max gradient norm to be used for gradient clipping. Set to 0 to disable. (format: float, default: 1)
  --weight-decay: float # Weight decay. Regularization parameter for the optimizer. (format: float, default: 0)
  --random-seed: int # Random seed for reproducible training. When set, the same seed produces the same run (e.g. data shuffle, init). If omitted or null, the server applies its default seed (e.g. 42).  (nullable)
  --suffix: string # Suffix to add to your fine-tuned model name. Must be at most 64 characters long.
  --wandb-api-key: string # Integration key for tracking experiments and model metrics on W&B platform
  --wandb-base-url: string # The base URL of a dedicated Weights & Biases instance.
  --wandb-project-name: string # The Weights & Biases project for your run. If not specified, uses `together` as the project name.
  --wandb-name: string # The Weights & Biases name for your run.
  --wandb-entity: string # The Weights & Biases entity for your run.
  --train-on-inputs: oneof<nothing, bool> # Whether to mask user messages in conversational data or prompts in instruction data. (DEPRECATED, default: auto)
  --training-method: record # The training method to use. 'sft' for Supervised Fine-Tuning or 'dpo' for Direct Preference Optimization. — shape: {method?: "sft", train_on_inputs?: bool, dpo_beta?: float, rpo_alpha?: float, dpo_normalize_logratios_by_length?: bool, dpo_reference_free?: bool, simpo_gamma?: float}
  --training-type: record # The training type to use. Defaults to LoRA if not provided. (nullable) — shape: {type?: "Full", lora_r?: int, lora_alpha?: int, lora_dropout?: float, lora_trainable_modules?: string}
  --multimodal-params: record # shape: {train_vision?: bool}
  --from-checkpoint: string # The checkpoint identifier to continue training from a previous fine-tuning job. Format is `{$JOB_ID}` or `{$OUTPUT_MODEL_NAME}` or `{$JOB_ID}:{$STEP}` or `{$OUTPUT_MODEL_NAME}:{$STEP}`. The step value is optional; without it, uses the final checkpoint.
  --from-hf-model: string # The Hugging Face Hub repo to start training from. Should be as close as possible to the base model (specified by the `model` argument) in terms of architecture and size.
  --hf-model-revision: string # The revision of the Hugging Face Hub model to continue training from. E.g., hf_model_revision=main (default, used if the argument is not provided) or hf_model_revision='607a30d783dfa663caf39e06633721c8d4cfcd7e' (specific commit).
  --hf-api-token: string # The API token for the Hugging Face Hub.
  --hf-output-repo-name: string # The name of the Hugging Face repository to upload the fine-tuned model to.
]: any -> record<id: string, status: string, created_at: string, updated_at: string, started_at: string, user_id: string, owner_address: string, total_price: int, token_count: int, events: table<object: any, created_at: string, level: any, message: string, type: string, param_count: int, token_count: int, total_steps: int, wandb_url: string, step: int, checkpoint_path: string, model_path: string, training_offset: int, hash: string>, training_file: string, validation_file: string, packing: bool, max_seq_length: int, model: string, model_output_name: string, suffix: string, n_epochs: int, n_evals: int, n_checkpoints: int, batch_size: int, training_type: any, training_method: any, learning_rate: float, lr_scheduler: record<lr_scheduler_type: string, lr_scheduler_args: any>, warmup_ratio: float, max_grad_norm: float, weight_decay: float, random_seed: int, wandb_project_name: string, wandb_name: string, from_checkpoint: string, from_hf_model: string, hf_model_revision: string, progress: record<estimate_available: bool, seconds_remaining: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fine-tunes")
  let body = {training_file: $training_file, validation_file: $validation_file, packing: $packing, max_seq_length: $max_seq_length, model: $model, n_epochs: $n_epochs, n_checkpoints: $n_checkpoints, n_evals: $n_evals, batch_size: $batch_size, gradient_accumulation_steps: $gradient_accumulation_steps, learning_rate: $learning_rate, lr_scheduler: $lr_scheduler, warmup_ratio: $warmup_ratio, max_grad_norm: $max_grad_norm, weight_decay: $weight_decay, random_seed: $random_seed, suffix: $suffix, wandb_api_key: $wandb_api_key, wandb_base_url: $wandb_base_url, wandb_project_name: $wandb_project_name, wandb_name: $wandb_name, wandb_entity: $wandb_entity, train_on_inputs: $train_on_inputs, training_method: $training_method, training_type: $training_type, multimodal_params: $multimodal_params, from_checkpoint: $from_checkpoint, from_hf_model: $from_hf_model, hf_model_revision: $hf_model_revision, hf_api_token: $hf_api_token, hf_output_repo_name: $hf_output_repo_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all jobs
#
# GET /fine-tunes
export def "fine-tunes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string, status: string, created_at: string, updated_at: string, started_at: string, user_id: string, owner_address: string, total_price: int, token_count: int, events: list, training_file: string, validation_file: string, packing: bool, max_seq_length: int, model: string, model_output_name: string, suffix: string, n_epochs: int, n_evals: int, n_checkpoints: int, batch_size: int, training_type: any, training_method: any, learning_rate: float, lr_scheduler: record, warmup_ratio: float, max_grad_norm: float, weight_decay: float, random_seed: int, wandb_project_name: string, wandb_name: string, from_checkpoint: string, from_hf_model: string, hf_model_revision: string, progress: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fine-tunes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Estimate price
#
# POST /fine-tunes/estimate-price
# --training_method shape: {method?: "sft", train_on_inputs?: bool, dpo_beta?: float, rpo_alpha?: float, dpo_normalize_logratios_by_length?: bool, dpo_reference_free?: bool, simpo_gamma?: float}
# --training_type shape: {type?: "Full", lora_r?: int, lora_alpha?: int, lora_dropout?: float, lora_trainable_modules?: string}
export def "fine-tunes-estimate-price post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  training_file: string # File-ID of a training file uploaded to the Together API
  --validation-file: string # File-ID of a validation file uploaded to the Together API
  --model: string # Name of the base model to run fine-tune job on
  --n-epochs: int # Number of complete passes through the training dataset (higher values may improve results but increase cost and risk of overfitting) (default: 1)
  --n-evals: int # Number of evaluations to be run on a given validation set during training (default: 0)
  --training-method: record # The training method to use. 'sft' for Supervised Fine-Tuning or 'dpo' for Direct Preference Optimization. — shape: {method?: "sft", train_on_inputs?: bool, dpo_beta?: float, rpo_alpha?: float, dpo_normalize_logratios_by_length?: bool, dpo_reference_free?: bool, simpo_gamma?: float}
  --training-type: record # The training type to use. Defaults to LoRA if not provided. (nullable) — shape: {type?: "Full", lora_r?: int, lora_alpha?: int, lora_dropout?: float, lora_trainable_modules?: string}
  --from-checkpoint: string # The checkpoint identifier to continue training from a previous fine-tuning job. Format is `{$JOB_ID}` or `{$OUTPUT_MODEL_NAME}` or `{$JOB_ID}:{$STEP}` or `{$OUTPUT_MODEL_NAME}:{$STEP}`. The step value is optional; without it, uses the final checkpoint.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fine-tunes/estimate-price")
  let body = {training_file: $training_file, validation_file: $validation_file, model: $model, n_epochs: $n_epochs, n_evals: $n_evals, training_method: $training_method, training_type: $training_type, from_checkpoint: $from_checkpoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List job
#
# GET /fine-tunes/{id}
export def "fine-tunes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, training_file: string, validation_file: string, model: string, model_output_name: string, model_output_path: string, trainingfile_numlines: int, trainingfile_size: int, created_at: string, updated_at: string, started_at: string, n_epochs: int, n_checkpoints: int, n_evals: int, batch_size: any, learning_rate: float, lr_scheduler: record<lr_scheduler_type: string, lr_scheduler_args: any>, warmup_ratio: float, max_grad_norm: float, weight_decay: float, eval_steps: int, train_on_inputs: any, training_method: record, training_type: record, multimodal_params: record<train_vision: bool>, status: string, job_id: string, events: table<object: any, created_at: string, level: any, message: string, type: string, param_count: int, token_count: int, total_steps: int, wandb_url: string, step: int, checkpoint_path: string, model_path: string, training_offset: int, hash: string>, token_count: int, param_count: int, total_price: int, epochs_completed: int, queue_depth: int, wandb_project_name: string, wandb_url: string, from_checkpoint: string, from_hf_model: string, hf_model_revision: string, progress: record<estimate_available: bool, seconds_remaining: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fine-tunes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a fine-tune job
#
# DELETE /fine-tunes/{id}
@deprecated --flag force
export def "fine-tunes delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # DEPRECATED, default: false
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/fine-tunes/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List job events
#
# GET /fine-tunes/{id}/events
export def "fine-tunes-events get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<object: any, created_at: string, level: any, message: string, type: string, param_count: int, token_count: int, total_steps: int, wandb_url: string, step: int, checkpoint_path: string, model_path: string, training_offset: int, hash: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fine-tunes/($id)/events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List checkpoints
#
# GET /fine-tunes/{id}/checkpoints
export def "fine-tunes-checkpoints get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<step: int, created_at: string, path: string, checkpoint_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fine-tunes/($id)/checkpoints")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download model
#
# GET /finetune/download
export def "finetune-download get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ft-id: string
  --checkpoint-step: int
  --checkpoint: string@checkpoint-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ft_id" $ft_id "scalar") (serialize-qp "checkpoint_step" $checkpoint_step "scalar") (serialize-qp "checkpoint" $checkpoint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/finetune/download" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel job
#
# POST /fine-tunes/{id}/cancel
export def "fine-tunes-cancel post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, created_at: string, updated_at: string, started_at: string, user_id: string, owner_address: string, total_price: int, token_count: int, events: table<object: any, created_at: string, level: any, message: string, type: string, param_count: int, token_count: int, total_steps: int, wandb_url: string, step: int, checkpoint_path: string, model_path: string, training_offset: int, hash: string>, training_file: string, validation_file: string, packing: bool, max_seq_length: int, model: string, model_output_name: string, suffix: string, n_epochs: int, n_evals: int, n_checkpoints: int, batch_size: int, training_type: any, training_method: any, learning_rate: float, lr_scheduler: record<lr_scheduler_type: string, lr_scheduler_args: any>, warmup_ratio: float, max_grad_norm: float, weight_decay: float, random_seed: int, wandb_project_name: string, wandb_name: string, from_checkpoint: string, from_hf_model: string, hf_model_revision: string, progress: record<estimate_available: bool, seconds_remaining: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fine-tunes/($id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metrics
#
# GET /fine-tunes/{id}/metrics
export def "fine-tunes-metrics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --global-step-from: int # Return only metrics with global_step >= this value. (format: int64, e.g. 0)
  --global-step-to: int # Return only metrics with global_step <= this value. (format: int64, e.g. 500)
  --logged-at-from: string # Return only metrics logged at or after this ISO-8601 timestamp. (format: date-time, e.g. 2024-01-01T00:00:00Z)
  --logged-at-to: string # Return only metrics logged at or before this ISO-8601 timestamp. (format: date-time, e.g. 2024-01-01T12:00:00Z)
  --resolution: int # Number of (uniformly sampled) train metrics to return. (format: int64, e.g. 100)
]: nothing -> record<metrics: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "global_step_from" $global_step_from "scalar") (serialize-qp "global_step_to" $global_step_to "scalar") (serialize-qp "logged_at_from" $logged_at_from "scalar") (serialize-qp "logged_at_to" $logged_at_to "scalar") (serialize-qp "resolution" $resolution "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/fine-tunes/($id)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List supported models
#
# GET /fine-tunes/models/supported
export def "fine-tunes-models-supported get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<models: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fine-tunes/models/supported")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get model limits
#
# GET /fine-tunes/models/limits
export def "fine-tunes-models-limits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model-name: string
]: nothing -> record<model_name: string, full_training: record<max_batch_size: int, max_batch_size_dpo: int, min_batch_size: int>, lora_training: record<max_batch_size: int, max_batch_size_dpo: int, min_batch_size: int, max_rank: int, target_modules: list<string>>, max_num_epochs: int, max_num_evals: int, max_learning_rate: float, min_learning_rate: float, supports_vision: bool, supports_tools: bool, supports_reasoning: bool, merge_output_lora: bool, default_gradient_accumulation_steps: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model_name" $model_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fine-tunes/models/limits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a rerank request
#
# POST /rerank
# operationId: rerank
export def "rerank rerank" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  model: string # The model to be used for the rerank request.<br> <br> [See all of Together AI's rerank models](https://docs.together.ai/docs/serverless-models#rerank-models)  (e.g. Salesforce/Llama-Rank-V1)
  --body-query: string # The search query to be used for ranking. (e.g. What animals can I find near Peru?)
  documents: any # List of documents, which can be either strings or objects. (e.g. [{title: Llama, text: The llama is a domesticated South American camelid, widely used as a meat and pack animal by Andean cultures since the pre-Columbian era.}, {title: Panda, text: The giant panda (Ailuropoda melanoleuca), also known as the panda bear or simply panda, is a bear species endemic to China.}, {title: Guanaco, text: The guanaco is a camelid native to South America, closely related to the llama. Guanacos are one of two wild South American camelids; the other species is the vicuña, which lives at higher elevations.}, {title: Wild Bactrian camel, text: The wild Bactrian camel (Camelus ferus) is an endangered species of camel endemic to Northwest China and southwestern Mongolia.}])
  --top-n: int # The number of top results to return. (e.g. 2)
  --return-documents: oneof<nothing, bool> # Whether to return supplied documents with the response. (e.g. true)
  --rank-fields: list # List of keys in the JSON Object document to rank by. Defaults to use all supplied keys for ranking. (e.g. [title, text])
]: any -> record<object: any, id: string, model: string, results: table<index: int, relevance_score: float, document: record>, usage: record<prompt_tokens: int, completion_tokens: int, total_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rerank")
  let body = {model: $model, query: $body_query, documents: $documents, top_n: $top_n, return_documents: $return_documents, rank_fields: $rank_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create audio generation request
#
# POST /audio/speech
# operationId: audio-speech
# --extra_params shape: {pronunciation_dict?: list}
export def "audio-speech audio-speech" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  model: any # The name of the model to query.<br> <br> [See all of Together AI's chat models](https://docs.together.ai/docs/serverless-models#audio-models) The current supported tts models are: - cartesia/sonic - hexgrad/Kokoro-82M - canopylabs/orpheus-3b-0.1-ft  (e.g. canopylabs/orpheus-3b-0.1-ft)
  input: string # Input text to generate the audio for
  voice: string # The voice to use for generating the audio. The voices supported are different for each model. For eg - for canopylabs/orpheus-3b-0.1-ft, one of the voices supported is tara, for hexgrad/Kokoro-82M, one of the voices supported is af_alloy and for cartesia/sonic, one of the voices supported is "friendly sidekick". <br> <br> You can view the voices supported for each model using the /v1/voices endpoint sending the model name as the query parameter. [View all supported voices here](https://docs.together.ai/docs/text-to-speech#supported-voices). <br> <br> `hexgrad/Kokoro-82M` additionally supports voice mixing, where two or more voices are combined into a single blended voice by joining their names with `+` (e.g. `af_bella+af_heart`). Optional per-voice weights can be provided in parentheses (e.g. `af_bella(2)+af_heart(1)`). Other models require a single voice name.
  --response-format: string@response-format-completer-1 # The format of audio output. Supported formats are mp3, wav, raw if streaming is false. If streaming is true, the only supported format is raw. (default: wav)
  --language: string # Language or locale of input text. Accepts ISO 639-1 language codes (e.g., `en`, `fr`, `es`, `zh`) as well as locale codes for region-specific variants. Locale codes must be lowercase (e.g., `zh-hk` for Cantonese).  (default: en, e.g. en)
  --response-encoding: string@response-encoding-completer # Audio encoding of response. Only applicable when response_format is raw or pcm. Cartesia models respect this parameter and support all values. Orpheus, Kokoro, and Minimax models always return pcm_s16le regardless of this setting. (default: pcm_f32le)
  --sample-rate: int # Sampling rate in Hz for the output audio. Cartesia and Minimax models respect this parameter. Orpheus and Kokoro models always output at 24000 Hz regardless of this setting. (default: 44100)
  --bit-rate: int@bit-rate-completer # Bitrate of the MP3 audio output in bits per second. Only applicable when response_format is mp3. Higher values produce better audio quality at larger file sizes. Default is 128000. Currently supported on Cartesia models. (default: 128000)
  --stream: oneof<nothing, bool> # If true, output is streamed for several characters at a time instead of waiting for the full response. The stream terminates with `data: [DONE]`. If false, return the encoded audio as octet stream (default: false)
  --extra-params: record # Additional model-specific parameters that fine-tune speech generation behavior. — shape: {pronunciation_dict?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audio/speech")
  let body = {model: $model, input: $input, voice: $voice, response_format: $response_format, language: $language, response_encoding: $response_encoding, sample_rate: $sample_rate, bit_rate: $bit_rate, stream: $stream, extra_params: $extra_params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/octet-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Real-time text-to-speech via WebSocket
#
# GET /audio/speech/websocket
# operationId: realtime-tts
export def "audio-speech-websocket realtime-tts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model: string@model-completer # default: hexgrad/Kokoro-82M
  --voice: string
  --max-partial-length: int # default: 250
  --language: string # default: en, e.g. en
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar") (serialize-qp "voice" $voice "scalar") (serialize-qp "max_partial_length" $max_partial_length "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/audio/speech/websocket" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create audio transcription request
#
# POST /audio/transcriptions
# operationId: audio-transcriptions
export def "audio-transcriptions audio-transcriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: any # Audio file upload or public HTTP/HTTPS URL. Supported formats: .wav, .mp3, .m4a, .webm, .flac, .ogg, .opus, .aac. Maximum duration 4 hours; longer audio is rejected with `audio_too_long`. Binary uploads are additionally capped at 500 MB (HTTP 413); URL-fetched audio is capped at 1 GB.
  --model: string@model-completer-1 # Model to use for transcription (default: openai/whisper-large-v3)
  --language: string # Optional ISO 639-1 language code. If `auto` is provided, language is auto-detected. (default: en, e.g. en)
  --prompt: string # Optional text to bias decoding. Supported only on Whisper-family models (e.g. `openai/whisper-large-v3`). Other STT models (e.g. `nvidia/parakeet-tdt-0.6b-v3`) accept the field for API compatibility but ignore it.
  --response-format: string@response-format-completer-2 # The format of the response (default: json)
  --temperature: float # Sampling temperature between 0.0 and 1.0 (format: float, default: 0)
  --timestamp-granularities: any # Controls level of timestamp detail in verbose_json. Only used when response_format is verbose_json. Can be a single granularity or an array to get multiple levels. (default: segment, e.g. [word, segment])
  --diarize: oneof<nothing, bool> # Whether to enable speaker diarization. When enabled, you will get the speaker id for each word in the transcription. In the response, in the words array, you will get the speaker id for each word. In addition, we also return the speaker_segments array which contains the speaker id for each speaker segment along with the start and end time of the segment along with all the words in the segment. <br> <br> For eg - ... "speaker_segments": [   "speaker_id": "SPEAKER_00",   "start": 0,   "end": 30.02,   "words": [     {       "id": 0,       "word": "Tijana",       "start": 0,       "end": 11.475,       "speaker_id": "SPEAKER_00"     },     ...  (default: false)
  --min-speakers: int # Minimum number of speakers expected in the audio. Used to improve diarization accuracy when the approximate number of speakers is known.
  --max-speakers: int # Maximum number of speakers expected in the audio. Used to improve diarization accuracy when the approximate number of speakers is known.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audio/transcriptions")
  let body = {file: $file, model: $model, language: $language, prompt: $prompt, response_format: $response_format, temperature: $temperature, timestamp_granularities: $timestamp_granularities, diarize: $diarize, min_speakers: $min_speakers, max_speakers: $max_speakers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create audio translation request
#
# POST /audio/translations
# operationId: audio-translations
export def "audio-translations audio-translations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: any # Audio file upload or public HTTP/HTTPS URL. Supported formats: .wav, .mp3, .m4a, .webm, .flac, .ogg, .opus, .aac. Maximum duration 4 hours; longer audio is rejected with `audio_too_long`. Binary uploads are additionally capped at 500 MB (HTTP 413); URL-fetched audio is capped at 1 GB.
  --model: string@model-completer-1 # Model to use for translation (default: openai/whisper-large-v3)
  --language: string # Target output language. Optional ISO 639-1 language code. If omitted, language is set to English. (default: en, e.g. en)
  --prompt: string # Optional text to bias decoding. Supported only on Whisper-family models (e.g. `openai/whisper-large-v3`). Other STT models (e.g. `nvidia/parakeet-tdt-0.6b-v3`) accept the field for API compatibility but ignore it.
  --response-format: string@response-format-completer-2 # The format of the response (default: json)
  --temperature: float # Sampling temperature between 0.0 and 1.0 (format: float, default: 0)
  --timestamp-granularities: any # Controls level of timestamp detail in verbose_json. Only used when response_format is verbose_json. Can be a single granularity or an array to get multiple levels. (default: segment, e.g. [word, segment])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audio/translations")
  let body = {file: $file, model: $model, language: $language, prompt: $prompt, response_format: $response_format, temperature: $temperature, timestamp_granularities: $timestamp_granularities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List all GPU clusters
#
# GET /compute/clusters
# operationId: GPUClusterService_List
export def "compute-clusters List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-id: string
]: nothing -> record<clusters: table<cluster_id: string, cluster_type: any, region: string, gpu_type: any, cluster_name: string, duration_hours: int, volumes: list, status: any, control_plane_nodes: list, gpu_worker_nodes: list, kube_config: string, num_gpus: int, slurm_shm_size_gib: int, capacity_pool_id: string, reservation_start_time: string, reservation_end_time: string, install_traefik: bool, cuda_version: string, nvidia_driver_version: string, created_at: string, oidc_config: record, project_id: string, cluster_config: record, num_cpu_workers: int, phase_transitions: list, desired_preemptible_gpus: int, allocated_preemptible_gpus: int, billing_type: string, add_ons: list, machine_cluster_id: string, first_ready_at: string, is_in_substrate: bool, control_plane_ready: bool, ums_project_id: string, ums_org_id: string, os_image: string, nvidia_driver_version_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/compute/clusters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a GPU cluster
#
# POST /compute/clusters
# operationId: GPUClusterService_Create
# --shared_volume shape: {volume_name: string, size_tib: int, region: string, is_lifecycle_independent?: bool}
# --oidc_config shape: {issuer_url: string, client_id: string, username_claim: string, username_prefix: string, group_claim: string, group_prefix: string, ca_cert?: string}
# --acceptance_tests_params shape: {enabled?: bool, dcgm_diag_level?: "DCGM_DIAG_LEVEL_SHORT"|"DCGM_DIAG_LEVEL_MEDIUM"|"DCGM_DIAG_LEVEL_LONG"|"DCGM_DIAG_LEVEL_EXTENDED", gpu_burn_duration?: int, nccl_single_node_skipped?: bool, gpu_burn_skipped?: bool, dcgm_diag_skipped?: bool, nccl_multi_node_skipped?: bool}
# --cluster_config shape: {load_balancer: "NONE"|"TRAEFIK"|"NGINX"|"ISTIO", kubernetes_dashboard_enabled?: bool, jumphost_enabled?: bool, slurm_startup_scripts?: record, ingress?: record, observability?: record, gpu_operator_version?: string}
# --add_ons item shape: {name: string, add_on_type: string, config?: record}
@deprecated --flag auto-scaled
export def "compute-clusters Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cluster-type: string@cluster-type-completer # Type of cluster to create.
  region: string # Region to create the GPU cluster in. Usable regions can be found from `client.clusters.list_regions()`
  gpu_type: string@gpu-type-completer-1 # Type of GPU to use in the cluster
  num_gpus: int # Number of GPUs to allocate in the cluster. This must be multiple of 8. For example, 8, 16 or 24 (format: int32)
  cluster_name: string # Name of the GPU cluster.
  --duration-days: int # Duration in days to keep the cluster running.
  --shared-volume: record # shape: {volume_name: string, size_tib: int, region: string, is_lifecycle_independent?: bool}
  --volume-id: string # ID of an existing volume to use with the cluster creation.
  billing_type: string@billing-type-completer # RESERVED billing types allow you to specify the duration of the cluster reservation via the duration_days field. ON_DEMAND billing types will give you ownership of the cluster until you delete it. SCHEDULED_CAPACITY billing types allow you to reserve capacity for a scheduled time window. You must specify the reservation_start_time and reservation_end_time with this request.
  --auto-scaled: oneof<nothing, bool> # Whether GPU cluster should be auto-scaled based on the workload. By default, it is not auto-scaled. (DEPRECATED, default: false)
  --auto-scale-max-gpus: int # Maximum number of GPUs to which the cluster can be auto-scaled up. This field is required if auto_scaled is true.
  --slurm-shm-size-gib: int # Shared memory size in GiB for Slurm cluster. This field is required if cluster_type is SLURM.
  --capacity-pool-id: string # ID of the capacity pool to use for the cluster. This field is optional and only applicable if the cluster is created from a capacity pool.
  --reservation-start-time: string # Reservation start time of the cluster. This field is required for SCHEDULED billing to specify the reservation start time for the cluster. If not provided, the cluster provisions immediately. (format: date-time)
  --reservation-end-time: string # Reservation end time of the cluster. This field is required for SCHEDULED billing to specify the reservation end time for the cluster. (format: date-time)
  --install-traefik: oneof<nothing, bool> # Whether to install Traefik ingress controller in the cluster. This field is only applicable for Kubernetes clusters and is false by default. (default: false)
  cuda_version: string # CUDA version for this cluster. For example, 12.5
  nvidia_driver_version: string # Nvidia driver version for this cluster. For example, 550. Only some combination of cuda_version and nvidia_driver_version are supported.
  --slurm-image: string # Custom Slurm image for Slurm clusters.
  --oidc-config: record # shape: {issuer_url: string, client_id: string, username_claim: string, username_prefix: string, group_claim: string, group_prefix: string, ca_cert?: string}
  --project-id: string # Project ID for the cluster. If not set, the project from the request context is used.
  --acceptance-tests-params: record # AcceptanceTestsParams groups all GPU acceptance test options when enabled is true. — shape: {enabled?: bool, dcgm_diag_level?: "DCGM_DIAG_LEVEL_SHORT"|"DCGM_DIAG_LEVEL_MEDIUM"|"DCGM_DIAG_LEVEL_LONG"|"DCGM_DIAG_LEVEL_EXTENDED", gpu_burn_duration?: int, nccl_single_node_skipped?: bool, gpu_burn_skipped?: bool, dcgm_diag_skipped?: bool, nccl_multi_node_skipped?: bool}
  --cluster-config: record # shape: {load_balancer: "NONE"|"TRAEFIK"|"NGINX"|"ISTIO", kubernetes_dashboard_enabled?: bool, jumphost_enabled?: bool, slurm_startup_scripts?: record, ingress?: record, observability?: record, gpu_operator_version?: string}
  --num-capacity-pool-gpus: int # Number of GPUs to allocate from the capacity pool. Must be a multiple of 8 and not exceed num_gpus. (format: int32)
  --auto-scale: oneof<nothing, bool> # Whether to enable auto-scaling for the cluster. If true, the cluster will automatically scale the number of GPU worker nodes between num_gpus and auto_scale_max_gpus based on the workload.
  --num-preemptible-gpus: int # Number of preemptible GPUs to request alongside on-demand capacity. Must be a multiple of 8. Preemptible nodes are cheaper but may be reclaimed when on-demand capacity is needed elsewhere; the system fulfills this asynchronously and surfaces the actual count in allocated_preemptible_gpus. (format: int32)
  --num-reserved-gpus: int # Number of prepaid (PLG) reserved GPUs for this cluster. When omitted for RESERVED billing on create, the server defaults this to num_gpus.
  --add-ons: list # Add-ons to enable on the cluster at creation time. — item shape: {name: string, add_on_type: string, config?: record}
]: any -> record<cluster_id: string, cluster_type: any, region: string, gpu_type: any, cluster_name: string, duration_hours: int, volumes: table<volume_id: string, volume_name: string, size_tib: int, status: string>, status: any, control_plane_nodes: table<node_id: string, status: string, host_name: string, num_cpu_cores: int, memory_gib: float, network: string, phase_transitions: list, public_ipv4: string>, gpu_worker_nodes: table<node_id: string, status: string, host_name: string, num_cpu_cores: int, num_gpus: int, memory_gib: float, networks: list, instance_id: string, latest_remediation: record, slurm_worker_hostname: string, phase_transitions: list, marked_for_deletion: bool, public_ipv4: string, ib_hca_type: string, ib_hca_count: int, nvswitch_count: int, nvswitch_type: string, ephemeral_storage: string, auto_remediation_enabled: bool>, kube_config: string, num_gpus: int, slurm_shm_size_gib: int, capacity_pool_id: string, reservation_start_time: string, reservation_end_time: string, install_traefik: bool, cuda_version: string, nvidia_driver_version: string, created_at: string, oidc_config: record<issuer_url: string, client_id: string, username_claim: string, username_prefix: string, group_claim: string, group_prefix: string, ca_cert: string>, project_id: string, cluster_config: record<load_balancer: string, kubernetes_dashboard_enabled: bool, jumphost_enabled: bool, slurm_startup_scripts: record<worker_prolog: string, worker_epilog: string, controller_prolog: string, controller_epilog: string, login_init_script: string, nodeset_init_script: string, extra_slurm_conf: string>, ingress: record<enabled: bool>, observability: record<enabled: bool>, gpu_operator_version: string>, num_cpu_workers: int, phase_transitions: table<phase: string, transition_time: string>, desired_preemptible_gpus: int, allocated_preemptible_gpus: int, billing_type: string, add_ons: table<name: string, add_on_type: string, config: record, state: record>, machine_cluster_id: string, first_ready_at: string, is_in_substrate: bool, control_plane_ready: bool, ums_project_id: string, ums_org_id: string, os_image: string, nvidia_driver_version_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/compute/clusters")
  let body = {cluster_type: $cluster_type, region: $region, gpu_type: $gpu_type, num_gpus: $num_gpus, cluster_name: $cluster_name, duration_days: $duration_days, shared_volume: $shared_volume, volume_id: $volume_id, billing_type: $billing_type, auto_scaled: $auto_scaled, auto_scale_max_gpus: $auto_scale_max_gpus, slurm_shm_size_gib: $slurm_shm_size_gib, capacity_pool_id: $capacity_pool_id, reservation_start_time: $reservation_start_time, reservation_end_time: $reservation_end_time, install_traefik: $install_traefik, cuda_version: $cuda_version, nvidia_driver_version: $nvidia_driver_version, slurm_image: $slurm_image, oidc_config: $oidc_config, project_id: $project_id, acceptance_tests_params: $acceptance_tests_params, cluster_config: $cluster_config, num_capacity_pool_gpus: $num_capacity_pool_gpus, auto_scale: $auto_scale, num_preemptible_gpus: $num_preemptible_gpus, num_reserved_gpus: $num_reserved_gpus, add_ons: $add_ons} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get GPU cluster by cluster ID
#
# GET /compute/clusters/{cluster_id}
# operationId: GPUClusterService_Get
export def "compute-clusters Get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cluster_id: string, cluster_type: any, region: string, gpu_type: any, cluster_name: string, duration_hours: int, volumes: table<volume_id: string, volume_name: string, size_tib: int, status: string>, status: any, control_plane_nodes: table<node_id: string, status: string, host_name: string, num_cpu_cores: int, memory_gib: float, network: string, phase_transitions: list, public_ipv4: string>, gpu_worker_nodes: table<node_id: string, status: string, host_name: string, num_cpu_cores: int, num_gpus: int, memory_gib: float, networks: list, instance_id: string, latest_remediation: record, slurm_worker_hostname: string, phase_transitions: list, marked_for_deletion: bool, public_ipv4: string, ib_hca_type: string, ib_hca_count: int, nvswitch_count: int, nvswitch_type: string, ephemeral_storage: string, auto_remediation_enabled: bool>, kube_config: string, num_gpus: int, slurm_shm_size_gib: int, capacity_pool_id: string, reservation_start_time: string, reservation_end_time: string, install_traefik: bool, cuda_version: string, nvidia_driver_version: string, created_at: string, oidc_config: record<issuer_url: string, client_id: string, username_claim: string, username_prefix: string, group_claim: string, group_prefix: string, ca_cert: string>, project_id: string, cluster_config: record<load_balancer: string, kubernetes_dashboard_enabled: bool, jumphost_enabled: bool, slurm_startup_scripts: record<worker_prolog: string, worker_epilog: string, controller_prolog: string, controller_epilog: string, login_init_script: string, nodeset_init_script: string, extra_slurm_conf: string>, ingress: record<enabled: bool>, observability: record<enabled: bool>, gpu_operator_version: string>, num_cpu_workers: int, phase_transitions: table<phase: string, transition_time: string>, desired_preemptible_gpus: int, allocated_preemptible_gpus: int, billing_type: string, add_ons: table<name: string, add_on_type: string, config: record, state: record>, machine_cluster_id: string, first_ready_at: string, is_in_substrate: bool, control_plane_ready: bool, ums_project_id: string, ums_org_id: string, os_image: string, nvidia_driver_version_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a GPU cluster
#
# PUT /compute/clusters/{cluster_id}
# operationId: GPUClusterService_Update
# --cluster_config shape: {load_balancer: "NONE"|"TRAEFIK"|"NGINX"|"ISTIO", kubernetes_dashboard_enabled?: bool, jumphost_enabled?: bool, slurm_startup_scripts?: record, ingress?: record, observability?: record, gpu_operator_version?: string}
# --add_ons item shape: {name: string, config?: record}
export def "compute-clusters Update" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cluster-type: any@cluster-type-completer # Type of cluster to update.
  --num-gpus: int # Target GPU count for the cluster. When omitted, the server keeps the current GPU count from cluster metadata (use for config-only or decommission-time-only updates).
  --reservation-end-time: string # Timestamp at which the cluster should be decommissioned. Only accepted for prepaid clusters. (format: date-time)
  --cluster-config: record # shape: {load_balancer: "NONE"|"TRAEFIK"|"NGINX"|"ISTIO", kubernetes_dashboard_enabled?: bool, jumphost_enabled?: bool, slurm_startup_scripts?: record, ingress?: record, observability?: record, gpu_operator_version?: string}
  --num-reserved-gpus: int # Number of reserved GPUs to update to. This field is only applicable for clusters with RESERVED billing type.
  --num-preemptible-gpus: int # Updated desired number of preemptible GPUs for the cluster. When omitted, the current value is preserved. Must be a multiple of 8. (format: int32)
  --add-ons: list # Add-ons to update on the cluster. Each entry identifies an existing add-on by name and provides the new external config to merge. — item shape: {name: string, config?: record}
]: any -> record<cluster_id: string, cluster_type: any, region: string, gpu_type: any, cluster_name: string, duration_hours: int, volumes: table<volume_id: string, volume_name: string, size_tib: int, status: string>, status: any, control_plane_nodes: table<node_id: string, status: string, host_name: string, num_cpu_cores: int, memory_gib: float, network: string, phase_transitions: list, public_ipv4: string>, gpu_worker_nodes: table<node_id: string, status: string, host_name: string, num_cpu_cores: int, num_gpus: int, memory_gib: float, networks: list, instance_id: string, latest_remediation: record, slurm_worker_hostname: string, phase_transitions: list, marked_for_deletion: bool, public_ipv4: string, ib_hca_type: string, ib_hca_count: int, nvswitch_count: int, nvswitch_type: string, ephemeral_storage: string, auto_remediation_enabled: bool>, kube_config: string, num_gpus: int, slurm_shm_size_gib: int, capacity_pool_id: string, reservation_start_time: string, reservation_end_time: string, install_traefik: bool, cuda_version: string, nvidia_driver_version: string, created_at: string, oidc_config: record<issuer_url: string, client_id: string, username_claim: string, username_prefix: string, group_claim: string, group_prefix: string, ca_cert: string>, project_id: string, cluster_config: record<load_balancer: string, kubernetes_dashboard_enabled: bool, jumphost_enabled: bool, slurm_startup_scripts: record<worker_prolog: string, worker_epilog: string, controller_prolog: string, controller_epilog: string, login_init_script: string, nodeset_init_script: string, extra_slurm_conf: string>, ingress: record<enabled: bool>, observability: record<enabled: bool>, gpu_operator_version: string>, num_cpu_workers: int, phase_transitions: table<phase: string, transition_time: string>, desired_preemptible_gpus: int, allocated_preemptible_gpus: int, billing_type: string, add_ons: table<name: string, add_on_type: string, config: record, state: record>, machine_cluster_id: string, first_ready_at: string, is_in_substrate: bool, control_plane_ready: bool, ums_project_id: string, ums_org_id: string, os_image: string, nvidia_driver_version_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)")
  let body = {cluster_type: $cluster_type, num_gpus: $num_gpus, reservation_end_time: $reservation_end_time, cluster_config: $cluster_config, num_reserved_gpus: $num_reserved_gpus, num_preemptible_gpus: $num_preemptible_gpus, add_ons: $add_ons} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete GPU cluster by cluster ID
#
# DELETE /compute/clusters/{cluster_id}
# operationId: GPUClusterService_Delete
export def "compute-clusters Delete" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cluster_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List regions and corresponding supported driver versions
#
# GET /compute/regions
# operationId: RegionService_List
export def "compute-regions List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<regions: table<name: string, driver_versions: list, supported_instance_types: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/compute/regions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all shared volumes
#
# GET /compute/clusters/storage/volumes
# operationId: SharedVolumeService_List
export def "compute-clusters-storage-volumes List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-id: string
]: nothing -> record<volumes: table<volume_id: string, volume_name: string, size_tib: int, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/compute/clusters/storage/volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a shared volume
#
# PUT /compute/clusters/storage/volumes
# operationId: SharedVolumeService_Update
export def "compute-clusters-storage-volumes Update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  volume_id: string # ID of the volume.
  --size-tib: int # Size of the volume in TiB.
]: any -> record<volume_id: string, volume_name: string, size_tib: int, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/compute/clusters/storage/volumes")
  let body = {volume_id: $volume_id, size_tib: $size_tib} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a shared volume
#
# POST /compute/clusters/storage/volumes
# operationId: SharedVolumeService_Create
export def "compute-clusters-storage-volumes Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  volume_name: string # User provided name of the volume.
  size_tib: int # Volume size in whole tebibytes (TiB).
  region: string # Region name. Usable regions can be found from `clusters.list_regions()`
  --is-lifecycle-independent: oneof<nothing, bool> # When true, the shared volume is not deleted when the cluster is decommissioned.
]: any -> record<volume_id: string, volume_name: string, size_tib: int, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/compute/clusters/storage/volumes")
  let body = {volume_name: $volume_name, size_tib: $size_tib, region: $region, is_lifecycle_independent: $is_lifecycle_independent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a shared volume by ID
#
# GET /compute/clusters/storage/volumes/{volume_id}
# operationId: SharedVolumeService_Get
export def "compute-clusters-storage-volumes Get" [
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<volume_id: string, volume_name: string, size_tib: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/compute/clusters/storage/volumes/($volume_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a shared volume by ID
#
# DELETE /compute/clusters/storage/volumes/{volume_id}
# operationId: SharedVolumeService_Delete
export def "compute-clusters-storage-volumes Delete" [
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/compute/clusters/storage/volumes/($volume_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all available availability zones
#
# GET /clusters/availability-zones
# operationId: availabilityZones
export def "clusters-availability-zones availabilityZones" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<avzones: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clusters/availability-zones")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all endpoints
#
# GET /endpoints
# operationId: listEndpoints
export def "endpoints listEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer
  --usage-type: string@usage-type-completer
  --mine: oneof<nothing, bool>
]: nothing -> record<object: any, data: table<object: any, id: string, name: string, model: string, type: string, owner: string, state: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "usage_type" $usage_type "scalar") (serialize-qp "mine" $mine "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a dedicated endpoint
#
# POST /endpoints
# operationId: createEndpoint
# --autoscaling shape: {min_replicas: int, max_replicas: int}
@deprecated --flag disable-prompt-cache
export def "endpoints createEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --display-name: string # A human-readable name for the endpoint (e.g. My Llama3 70b endpoint)
  model: string # The model to deploy on this endpoint (e.g. deepseek-ai/DeepSeek-R1)
  hardware: string # The hardware configuration to use for this endpoint (e.g. 1x_nvidia_a100_80gb_sxm)
  autoscaling: record # Configuration for automatic scaling of replicas based on demand. — shape: {min_replicas: int, max_replicas: int}
  --disable-prompt-cache: oneof<nothing, bool> # This parameter is deprecated and no longer has any effect. (DEPRECATED, default: false)
  --disable-speculative-decoding: oneof<nothing, bool> # Whether to disable speculative decoding for this endpoint (default: false)
  --state: string@state-completer # The desired state of the endpoint (default: STARTED, e.g. STARTED)
  --inactive-timeout: int # The number of minutes of inactivity after which the endpoint stops automatically. Set to null, omit, or set to 0 to disable automatic timeout. (nullable, e.g. 60)
  --availability-zone: string # Create the endpoint in a specified availability zone (e.g., us-central-4b)
]: any -> record<object: any, id: string, name: string, display_name: string, model: string, hardware: string, type: string, owner: string, state: string, autoscaling: record<min_replicas: int, max_replicas: int>, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/endpoints")
  let body = {display_name: $display_name, model: $model, hardware: $hardware, autoscaling: $autoscaling, disable_prompt_cache: $disable_prompt_cache, disable_speculative_decoding: $disable_speculative_decoding, state: $state, inactive_timeout: $inactive_timeout, availability_zone: $availability_zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get endpoint by ID
#
# GET /endpoints/{endpointId}
# operationId: getEndpoint
export def "endpoints get" [
  endpointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: any, id: string, name: string, display_name: string, model: string, hardware: string, type: string, owner: string, state: string, autoscaling: record<min_replicas: int, max_replicas: int>, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($endpointId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update endpoint, this can also be used to start or stop a dedicated endpoint
#
# PATCH /endpoints/{endpointId}
# operationId: updateEndpoint
# --autoscaling shape: {min_replicas: int, max_replicas: int}
export def "endpoints updateEndpoint" [
  endpointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --display-name: string # A human-readable name for the endpoint (e.g. My Llama3 70b endpoint)
  --state: string@state-completer # The desired state of the endpoint (e.g. STARTED)
  --autoscaling: record # Configuration for automatic scaling of replicas based on demand. — shape: {min_replicas: int, max_replicas: int}
  --inactive-timeout: int # The number of minutes of inactivity after which the endpoint stops automatically. Set to 0 to disable automatic timeout. (nullable, e.g. 60)
]: any -> record<object: any, id: string, name: string, display_name: string, model: string, hardware: string, type: string, owner: string, state: string, autoscaling: record<min_replicas: int, max_replicas: int>, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($endpointId)")
  let body = {display_name: $display_name, state: $state, autoscaling: $autoscaling, inactive_timeout: $inactive_timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete endpoint
#
# DELETE /endpoints/{endpointId}
# operationId: deleteEndpoint
export def "endpoints delete" [
  endpointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($endpointId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available hardware configurations
#
# GET /hardware
# operationId: listHardware
export def "hardware listHardware" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model: string # e.g. deepseek-ai/DeepSeek-R1
]: nothing -> record<object: any, data: table<object: any, id: string, pricing: record, specs: record, availability: record, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Execute code
#
# POST /tci/execute
# operationId: tci/execute
# --files item shape: {content: string, encoding: "string"|"base64", name: string}
export def "tci-execute tci/execute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string # Code snippet to execute. (e.g. print('Hello, world!'))
  --files: list # Files to upload to the session. If present, files are uploaded before executing the given code. — item shape: {content: string, encoding: "string"|"base64", name: string}
  language: any@language-completer # Programming language for the code to execute. Currently only supports Python. (default: python)
  --session-id: string # Identifier of the current session. Used to make follow-up calls. Returns an error if the session does not belong to the caller or has expired. (e.g. ses_abcDEF123)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tci/execute")
  let body = {code: $code, files: $files, language: $language, session_id: $session_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List active sessions
#
# GET /tci/sessions
# operationId: sessions/list
export def "tci-sessions sessions/list" [
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
  let full_url = (build-url $base "/tci/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List batch jobs
#
# GET /batches
export def "batches list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, user_id: string, input_file_id: string, file_size_bytes: int, status: string, job_deadline: string, created_at: string, endpoint: string, progress: float, model_id: string, output_file_id: string, error_file_id: string, error: string, completed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a batch job
#
# POST /batches
export def "batches post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  endpoint: string@endpoint-completer # The endpoint to use for batch processing. Each line of the uploaded input file is dispatched against this endpoint. - `/v1/chat/completions` — chat completion batches - `/v1/audio/transcriptions` — audio transcription batches (e.g. `openai/whisper-large-v3`) - `/v1/audio/translations` — audio translation batches  (e.g. /v1/chat/completions)
  input_file_id: string # ID of the uploaded input file containing batch requests (e.g. file-abc123def456ghi789)
  --completion-window: string # Time window for batch completion (optional) (e.g. 24h)
  --priority: int # Priority for batch processing (optional) (e.g. 1)
  --model-id: string # Model to use for processing batch requests (e.g. Qwen/Qwen3.5-9B)
]: any -> record<job: record<id: string, user_id: string, input_file_id: string, file_size_bytes: int, status: string, job_deadline: string, created_at: string, endpoint: string, progress: float, model_id: string, output_file_id: string, error_file_id: string, error: string, completed_at: string>, warning: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batches")
  let body = {endpoint: $endpoint, input_file_id: $input_file_id, completion_window: $completion_window, priority: $priority, model_id: $model_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a batch job
#
# GET /batches/{id}
export def "batches get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, user_id: string, input_file_id: string, file_size_bytes: int, status: string, job_deadline: string, created_at: string, endpoint: string, progress: float, model_id: string, output_file_id: string, error_file_id: string, error: string, completed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/batches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a batch job
#
# POST /batches/{id}/cancel
export def "batches-cancel post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, user_id: string, input_file_id: string, file_size_bytes: int, status: string, job_deadline: string, created_at: string, endpoint: string, progress: float, model_id: string, output_file_id: string, error_file_id: string, error: string, completed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/batches/($id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an evaluation job
#
# POST /evaluation
# operationId: createEvaluationJob
export def "evaluation createEvaluationJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-1 # The type of evaluation to perform (e.g. classify)
  parameters: any # Type-specific parameters for the evaluation
]: any -> record<workflow_id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/evaluation")
  let body = {type: $type, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all evaluation jobs
#
# GET /evaluation
# operationId: getAllEvaluationJobs
export def "evaluation list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string
  --limit: int # default: 10
]: nothing -> table<workflow_id: string, type: string, owner_id: string, status: string, status_updates: list<record>, parameters: record, created_at: string, updated_at: string, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/evaluation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get model list
#
# GET /evaluation/model-list
# operationId: getModelList
export def "evaluation-model-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model-source: string # default: all
]: nothing -> record<model_list: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model_source" $model_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/evaluation/model-list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get evaluation job details
#
# GET /evaluation/{id}
# operationId: getEvaluationJobDetails
export def "evaluation get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<workflow_id: string, type: string, owner_id: string, status: string, status_updates: table<status: string, message: string, timestamp: string>, parameters: record, created_at: string, updated_at: string, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/evaluation/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get evaluation job status and results
#
# GET /evaluation/{id}/status
# operationId: getEvaluationJobStatusAndResults
export def "evaluation-status get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/evaluation/($id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Real-time audio transcription via WebSocket
#
# GET /realtime
# operationId: realtime-transcription
export def "realtime realtime-transcription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model: string
  --input-audio-format: string@input-audio-format-completer # Audio format specification. Currently supports 16-bit PCM at 16kHz sample rate. (default: pcm_s16le_16000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar") (serialize-qp "input_audio_format" $input_audio_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/realtime" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a queued job
#
# POST /queue/cancel
# operationId: cancelQueueJob
export def "queue-cancel cancelQueueJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  model: string # Model identifier the job was submitted to
  request_id: string # The request ID returned from the submit endpoint
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/queue/cancel")
  let body = {model: $model, request_id: $request_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get queue metrics
#
# GET /queue/metrics
# operationId: getQueueMetrics
export def "queue-metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model: string
]: nothing -> record<messages_running: int, messages_waiting: int, total_jobs: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/queue/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get job status
#
# GET /queue/status
# operationId: getQueueJobStatus
export def "queue-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request-id: string
  --model: string
]: nothing -> record<claimed_at: string, created_at: string, done_at: string, info: record, inputs: record, model: string, outputs: record, priority: int, request_id: string, retries: int, status: string, warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "request_id" $request_id "scalar") (serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/queue/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit a queued job
#
# POST /queue/submit
# operationId: submitQueueJob
export def "queue-submit submitQueueJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --info: record # Arbitrary JSON metadata stored with the job. Returned in status responses, where the model and system may have added or modified keys (e.g. progress).
  model: string # Required model identifier (e.g. my-queue-model)
  payload: record # Freeform model input. Passed unchanged to the model. Contents are model-specific.
  --priority: int # Job priority. Higher values are processed first (strict priority ordering). Jobs with equal priority are processed in submission order (FIFO).  (default: 0)
]: any -> record<requestId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/queue/submit")
  let body = {info: $info, model: $model, payload: $payload, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List model resources
#
# GET /rl/model-resources
# operationId: listModelResources
export def "rl-model-resources listModelResources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer
  --limit: int # format: int32, default: 20
  --after: string
]: nothing -> record<data: table<id: string, status: string, base_model: string, type: string, lora_enabled: bool, created_at: string, updated_at: string>, meta: record<limit: int, has_more: bool, next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rl/model-resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create model resources
#
# POST /rl/model-resources
# operationId: createModelResources
export def "rl-model-resources createModelResources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  base_model: string # Base model to provision the resource for (e.g. Qwen/Qwen3-0.6B)
  --type: string@type-completer-2 # Type of a training session. TRAINER_AND_GENERATOR provisions both trainer and generator; TRAINER_ONLY provisions only the trainer and rejects generator-dependent operations such as sample. (default: SESSION_TYPE_UNSPECIFIED)
  --lora-enabled: oneof<nothing, bool> # Whether the resource hosts LoRA sessions or a single full-weight session (default: true, e.g. true)
]: any -> record<id: string, status: string, base_model: string, type: string, lora_enabled: bool, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rl/model-resources")
  let body = {base_model: $base_model, type: $type, lora_enabled: $lora_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get model resources
#
# GET /rl/model-resources/{model_resources_id}
# operationId: getModelResources
export def "rl-model-resources get" [
  model_resources_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, base_model: string, type: string, lora_enabled: bool, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/model-resources/($model_resources_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete model resources
#
# DELETE /rl/model-resources/{model_resources_id}
# operationId: deleteModelResources
export def "rl-model-resources delete" [
  model_resources_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, base_model: string, type: string, lora_enabled: bool, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/model-resources/($model_resources_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List training sessions
#
# GET /rl/training-sessions
# operationId: listTrainingSessions
export def "rl-training-sessions listTrainingSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-1 # default: TRAINING_SESSION_STATUS_UNSPECIFIED
  --limit: int # format: int32, default: 20
  --after: string
  --model-resources-id: string
]: nothing -> record<data: table<id: string, status: string, base_model: string, inference_checkpoints: list, training_checkpoints: list, resume_from_checkpoint_id: string, step: any, created_at: string, updated_at: string, lora_config: record, optimizer_config: record, type: string, model_resources_id: string>, meta: record<limit: int, has_more: bool, next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "model_resources_id" $model_resources_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rl/training-sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create training session
#
# POST /rl/training-sessions
# operationId: startTrainingSession
# --lora_config shape: {rank?: int, alpha?: int, dropout?: float, enable?: bool}
# --optimizer_config shape: {name?: "AdamW"|"Muon", muon?: record}
export def "rl-training-sessions startTrainingSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-model: string # Base model to use for the training session. Required unless model_resources_id is set. (e.g. meta-llama/Meta-Llama-3-8B-Instruct)
  --resume-from-checkpoint-id: string # Checkpoint ID to resume from (e.g. 123e4567-e89b-12d3-a456-426614174000)
  --resume-from-hf-checkpoint: string # HuggingFace repo (or hf://) to resume model weights from. Accepts either a full model or a PEFT adapter directory. Mutually exclusive with resume_from_checkpoint_id. (e.g. your-org/llama-3-8b-finetuned)
  --type: string@type-completer-2 # Type of a training session. TRAINER_AND_GENERATOR provisions both trainer and generator; TRAINER_ONLY provisions only the trainer and rejects generator-dependent operations such as sample. (default: SESSION_TYPE_UNSPECIFIED)
  --lora-config: record # LoRA adapter configuration — shape: {rank?: int, alpha?: int, dropout?: float, enable?: bool}
  --optimizer-config: record # Optimizer selection for the training session. Fields here are fixed for the session's lifetime; tunable per-step hyperparameters are configured on each OptimStep request instead. — shape: {name?: "AdamW"|"Muon", muon?: record}
  --model-resources-id: string # Existing model resource to attach the session to. When set, base_model and type are inherited from the resource. (e.g. 123e4567-e89b-12d3-a456-426614174000)
]: any -> record<id: string, status: string, base_model: string, inference_checkpoints: table<id: string, step: any, created_at: string, registration: record>, training_checkpoints: table<id: string, step: any, created_at: string>, resume_from_checkpoint_id: string, step: any, created_at: string, updated_at: string, lora_config: record<rank: int, alpha: int, dropout: float, enable: bool>, optimizer_config: record<name: string, muon: record<scale_mode: string>>, type: string, model_resources_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rl/training-sessions")
  let body = {base_model: $base_model, resume_from_checkpoint_id: $resume_from_checkpoint_id, resume_from_hf_checkpoint: $resume_from_hf_checkpoint, type: $type, lora_config: $lora_config, optimizer_config: $optimizer_config, model_resources_id: $model_resources_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List supported models
#
# GET /rl/supported-models
# operationId: listSupportedModels
export def "rl-supported-models listSupportedModels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<base_model: string, trainer_config: record, generator_config: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rl/supported-models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get training session
#
# GET /rl/training-sessions/{session_id}
# operationId: getTrainingSession
export def "rl-training-sessions get" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, base_model: string, inference_checkpoints: table<id: string, step: any, created_at: string, registration: record>, training_checkpoints: table<id: string, step: any, created_at: string>, resume_from_checkpoint_id: string, step: any, created_at: string, updated_at: string, lora_config: record<rank: int, alpha: int, dropout: float, enable: bool>, optimizer_config: record<name: string, muon: record<scale_mode: string>>, type: string, model_resources_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop training session
#
# POST /rl/training-sessions/{session_id}/stop
# operationId: stopTrainingSession
export def "rl-training-sessions-stop stopTrainingSession" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, base_model: string, inference_checkpoints: table<id: string, step: any, created_at: string, registration: record>, training_checkpoints: table<id: string, step: any, created_at: string>, resume_from_checkpoint_id: string, step: any, created_at: string, updated_at: string, lora_config: record<rank: int, alpha: int, dropout: float, enable: bool>, optimizer_config: record<name: string, muon: record<scale_mode: string>>, type: string, model_resources_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get forward-backward operation
#
# GET /rl/training-sessions/{session_id}/operations/forward-backward/{operation_id}
# operationId: getForwardBackwardOperation
export def "rl-training-sessions-operations-forward-backward get" [
  session_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, output: record<loss: float, metrics: record>, error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/forward-backward/($operation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get optim-step operation
#
# GET /rl/training-sessions/{session_id}/operations/optim-step/{operation_id}
# operationId: getOptimStepOperation
export def "rl-training-sessions-operations-optim-step get" [
  session_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, output: record<step: any>, error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/optim-step/($operation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get sample operation
#
# GET /rl/training-sessions/{session_id}/operations/sample/{operation_id}
# operationId: GetSample
export def "rl-training-sessions-operations-sample GetSample" [
  session_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, output: record<rollouts: list<record>>, error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/sample/($operation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Forward-backward pass
#
# POST /rl/training-sessions/{session_id}/operations/forward-backward
# operationId: forwardBackward
# --samples item shape: {model_input: record, loss_inputs: record}
# --loss shape: {type: "LOSS_TYPE_UNSPECIFIED"|"LOSS_TYPE_CROSS_ENTROPY"|"LOSS_TYPE_GRPO", cross_entropy_params?: record, grpo_params?: record}
export def "rl-training-sessions-operations-forward-backward forwardBackward" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  samples: list # Batch of training samples to process — item shape: {model_input: record, loss_inputs: record}
  loss: record # shape: {type: "LOSS_TYPE_UNSPECIFIED"|"LOSS_TYPE_CROSS_ENTROPY"|"LOSS_TYPE_GRPO", cross_entropy_params?: record, grpo_params?: record}
]: any -> record<id: string, status: string, output: record<loss: float, metrics: record>, error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/forward-backward")
  let body = {samples: $samples, loss: $loss} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Custom forward-backward pass
#
# POST /rl/training-sessions/{session_id}/operations/custom-forward-backward
# operationId: customForwardBackward
# --samples item shape: {model_input: record, loss_inputs: record}
# --gradients item shape: {data: list, dtype?: "D_TYPE_UNSPECIFIED"|"D_TYPE_INT64"|"D_TYPE_FLOAT32"|"D_TYPE_BFLOAT16"}
export def "rl-training-sessions-operations-custom-forward-backward customForwardBackward" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  samples: list # Batch of training samples — item shape: {model_input: record, loss_inputs: record}
  gradients: list # Per-sample per-token gradients of the loss with respect to log-probabilities — item shape: {data: list, dtype?: "D_TYPE_UNSPECIFIED"|"D_TYPE_INT64"|"D_TYPE_FLOAT32"|"D_TYPE_BFLOAT16"}
]: any -> record<id: string, status: string, output: record, error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/custom-forward-backward")
  let body = {samples: $samples, gradients: $gradients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get custom forward-backward operation
#
# GET /rl/training-sessions/{session_id}/operations/custom-forward-backward/{operation_id}
# operationId: getCustomForwardBackwardOperation
export def "rl-training-sessions-operations-custom-forward-backward get" [
  session_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, output: record, error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/custom-forward-backward/($operation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Forward pass
#
# POST /rl/training-sessions/{session_id}/operations/forward
# operationId: forward
# --samples item shape: {model_input: record, loss_inputs: record}
export def "rl-training-sessions-operations-forward forward" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  samples: list # Batch of training samples for which to compute per-token log-probabilities — item shape: {model_input: record, loss_inputs: record}
]: any -> record<id: string, status: string, output: record<logprobs: list<record>>, error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/forward")
  let body = {samples: $samples} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get forward operation
#
# GET /rl/training-sessions/{session_id}/operations/forward/{operation_id}
# operationId: getForwardOperation
export def "rl-training-sessions-operations-forward get" [
  session_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, output: record<logprobs: list<record>>, error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/forward/($operation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Optimizer step
#
# POST /rl/training-sessions/{session_id}/operations/optim-step
# operationId: OptimStep
# --adamw_params shape: {lr?: float, beta1?: float, beta2?: float, eps?: float, weight_decay?: float}
# --muon_params shape: {lr?: float, momentum?: float, newton_schulz_steps?: int, weight_decay?: float}
export def "rl-training-sessions-operations-optim-step OptimStep" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --learning-rate: float # Learning rate to apply on this step. When adamw_params.lr or muon_params.lr is also set, those take precedence for the parameters they target; this field applies to any parameters not covered by a more specific override. (format: float, default: 0.0001, e.g. 0.0001)
  --adamw-params: record # Per-step overrides for AdamW hyperparameters. In an AdamW session this tunes the entire model. In a Muon session this tunes the parts of the model that Muon does not, typically embeddings, normalization layers, and the language-model head. — shape: {lr?: float, beta1?: float, beta2?: float, eps?: float, weight_decay?: float}
  --muon-params: record # Per-step overrides for Muon-specific hyperparameters. Applied to the model's weight matrices; the rest of the model is tuned via AdamWOptimizerParams. Rejected on sessions started with a non-Muon optimizer. — shape: {lr?: float, momentum?: float, newton_schulz_steps?: int, weight_decay?: float}
  --max-grad-norm: float # Gradient norm clipping threshold for this step. Applied to the full model gradient norm, not per-parameter-group. When unset, the previous step's value is reused. (format: float, e.g. 1)
]: any -> record<id: string, status: string, output: record<step: any>, error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/optim-step")
  let body = {learning_rate: $learning_rate, adamw_params: $adamw_params, muon_params: $muon_params, max_grad_norm: $max_grad_norm} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sample
#
# POST /rl/training-sessions/{session_id}/operations/sample
# operationId: Sample
# --prompts item shape: {chunks: list}
# --sampling_params shape: {max_tokens?: int, temperature?: float, top_p?: float, top_k?: int, stop?: list, seed?: any}
export def "rl-training-sessions-operations-sample Sample" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  prompts: list # Input prompts as tokenized chunks — item shape: {chunks: list}
  --sampling-params: record # shape: {max_tokens?: int, temperature?: float, top_p?: float, top_k?: int, stop?: list, seed?: any}
  --num-samples: int # Number of completions to generate per prompt (format: int64, default: 1, e.g. 1)
]: any -> record<id: string, status: string, output: record<rollouts: list<record>>, error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/sample")
  let body = {prompts: $prompts, sampling_params: $sampling_params, num_samples: $num_samples} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create inference checkpoint
#
# POST /rl/training-sessions/{session_id}/operations/inference-checkpoint
# operationId: createInferenceCheckpoint
export def "rl-training-sessions-operations-inference-checkpoint createInferenceCheckpoint" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, output: record<model_name: string>, error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/inference-checkpoint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get inference checkpoint operation
#
# GET /rl/training-sessions/{session_id}/operations/inference-checkpoint/{operation_id}
# operationId: getInferenceCheckpointOperation
export def "rl-training-sessions-operations-inference-checkpoint get" [
  session_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, output: record<model_name: string>, error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/inference-checkpoint/($operation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Save training checkpoint
#
# POST /rl/training-sessions/{session_id}/operations/training-checkpoint
# operationId: createTrainingCheckpoint
export def "rl-training-sessions-operations-training-checkpoint createTrainingCheckpoint" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, output: record<checkpoint_id: string>, error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/training-checkpoint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get save training checkpoint operation
#
# GET /rl/training-sessions/{session_id}/operations/training-checkpoint/{operation_id}
# operationId: getTrainingCheckpointOperation
export def "rl-training-sessions-operations-training-checkpoint get" [
  session_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, output: record<checkpoint_id: string>, error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rl/training-sessions/($session_id)/operations/training-checkpoint/($operation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download checkpoint
#
# GET /rl/checkpoints/{id}/download
# operationId: downloadCheckpoint
export def "rl-checkpoints-download downloadCheckpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --variant: string@variant-completer # default: CHECKPOINT_VARIANT_UNSPECIFIED
]: nothing -> record<data: table<filename: string, url: string, size: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variant" $variant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rl/checkpoints/($id)/download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /compute/clusters/{cluster_id}/addons
#
# operationId: InstanceClusterAddOnService_List
export def "compute-clusters-addons List" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<add_ons: table<name: string, add_on_type: string, config: record, state: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)/addons")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /compute/clusters/{cluster_id}/addons
#
# operationId: InstanceClusterAddOnService_Create
# --config shape: {dashboard?: record, ingress?: record}
export def "compute-clusters-addons Create" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  add_on_type: string
  --config: record # shape: {dashboard?: record, ingress?: record}
]: any -> record<name: string, add_on_type: string, config: record<dashboard: record<enabled: bool>, ingress: record<enabled: bool>>, state: record<dashboard: record, ingress: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)/addons")
  let body = {name: $name, add_on_type: $add_on_type, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /compute/clusters/{cluster_id}/addons/{addon_id}
#
# operationId: InstanceClusterAddOnService_Get
export def "compute-clusters-addons Get" [
  cluster_id: string
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, add_on_type: string, config: record<dashboard: record<enabled: bool>, ingress: record<enabled: bool>>, state: record<dashboard: record, ingress: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)/addons/($addon_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /compute/clusters/{cluster_id}/addons/{addon_id}
#
# operationId: InstanceClusterAddOnService_Update
# --config shape: {dashboard?: record, ingress?: record}
export def "compute-clusters-addons Update" [
  cluster_id: string
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config: record # shape: {dashboard?: record, ingress?: record}
]: any -> record<name: string, add_on_type: string, config: record<dashboard: record<enabled: bool>, ingress: record<enabled: bool>>, state: record<dashboard: record, ingress: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)/addons/($addon_id)")
  let body = {config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /compute/clusters/{cluster_id}/addons/{addon_id}
#
# operationId: InstanceClusterAddOnService_Delete
export def "compute-clusters-addons Delete" [
  cluster_id: string
  addon_id: string
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
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)/addons/($addon_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List remediations
#
# GET /compute/clusters/{cluster_id}/instances/{instance_id}/remediations
# operationId: RemediationService_ListRemediations
export def "compute-clusters-instances-remediations ListRemediations" [
  cluster_id: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int
  --page-token: string
  --state: list
  --order-by: string
  --trigger: list
  --mode: list
]: nothing -> record<remediations: table<id: string, cluster_id: string, instance_id: string, mode: string, trigger: string, state: string, reason: string, active_health_check_run_id: string, passive_health_check_event_id: string, requested_by: string, create_time: string, reviewed_by: string, review_time: string, review_comment: string, start_time: string, end_time: string, error_message: string, update_time: string, instance_name: string>, next_page_token: string, has_next: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "state" $state "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "trigger" $trigger "multi") (serialize-qp "mode" $mode "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)/instances/($instance_id)/remediations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new remediation for an instance.  Remediations created via the API goes directly to PENDING state.  Our system may trigger automated remediations that require approval. These remediations are created with PENDING_APPROVAL state. The user must call /approve to start the actual remediation process. These operations can also be rejected by calling /reject.
#
# POST /compute/clusters/{cluster_id}/instances/{instance_id}/remediations
# operationId: RemediationService_CreateRemediation
export def "compute-clusters-instances-remediations CreateRemediation" [
  cluster_id: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --remediation-id: string
  mode: string@mode-completer # Remediation mode specifies how the remediation should be performed.  - `REMEDIATION_MODE_VM_ONLY`: Deletes the VM and provisions a new one on any available host. - `REMEDIATION_MODE_HOST_AWARE`: Cordons the host, deletes the VM, and provisions a new one on a different host.
  --reason: string # User-provided reason for the remediation.
]: any -> record<id: string, cluster_id: string, instance_id: string, mode: string, trigger: string, state: string, reason: string, active_health_check_run_id: string, passive_health_check_event_id: string, requested_by: string, create_time: string, reviewed_by: string, review_time: string, review_comment: string, start_time: string, end_time: string, error_message: string, update_time: string, instance_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "remediation_id" $remediation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)/instances/($instance_id)/remediations" $qp)
  let body = {mode: $mode, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the status of a specific remdiation on a specific instance in a specific cluster.
#
# GET /compute/clusters/{cluster_id}/instances/{instance_id}/remediations/{remediation_id}
# operationId: RemediationService_GetRemediation
export def "compute-clusters-instances-remediations GetRemediation" [
  cluster_id: string
  instance_id: string
  remediation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, cluster_id: string, instance_id: string, mode: string, trigger: string, state: string, reason: string, active_health_check_run_id: string, passive_health_check_event_id: string, requested_by: string, create_time: string, reviewed_by: string, review_time: string, review_comment: string, start_time: string, end_time: string, error_message: string, update_time: string, instance_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)/instances/($instance_id)/remediations/($remediation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Approves a pending remediation.  Only remediations with state PENDING_APPROVAL can be approved.  On APPROVE: state changes to PENDING and the remediation process begins. The reviewed_by, review_time, and review_comment fields are populated on the remediation after approval.
#
# POST /compute/clusters/{cluster_id}/instances/{instance_id}/remediations/{remediation_id}/approve
# operationId: RemediationService_ApproveRemediation
export def "compute-clusters-instances-remediations-approve ApproveRemediation" [
  cluster_id: string
  instance_id: string
  remediation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comment: string # Comment explaining the action.
]: any -> record<id: string, cluster_id: string, instance_id: string, mode: string, trigger: string, state: string, reason: string, active_health_check_run_id: string, passive_health_check_event_id: string, requested_by: string, create_time: string, reviewed_by: string, review_time: string, review_comment: string, start_time: string, end_time: string, error_message: string, update_time: string, instance_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)/instances/($instance_id)/remediations/($remediation_id)/approve")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancels a pending remediation.  Only remediations in PENDING_APPROVAL or PENDING state can be cancelled.
#
# POST /compute/clusters/{cluster_id}/instances/{instance_id}/remediations/{remediation_id}/cancel
# operationId: RemediationService_CancelRemediation
export def "compute-clusters-instances-remediations-cancel CancelRemediation" [
  cluster_id: string
  instance_id: string
  remediation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, cluster_id: string, instance_id: string, mode: string, trigger: string, state: string, reason: string, active_health_check_run_id: string, passive_health_check_event_id: string, requested_by: string, create_time: string, reviewed_by: string, review_time: string, review_comment: string, start_time: string, end_time: string, error_message: string, update_time: string, instance_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)/instances/($instance_id)/remediations/($remediation_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rejects a pending remediation.  Only remediations with state PENDING_APPROVAL can be rejected.  On REJECT: state changes to CANCELLED. The reviewed_by, review_time, and review_comment fields are populated on the remediation after rejection.
#
# POST /compute/clusters/{cluster_id}/instances/{instance_id}/remediations/{remediation_id}/reject
# operationId: RemediationService_RejectRemediation
export def "compute-clusters-instances-remediations-reject RejectRemediation" [
  cluster_id: string
  instance_id: string
  remediation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comment: string # Comment explaining the action.
]: any -> record<id: string, cluster_id: string, instance_id: string, mode: string, trigger: string, state: string, reason: string, active_health_check_run_id: string, passive_health_check_event_id: string, requested_by: string, create_time: string, reviewed_by: string, review_time: string, review_comment: string, start_time: string, end_time: string, error_message: string, update_time: string, instance_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/compute/clusters/($cluster_id)/instances/($instance_id)/remediations/($remediation_id)/reject")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
