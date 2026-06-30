# Auto-generated client for AWS Batch v2016-08-10
# Source: https://api.apis.guru/v2/specs/amazonaws.com/batch/2016-08-10/openapi.json
# Auth: --token flag or $env.AWS_BATCH_TOKEN

const BASE_URL = "http://batch.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_BATCH_TOKEN | default "" }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://batch.us-east-1.amazonaws.com" "http://batch.us-east-2.amazonaws.com" "http://batch.us-west-1.amazonaws.com" "http://batch.us-west-2.amazonaws.com" "http://batch.us-gov-west-1.amazonaws.com" "http://batch.us-gov-east-1.amazonaws.com" "http://batch.ca-central-1.amazonaws.com" "http://batch.eu-north-1.amazonaws.com" "http://batch.eu-west-1.amazonaws.com" "http://batch.eu-west-2.amazonaws.com" "http://batch.eu-west-3.amazonaws.com" "http://batch.eu-central-1.amazonaws.com" "http://batch.eu-south-1.amazonaws.com" "http://batch.af-south-1.amazonaws.com" "http://batch.ap-northeast-1.amazonaws.com" "http://batch.ap-northeast-2.amazonaws.com" "http://batch.ap-northeast-3.amazonaws.com" "http://batch.ap-southeast-1.amazonaws.com" "http://batch.ap-southeast-2.amazonaws.com" "http://batch.ap-east-1.amazonaws.com" "http://batch.ap-south-1.amazonaws.com" "http://batch.sa-east-1.amazonaws.com" "http://batch.me-south-1.amazonaws.com" "https://batch.us-east-1.amazonaws.com" "https://batch.us-east-2.amazonaws.com" "https://batch.us-west-1.amazonaws.com" "https://batch.us-west-2.amazonaws.com" "https://batch.us-gov-west-1.amazonaws.com" "https://batch.us-gov-east-1.amazonaws.com" "https://batch.ca-central-1.amazonaws.com" "https://batch.eu-north-1.amazonaws.com" "https://batch.eu-west-1.amazonaws.com" "https://batch.eu-west-2.amazonaws.com" "https://batch.eu-west-3.amazonaws.com" "https://batch.eu-central-1.amazonaws.com" "https://batch.eu-south-1.amazonaws.com" "https://batch.af-south-1.amazonaws.com" "https://batch.ap-northeast-1.amazonaws.com" "https://batch.ap-northeast-2.amazonaws.com" "https://batch.ap-northeast-3.amazonaws.com" "https://batch.ap-southeast-1.amazonaws.com" "https://batch.ap-southeast-2.amazonaws.com" "https://batch.ap-east-1.amazonaws.com" "https://batch.ap-south-1.amazonaws.com" "https://batch.sa-east-1.amazonaws.com" "https://batch.me-south-1.amazonaws.com" "http://batch.cn-north-1.amazonaws.com.cn" "http://batch.cn-northwest-1.amazonaws.com.cn" "https://batch.cn-north-1.amazonaws.com.cn" "https://batch.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["MANAGED" "UNMANAGED"] }
def state-completer [] { ["DISABLED" "ENABLED"] }
def job-status-completer [] { ["FAILED" "PENDING" "RUNNABLE" "RUNNING" "STARTING" "SUBMITTED" "SUCCEEDED"] }
def type-completer-1 [] { ["container" "multinode"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "canceljob cancel-job" } } | get name | first)
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

# Cancels a job in an Batch job queue. Jobs that are in the SUBMITTED or PENDING are canceled. A job inRUNNABLE remains in RUNNABLE until it reaches the head of the job queue. Then the job status is updated to FAILED. Jobs that progressed to the STARTING or RUNNING state aren't canceled. However, the API operation still succeeds, even if no job is canceled. These jobs must be terminated with the TerminateJob operation.
#
# POST /v1/canceljob
# operationId: CancelJob
export def "canceljob cancel-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  job_id: string # The Batch job ID of the job to cancel.
  reason: string # A message to attach to the job that explains the reason for canceling it. This message is returned by future DescribeJobs operations on the job. This message is also recorded in the Batch activity logs.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/canceljob" $auth.query)
  let req_body = {"jobId": $job_id, "reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates an Batch compute environment. You can create MANAGED or UNMANAGED compute environments. MANAGED compute environments can use Amazon EC2 or Fargate resources. UNMANAGED compute environments can only use EC2 resources. In a managed compute environment, Batch manages the capacity and instance types of the compute resources within the environment. This is based on the compute resource specification that you define or the launch template (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html) that you specify when you create the compute environment. Either, you can choose to use EC2 On-Demand Instances and EC2 Spot Instances. Or, you can use Fargate and Fargate Spot capacity in your managed compute environment. You can optionally set a maximum price so that Spot Instances only launch when the Spot Instance price is less than a specified percentage of the On-Demand price. Multi-node parallel jobs aren't supported on Spot Instances. In an unmanaged compute environment, you can manage your own EC2 compute resources and have flexibility with how you configure your compute resources. For example, you can use custom AMIs. However, you must verify that each of your AMIs meet the Amazon ECS container instance AMI specification. For more information, see container instance AMIs (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container_instance_AMIs.html) in the Amazon Elastic Container Service Developer Guide. After you created your unmanaged compute environment, you can use the DescribeComputeEnvironments operation to find the Amazon ECS cluster that's associated with it. Then, launch your container instances into that Amazon ECS cluster. For more information, see Launching an Amazon ECS container instance (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html) in the Amazon Elastic Container Service Developer Guide. To create a compute environment that uses EKS resources, the caller must have permissions to call eks:DescribeCluster. Batch doesn't automatically upgrade the AMIs in a compute environment after it's created. For example, it also doesn't update the AMIs in your compute environment when a newer version of the Amazon ECS optimized AMI is available. You're responsible for the management of the guest operating system. This includes any updates and security patches. You're also responsible for any additional application software or utilities that you install on the compute resources. There are two ways to use a new AMI for your Batch jobs. The original method is to complete these steps: Create a new compute environment with the new AMI. Add the compute environment to an existing job queue. Remove the earlier compute environment from your job queue. Delete the earlier compute environment. In April 2022, Batch added enhanced support for updating compute environments. For more information, see Updating compute environments (https://docs.aws.amazon.com/batch/latest/userguide/updating-compute-environments.html). To use the enhanced updating of compute environments to update AMIs, follow these rules: Either don't set the service role (serviceRole) parameter or set it to the AWSBatchServiceRole service-linked role. Set the allocation strategy (allocationStrategy) parameter to BEST_FIT_PROGRESSIVE or SPOT_CAPACITY_OPTIMIZED. Set the update to latest image version (updateToLatestImageVersion) parameter to true. Don't specify an AMI ID in imageId, imageIdOverride (in ec2Configuration (https://docs.aws.amazon.com/batch/latest/APIReference/API_Ec2Configuration.html)), or in the launch template (launchTemplate). In that case, Batch selects the latest Amazon ECS optimized AMI that's supported by Batch at the time the infrastructure update is initiated. Alternatively, you can specify the AMI ID in the imageId or imageIdOverride parameters, or the launch template identified by the LaunchTemplate properties. Changing any of these properties starts an infrastructure update. If the AMI ID is specified in the launch template, it can't be replaced by specifying an AMI ID in either the imageId or imageIdOverride parameters. It can only be replaced by specifying a different launch template, or if the launch template version is set to $Default or $Latest, by setting either a new default version for the launch template (if $Default) or by adding a new version to the launch template (if $Latest). If these rules are followed, any update that starts an infrastructure update causes the AMI ID to be re-selected. If the version setting in the launch template (launchTemplate) is set to $Latest or $Default, the latest or default version of the launch template is evaluated up at the time of the infrastructure update, even if the launchTemplate wasn't updated.
#
# POST /v1/createcomputeenvironment
# operationId: CreateComputeEnvironment
# --computeResources shape: {type?: any, allocationStrategy?: any, minvCpus?: any, maxvCpus?: any, desiredvCpus?: any, instanceTypes?: any, imageId?: any, subnets?: any, securityGroupIds?: any, ec2KeyPair?: any, instanceRole?: any, tags?: any, placementGroup?: any, bidPercentage?: any, spotIamFleetRole?: any, launchTemplate?: any, ec2Configuration?: any}
# --eksConfiguration shape: {eksClusterArn?: any, kubernetesNamespace?: any}
export def "create-computeenvironment create-compute-environment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  compute_environment_name: string # The name for your compute environment. It can be up to 128 characters long. It can contain uppercase and lowercase letters, numbers, hyphens (-), and underscores (_).
  type: string@type-completer # The type of the compute environment: MANAGED or UNMANAGED. For more information, see Compute Environments (https://docs.aws.amazon.com/batch/latest/userguide/compute_environments.html) in the Batch User Guide.
  --state: string@state-completer # The state of the compute environment. If the state is ENABLED, then the compute environment accepts jobs from a queue and can scale out automatically based on queues. If the state is ENABLED, then the Batch scheduler can attempt to place jobs from an associated job queue on the compute resources within the environment. If the compute environment is managed, then it can scale its instances out or in automatically, based on the job queue demand. If the state is DISABLED, then the Batch scheduler doesn't attempt to place jobs within the environment. Jobs in a STARTING or RUNNING state continue to progress normally. Managed compute environments in the DISABLED state don't scale out. Compute environments in a DISABLED state may continue to incur billing charges. To prevent additional charges, turn off and then delete the compute environment. For more information, see State (https://docs.aws.amazon.com/batch/latest/userguide/compute_environment_parameters.html#compute_environment_state) in the Batch User Guide. When an instance is idle, the instance scales down to the minvCpus value. However, the instance size doesn't change. For example, consider a c5.8xlarge instance with a minvCpus value of 4 and a desiredvCpus value of 36. This instance doesn't scale down to a c5.large instance.
  --unmanagedv-cpus: int # The maximum number of vCPUs for an unmanaged compute environment. This parameter is only used for fair share scheduling to reserve vCPU capacity for new share identifiers. If this parameter isn't provided for a fair share job queue, no vCPU capacity is reserved. This parameter is only supported when the type parameter is set to UNMANAGED.
  --compute-resources: record # An object that represents an Batch compute resource. For more information, see Compute environments (https://docs.aws.amazon.com/batch/latest/userguide/compute_environments.html) in the Batch User Guide. — shape: {type?: any, allocationStrategy?: any, minvCpus?: any, maxvCpus?: any, desiredvCpus?: any, instanceTypes?: any, imageId?: any, subnets?: any, securityGroupIds?: any, ec2KeyPair?: any, instanceRole?: any, tags?: any, placementGroup?: any, bidPercentage?: any, spotIamFleetRole?: any, launchTemplate?: any, ec2Configuration?: any}
  --service-role: string # The full Amazon Resource Name (ARN) of the IAM role that allows Batch to make calls to other Amazon Web Services services on your behalf. For more information, see Batch service IAM role (https://docs.aws.amazon.com/batch/latest/userguide/service_IAM_role.html) in the Batch User Guide. If your account already created the Batch service-linked role, that role is used by default for your compute environment unless you specify a different role here. If the Batch service-linked role doesn't exist in your account, and no role is specified here, the service attempts to create the Batch service-linked role in your account. If your specified role has a path other than /, then you must specify either the full role ARN (recommended) or prefix the role name with the path. For example, if a role with the name bar has a path of /foo/, specify /foo/bar as the role name. For more information, see Friendly names and paths (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-friendly-names) in the IAM User Guide. Depending on how you created your Batch service role, its ARN might contain the service-role path prefix. When you only specify the name of the service role, Batch assumes that your ARN doesn't use the service-role path prefix. Because of this, we recommend that you specify the full ARN of your service role when you create compute environments.
  --tags: record # The tags that you apply to the compute environment to help you categorize and organize your resources. Each tag consists of a key and an optional value. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in Amazon Web Services General Reference. These tags can be updated or removed using the TagResource (https://docs.aws.amazon.com/batch/latest/APIReference/API_TagResource.html) and UntagResource (https://docs.aws.amazon.com/batch/latest/APIReference/API_UntagResource.html) API operations. These tags don't propagate to the underlying compute resources.
  --eks-configuration: record # Configuration for the Amazon EKS cluster that supports the Batch compute environment. The cluster must exist before the compute environment can be created. — shape: {eksClusterArn?: any, kubernetesNamespace?: any}
]: any -> record<computeEnvironmentName: record, computeEnvironmentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/createcomputeenvironment" $auth.query)
  let req_body = {"computeEnvironmentName": $compute_environment_name, "type": $type, "state": $state, "unmanagedvCpus": $unmanagedv_cpus, "computeResources": $compute_resources, "serviceRole": $service_role, "tags": $tags, "eksConfiguration": $eks_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates an Batch job queue. When you create a job queue, you associate one or more compute environments to the queue and assign an order of preference for the compute environments. You also set a priority to the job queue that determines the order that the Batch scheduler places jobs onto its associated compute environments. For example, if a compute environment is associated with more than one job queue, the job queue with a higher priority is given preference for scheduling jobs to that compute environment.
#
# POST /v1/createjobqueue
# operationId: CreateJobQueue
# --computeEnvironmentOrder item shape: {order: any, computeEnvironment: any}
export def "create-jobqueue create-job-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  job_queue_name: string # The name of the job queue. It can be up to 128 letters long. It can contain uppercase and lowercase letters, numbers, hyphens (-), and underscores (_).
  --state: string@state-completer # The state of the job queue. If the job queue state is ENABLED, it is able to accept jobs. If the job queue state is DISABLED, new jobs can't be added to the queue, but jobs already in the queue can finish.
  --scheduling-policy-arn: string # The Amazon Resource Name (ARN) of the fair share scheduling policy. If this parameter is specified, the job queue uses a fair share scheduling policy. If this parameter isn't specified, the job queue uses a first in, first out (FIFO) scheduling policy. After a job queue is created, you can replace but can't remove the fair share scheduling policy. The format is aws:Partition:batch:Region:Account:scheduling-policy/Name . An example is aws:aws:batch:us-west-2:123456789012:scheduling-policy/MySchedulingPolicy.
  priority: int # The priority of the job queue. Job queues with a higher priority (or a higher integer value for the priority parameter) are evaluated first when associated with the same compute environment. Priority is determined in descending order. For example, a job queue with a priority value of 10 is given scheduling preference over a job queue with a priority value of 1. All of the compute environments must be either EC2 (EC2 or SPOT) or Fargate (FARGATE or FARGATE_SPOT); EC2 and Fargate compute environments can't be mixed.
  compute_environment_order: list # The set of compute environments mapped to a job queue and their order relative to each other. The job scheduler uses this parameter to determine which compute environment runs a specific job. Compute environments must be in the VALID state before you can associate them with a job queue. You can associate up to three compute environments with a job queue. All of the compute environments must be either EC2 (EC2 or SPOT) or Fargate (FARGATE or FARGATE_SPOT); EC2 and Fargate compute environments can't be mixed. All compute environments that are associated with a job queue must share the same architecture. Batch doesn't support mixing compute environment architecture types in a single job queue. — item shape: {order: any, computeEnvironment: any}
  --tags: record # The tags that you apply to the job queue to help you categorize and organize your resources. Each tag consists of a key and an optional value. For more information, see Tagging your Batch resources (https://docs.aws.amazon.com/batch/latest/userguide/using-tags.html) in Batch User Guide.
]: any -> record<jobQueueName: record, jobQueueArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/createjobqueue" $auth.query)
  let req_body = {"jobQueueName": $job_queue_name, "state": $state, "schedulingPolicyArn": $scheduling_policy_arn, "priority": $priority, "computeEnvironmentOrder": $compute_environment_order, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates an Batch scheduling policy.
#
# POST /v1/createschedulingpolicy
# operationId: CreateSchedulingPolicy
# --fairsharePolicy shape: {shareDecaySeconds?: any, computeReservation?: any, shareDistribution?: any}
export def "create-schedulingpolicy create-scheduling-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name of the scheduling policy. It can be up to 128 letters long. It can contain uppercase and lowercase letters, numbers, hyphens (-), and underscores (_).
  --fairshare-policy: record # The fair share policy for a scheduling policy. — shape: {shareDecaySeconds?: any, computeReservation?: any, shareDistribution?: any}
  --tags: record # The tags that you apply to the scheduling policy to help you categorize and organize your resources. Each tag consists of a key and an optional value. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in Amazon Web Services General Reference. These tags can be updated or removed using the TagResource (https://docs.aws.amazon.com/batch/latest/APIReference/API_TagResource.html) and UntagResource (https://docs.aws.amazon.com/batch/latest/APIReference/API_UntagResource.html) API operations.
]: any -> record<name: record, arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/createschedulingpolicy" $auth.query)
  let req_body = {"name": $name, "fairsharePolicy": $fairshare_policy, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an Batch compute environment. Before you can delete a compute environment, you must set its state to DISABLED with the UpdateComputeEnvironment API operation and disassociate it from any job queues with the UpdateJobQueue API operation. Compute environments that use Fargate resources must terminate all active jobs on that compute environment before deleting the compute environment. If this isn't done, the compute environment enters an invalid state.
#
# POST /v1/deletecomputeenvironment
# operationId: DeleteComputeEnvironment
export def "delete-computeenvironment delete-compute-environment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  compute_environment: string # The name or Amazon Resource Name (ARN) of the compute environment to delete.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/deletecomputeenvironment" $auth.query)
  let req_body = {"computeEnvironment": $compute_environment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the specified job queue. You must first disable submissions for a queue with the UpdateJobQueue operation. All jobs in the queue are eventually terminated when you delete a job queue. The jobs are terminated at a rate of about 16 jobs each second. It's not necessary to disassociate compute environments from a queue before submitting a DeleteJobQueue request.
#
# POST /v1/deletejobqueue
# operationId: DeleteJobQueue
export def "delete-jobqueue delete-job-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  job_queue: string # The short name or full Amazon Resource Name (ARN) of the queue to delete.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/deletejobqueue" $auth.query)
  let req_body = {"jobQueue": $job_queue} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the specified scheduling policy. You can't delete a scheduling policy that's used in any job queues.
#
# POST /v1/deleteschedulingpolicy
# operationId: DeleteSchedulingPolicy
export def "delete-schedulingpolicy delete-scheduling-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  arn: string # The Amazon Resource Name (ARN) of the scheduling policy to delete.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/deleteschedulingpolicy" $auth.query)
  let req_body = {"arn": $arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deregisters an Batch job definition. Job definitions are permanently deleted after 180 days.
#
# POST /v1/deregisterjobdefinition
# operationId: DeregisterJobDefinition
export def "deregisterjobdefinition create-deregister-job-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  job_definition: string # The name and revision (name:revision) or full Amazon Resource Name (ARN) of the job definition to deregister.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/deregisterjobdefinition" $auth.query)
  let req_body = {"jobDefinition": $job_definition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes one or more of your compute environments. If you're using an unmanaged compute environment, you can use the DescribeComputeEnvironment operation to determine the ecsClusterArn that you launch your Amazon ECS container instances into.
#
# POST /v1/describecomputeenvironments
# operationId: DescribeComputeEnvironments
export def "describecomputeenvironments get-compute-environments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --compute-environments: list<string> # A list of up to 100 compute environment names or full Amazon Resource Name (ARN) entries.
  --max-results-body: int # The maximum number of cluster results returned by DescribeComputeEnvironments in paginated output. When this parameter is used, DescribeComputeEnvironments only returns maxResults results in a single page along with a nextToken response element. The remaining results of the initial request can be seen by sending another DescribeComputeEnvironments request with the returned nextToken value. This value can be between 1 and 100. If this parameter isn't used, then DescribeComputeEnvironments returns up to 100 results and a nextToken value if applicable. (body field)
  --next-token-body: string # The nextToken value returned from a previous paginated DescribeComputeEnvironments request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This value is null when there are no more results to return. Treat this token as an opaque identifier that's only used to retrieve the next items in a list and not for other programmatic purposes. (body field)
]: any -> record<computeEnvironments: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/describecomputeenvironments" $qp $auth.query)
  let req_body = {"computeEnvironments": $compute_environments, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes a list of job definitions. You can specify a status (such as ACTIVE) to only return job definitions that match that status.
#
# POST /v1/describejobdefinitions
# operationId: DescribeJobDefinitions
export def "describejobdefinitions get-job-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --job-definitions: list<string> # A list of up to 100 job definitions. Each entry in the list can either be an ARN in the format arn:aws:batch:${Region}:${Account}:job-definition/${JobDefinitionName}:${Revision} or a short version using the form ${JobDefinitionName}:${Revision}.
  --max-results-body: int # The maximum number of results returned by DescribeJobDefinitions in paginated output. When this parameter is used, DescribeJobDefinitions only returns maxResults results in a single page and a nextToken response element. The remaining results of the initial request can be seen by sending another DescribeJobDefinitions request with the returned nextToken value. This value can be between 1 and 100. If this parameter isn't used, then DescribeJobDefinitions returns up to 100 results and a nextToken value if applicable. (body field)
  --job-definition-name: string # The name of the job definition to describe.
  --status: string # The status used to filter job definitions.
  --next-token-body: string # The nextToken value returned from a previous paginated DescribeJobDefinitions request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This value is null when there are no more results to return. Treat this token as an opaque identifier that's only used to retrieve the next items in a list and not for other programmatic purposes. (body field)
]: any -> record<jobDefinitions: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/describejobdefinitions" $qp $auth.query)
  let req_body = {"jobDefinitions": $job_definitions, "maxResults": $max_results_body, "jobDefinitionName": $job_definition_name, "status": $status, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes one or more of your job queues.
#
# POST /v1/describejobqueues
# operationId: DescribeJobQueues
export def "describejobqueues get-job-queues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --job-queues: list<string> # A list of up to 100 queue names or full queue Amazon Resource Name (ARN) entries.
  --max-results-body: int # The maximum number of results returned by DescribeJobQueues in paginated output. When this parameter is used, DescribeJobQueues only returns maxResults results in a single page and a nextToken response element. The remaining results of the initial request can be seen by sending another DescribeJobQueues request with the returned nextToken value. This value can be between 1 and 100. If this parameter isn't used, then DescribeJobQueues returns up to 100 results and a nextToken value if applicable. (body field)
  --next-token-body: string # The nextToken value returned from a previous paginated DescribeJobQueues request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This value is null when there are no more results to return. Treat this token as an opaque identifier that's only used to retrieve the next items in a list and not for other programmatic purposes. (body field)
]: any -> record<jobQueues: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/describejobqueues" $qp $auth.query)
  let req_body = {"jobQueues": $job_queues, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes a list of Batch jobs.
#
# POST /v1/describejobs
# operationId: DescribeJobs
export def "describejobs get-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  jobs: list<string> # A list of up to 100 job IDs.
]: any -> record<jobs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/describejobs" $auth.query)
  let req_body = {"jobs": $jobs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes one or more of your scheduling policies.
#
# POST /v1/describeschedulingpolicies
# operationId: DescribeSchedulingPolicies
export def "describeschedulingpolicies get-scheduling-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  arns: list<string> # A list of up to 100 scheduling policy Amazon Resource Name (ARN) entries.
]: any -> record<schedulingPolicies: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/describeschedulingpolicies" $auth.query)
  let req_body = {"arns": $arns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of Batch jobs. You must specify only one of the following items: A job queue ID to return a list of jobs in that job queue A multi-node parallel job ID to return a list of nodes for that job An array job ID to return a list of the children for that job You can filter the results by job status with the jobStatus parameter. If you don't specify a status, only RUNNING jobs are returned.
#
# POST /v1/listjobs
# operationId: ListJobs
# --filters item shape: {name?: any, values?: any}
export def "listjobs list-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --job-queue: string # The name or full Amazon Resource Name (ARN) of the job queue used to list jobs.
  --array-job-id: string # The job ID for an array job. Specifying an array job ID with this parameter lists all child jobs from within the specified array.
  --multi-node-job-id: string # The job ID for a multi-node parallel job. Specifying a multi-node parallel job ID with this parameter lists all nodes that are associated with the specified job.
  --job-status: string@job-status-completer # The job status used to filter jobs in the specified queue. If the filters parameter is specified, the jobStatus parameter is ignored and jobs with any status are returned. If you don't specify a status, only RUNNING jobs are returned.
  --max-results-body: int # The maximum number of results returned by ListJobs in paginated output. When this parameter is used, ListJobs only returns maxResults results in a single page and a nextToken response element. The remaining results of the initial request can be seen by sending another ListJobs request with the returned nextToken value. This value can be between 1 and 100. If this parameter isn't used, then ListJobs returns up to 100 results and a nextToken value if applicable. (body field)
  --next-token-body: string # The nextToken value returned from a previous paginated ListJobs request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This value is null when there are no more results to return. Treat this token as an opaque identifier that's only used to retrieve the next items in a list and not for other programmatic purposes. (body field)
  --filters: list # The filter to apply to the query. Only one filter can be used at a time. When the filter is used, jobStatus is ignored. The filter doesn't apply to child jobs in an array or multi-node parallel (MNP) jobs. The results are sorted by the createdAt field, with the most recent jobs being first. JOB_NAME The value of the filter is a case-insensitive match for the job name. If the value ends with an asterisk (*), the filter matches any job name that begins with the string before the '*'. This corresponds to the jobName value. For example, test1 matches both Test1 and test1, and test1* matches both test1 and Test10. When the JOB_NAME filter is used, the results are grouped by the job name and version. JOB_DEFINITION The value for the filter is the name or Amazon Resource Name (ARN) of the job definition. This corresponds to the jobDefinition value. The value is case sensitive. When the value for the filter is the job definition name, the results include all the jobs that used any revision of that job definition name. If the value ends with an asterisk (*), the filter matches any job definition name that begins with the string before the '*'. For example, jd1 matches only jd1, and jd1* matches both jd1 and jd1A. The version of the job definition that's used doesn't affect the sort order. When the JOB_DEFINITION filter is used and the ARN is used (which is in the form arn:${Partition}:batch:${Region}:${Account}:job-definition/${JobDefinitionName}:${Revision}), the results include jobs that used the specified revision of the job definition. Asterisk (*) isn't supported when the ARN is used. BEFORE_CREATED_AT The value for the filter is the time that's before the job was created. This corresponds to the createdAt value. The value is a string representation of the number of milliseconds since 00:00:00 UTC (midnight) on January 1, 1970. AFTER_CREATED_AT The value for the filter is the time that's after the job was created. This corresponds to the createdAt value. The value is a string representation of the number of milliseconds since 00:00:00 UTC (midnight) on January 1, 1970. — item shape: {name?: any, values?: any}
]: any -> record<jobSummaryList: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/listjobs" $qp $auth.query)
  let req_body = {"jobQueue": $job_queue, "arrayJobId": $array_job_id, "multiNodeJobId": $multi_node_job_id, "jobStatus": $job_status, "maxResults": $max_results_body, "nextToken": $next_token_body, "filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of Batch scheduling policies.
#
# POST /v1/listschedulingpolicies
# operationId: ListSchedulingPolicies
export def "list-schedulingpolicies list-scheduling-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --max-results-body: int # The maximum number of results that's returned by ListSchedulingPolicies in paginated output. When this parameter is used, ListSchedulingPolicies only returns maxResults results in a single page and a nextToken response element. You can see the remaining results of the initial request by sending another ListSchedulingPolicies request with the returned nextToken value. This value can be between 1 and 100. If this parameter isn't used, ListSchedulingPolicies returns up to 100 results and a nextToken value if applicable. (body field)
  --next-token-body: string # The nextToken value that's returned from a previous paginated ListSchedulingPolicies request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This value is null when there are no more results to return. Treat this token as an opaque identifier that's only used to retrieve the next items in a list and not for other programmatic purposes. (body field)
]: any -> record<schedulingPolicies: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/listschedulingpolicies" $qp $auth.query)
  let req_body = {"maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the tags for an Batch resource. Batch resources that support tags are compute environments, jobs, job definitions, job queues, and scheduling policies. ARNs for child jobs of array and multi-node parallel (MNP) jobs aren't supported.
#
# GET /v1/tags/{resourceArn}
# operationId: ListTagsForResource
export def "tags list-for-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource aren't specified in the request parameters, they aren't changed. When a resource is deleted, the tags that are associated with that resource are deleted as well. Batch resources that support tags are compute environments, jobs, job definitions, job queues, and scheduling policies. ARNs for child jobs of array and multi-node parallel (MNP) jobs aren't supported.
#
# POST /v1/tags/{resourceArn}
# operationId: TagResource
export def "tags tag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: record # The tags that you apply to the resource to help you categorize and organize your resources. Each tag consists of a key and an optional value. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in Amazon Web Services General Reference.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}") $auth.query)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Registers an Batch job definition.
#
# POST /v1/registerjobdefinition
# operationId: RegisterJobDefinition
# --containerProperties shape: {image?: any, vcpus?: any, memory?: any, command?: any, jobRoleArn?: any, executionRoleArn?: any, volumes?: any, environment?: any, mountPoints?: any, readonlyRootFilesystem?: any, privileged?: any, ulimits?: any, user?: any, instanceType?: any, resourceRequirements?: any, linuxParameters?: any, logConfiguration?: any, secrets?: any, networkConfiguration?: any, fargatePlatformConfiguration?: any, ephemeralStorage?: any}
# --nodeProperties shape: {numNodes?: any, mainNode?: any, nodeRangeProperties?: any}
# --retryStrategy shape: {attempts?: any, evaluateOnExit?: any}
# --timeout shape: {attemptDurationSeconds?: any}
# --eksProperties shape: {podProperties?: any}
export def "registerjobdefinition create-job-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  job_definition_name: string # The name of the job definition to register. It can be up to 128 letters long. It can contain uppercase and lowercase letters, numbers, hyphens (-), and underscores (_).
  type: string@type-completer-1 # The type of job definition. For more information about multi-node parallel jobs, see Creating a multi-node parallel job definition (https://docs.aws.amazon.com/batch/latest/userguide/multi-node-job-def.html) in the Batch User Guide. If the job is run on Fargate resources, then multinode isn't supported.
  --parameters: record # Default parameter substitution placeholders to set in the job definition. Parameters are specified as a key-value pair mapping. Parameters in a SubmitJob request override any corresponding parameter defaults from the job definition.
  --scheduling-priority: int # The scheduling priority for jobs that are submitted with this job definition. This only affects jobs in job queues with a fair share policy. Jobs with a higher scheduling priority are scheduled before jobs with a lower scheduling priority. The minimum supported value is 0 and the maximum supported value is 9999.
  --container-properties: record # Container properties are used for Amazon ECS based job definitions. These properties to describe the container that's launched as part of a job. — shape: {image?: any, vcpus?: any, memory?: any, command?: any, jobRoleArn?: any, executionRoleArn?: any, volumes?: any, environment?: any, mountPoints?: any, readonlyRootFilesystem?: any, privileged?: any, ulimits?: any, user?: any, instanceType?: any, resourceRequirements?: any, linuxParameters?: any, logConfiguration?: any, secrets?: any, networkConfiguration?: any, fargatePlatformConfiguration?: any, ephemeralStorage?: any}
  --node-properties: record # An object that represents the node properties of a multi-node parallel job. Node properties can't be specified for Amazon EKS based job definitions. — shape: {numNodes?: any, mainNode?: any, nodeRangeProperties?: any}
  --retry-strategy: record # The retry strategy that's associated with a job. For more information, see Automated job retries (https://docs.aws.amazon.com/batch/latest/userguide/job_retries.html) in the Batch User Guide. — shape: {attempts?: any, evaluateOnExit?: any}
  --propagate-tags: oneof<nothing, bool> # Specifies whether to propagate the tags from the job or job definition to the corresponding Amazon ECS task. If no value is specified, the tags are not propagated. Tags can only be propagated to the tasks during task creation. For tags with the same name, job tags are given priority over job definitions tags. If the total number of combined tags from the job and job definition is over 50, the job is moved to the FAILED state. If the job runs on Amazon EKS resources, then you must not specify propagateTags.
  --timeout: record # An object that represents a job timeout configuration. — shape: {attemptDurationSeconds?: any}
  --tags: record # The tags that you apply to the job definition to help you categorize and organize your resources. Each tag consists of a key and an optional value. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/batch/latest/userguide/using-tags.html) in Batch User Guide.
  --platform-capabilities: list<string> # The platform capabilities required by the job definition. If no value is specified, it defaults to EC2. To run the job on Fargate resources, specify FARGATE. If the job runs on Amazon EKS resources, then you must not specify platformCapabilities.
  --eks-properties: record # An object that contains the properties for the Kubernetes resources of a job. — shape: {podProperties?: any}
]: any -> record<jobDefinitionName: record, jobDefinitionArn: record, revision: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/registerjobdefinition" $auth.query)
  let req_body = {"jobDefinitionName": $job_definition_name, "type": $type, "parameters": $parameters, "schedulingPriority": $scheduling_priority, "containerProperties": $container_properties, "nodeProperties": $node_properties, "retryStrategy": $retry_strategy, "propagateTags": $propagate_tags, "timeout": $timeout, "tags": $tags, "platformCapabilities": $platform_capabilities, "eksProperties": $eks_properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Submits an Batch job from a job definition. Parameters that are specified during SubmitJob override parameters defined in the job definition. vCPU and memory requirements that are specified in the resourceRequirements objects in the job definition are the exception. They can't be overridden this way using the memory and vcpus parameters. Rather, you must specify updates to job definition parameters in a resourceRequirements object that's included in the containerOverrides parameter. Job queues with a scheduling policy are limited to 500 active fair share identifiers at a time. Jobs that run on Fargate resources can't be guaranteed to run for more than 14 days. This is because, after 14 days, Fargate resources might become unavailable and job might be terminated.
#
# POST /v1/submitjob
# operationId: SubmitJob
# --arrayProperties shape: {size?: any}
# --dependsOn item shape: {jobId?: any, type?: any}
# --containerOverrides shape: {vcpus?: any, memory?: any, command?: any, instanceType?: any, environment?: any, resourceRequirements?: any}
# --nodeOverrides shape: {numNodes?: any, nodePropertyOverrides?: any}
# --retryStrategy shape: {attempts?: any, evaluateOnExit?: any}
# --timeout shape: {attemptDurationSeconds?: any}
# --eksPropertiesOverride shape: {podProperties?: any}
export def "submitjob submit-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  job_name: string # The name of the job. It can be up to 128 letters long. The first character must be alphanumeric, can contain uppercase and lowercase letters, numbers, hyphens (-), and underscores (_).
  job_queue: string # The job queue where the job is submitted. You can specify either the name or the Amazon Resource Name (ARN) of the queue.
  --share-identifier: string # The share identifier for the job. If the job queue doesn't have a scheduling policy, then this parameter must not be specified. If the job queue has a scheduling policy, then this parameter must be specified.
  --scheduling-priority-override: int # The scheduling priority for the job. This only affects jobs in job queues with a fair share policy. Jobs with a higher scheduling priority are scheduled before jobs with a lower scheduling priority. This overrides any scheduling priority in the job definition. The minimum supported value is 0 and the maximum supported value is 9999.
  --array-properties: record # An object that represents an Batch array job. — shape: {size?: any}
  --depends-on: list # A list of dependencies for the job. A job can depend upon a maximum of 20 jobs. You can specify a SEQUENTIAL type dependency without specifying a job ID for array jobs so that each child array job completes sequentially, starting at index 0. You can also specify an N_TO_N type dependency with a job ID for array jobs. In that case, each index child of this job must wait for the corresponding index child of each dependency to complete before it can begin. — item shape: {jobId?: any, type?: any}
  job_definition: string # The job definition used by this job. This value can be one of definition-name, definition-name:revision, or the Amazon Resource Name (ARN) for the job definition, with or without the revision (arn:aws:batch:region:account:job-definition/definition-name:revision , or arn:aws:batch:region:account:job-definition/definition-name ). If the revision is not specified, then the latest active revision is used.
  --parameters: record # Additional parameters passed to the job that replace parameter substitution placeholders that are set in the job definition. Parameters are specified as a key and value pair mapping. Parameters in a SubmitJob request override any corresponding parameter defaults from the job definition.
  --container-overrides: record # The overrides that should be sent to a container. — shape: {vcpus?: any, memory?: any, command?: any, instanceType?: any, environment?: any, resourceRequirements?: any}
  --node-overrides: record # An object that represents any node overrides to a job definition that's used in a SubmitJob API operation. This parameter isn't applicable to jobs that are running on Fargate resources. Don't provide it for these jobs. Rather, use containerOverrides instead. — shape: {numNodes?: any, nodePropertyOverrides?: any}
  --retry-strategy: record # The retry strategy that's associated with a job. For more information, see Automated job retries (https://docs.aws.amazon.com/batch/latest/userguide/job_retries.html) in the Batch User Guide. — shape: {attempts?: any, evaluateOnExit?: any}
  --propagate-tags: oneof<nothing, bool> # Specifies whether to propagate the tags from the job or job definition to the corresponding Amazon ECS task. If no value is specified, the tags aren't propagated. Tags can only be propagated to the tasks during task creation. For tags with the same name, job tags are given priority over job definitions tags. If the total number of combined tags from the job and job definition is over 50, the job is moved to the FAILED state. When specified, this overrides the tag propagation setting in the job definition.
  --timeout: record # An object that represents a job timeout configuration. — shape: {attemptDurationSeconds?: any}
  --tags: record # The tags that you apply to the job request to help you categorize and organize your resources. Each tag consists of a key and an optional value. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in Amazon Web Services General Reference.
  --eks-properties-override: record # An object that contains overrides for the Kubernetes resources of a job. — shape: {podProperties?: any}
]: any -> record<jobArn: record, jobName: record, jobId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/submitjob" $auth.query)
  let req_body = {"jobName": $job_name, "jobQueue": $job_queue, "shareIdentifier": $share_identifier, "schedulingPriorityOverride": $scheduling_priority_override, "arrayProperties": $array_properties, "dependsOn": $depends_on, "jobDefinition": $job_definition, "parameters": $parameters, "containerOverrides": $container_overrides, "nodeOverrides": $node_overrides, "retryStrategy": $retry_strategy, "propagateTags": $propagate_tags, "timeout": $timeout, "tags": $tags, "eksPropertiesOverride": $eks_properties_override} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Terminates a job in a job queue. Jobs that are in the STARTING or RUNNING state are terminated, which causes them to transition to FAILED. Jobs that have not progressed to the STARTING state are cancelled.
#
# POST /v1/terminatejob
# operationId: TerminateJob
export def "terminatejob create-terminate-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  job_id: string # The Batch job ID of the job to terminate.
  reason: string # A message to attach to the job that explains the reason for canceling it. This message is returned by future DescribeJobs operations on the job. This message is also recorded in the Batch activity logs.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/terminatejob" $auth.query)
  let req_body = {"jobId": $job_id, "reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes specified tags from an Batch resource.
#
# DELETE /v1/tags/{resourceArn}
# operationId: UntagResource
export def "tags untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # The keys of the tags to be removed.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"tagKeys": $tag_keys} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Updates an Batch compute environment.
#
# POST /v1/updatecomputeenvironment
# operationId: UpdateComputeEnvironment
# --computeResources shape: {minvCpus?: any, maxvCpus?: any, desiredvCpus?: any, subnets?: any, securityGroupIds?: any, allocationStrategy?: any, instanceTypes?: any, ec2KeyPair?: any, instanceRole?: any, tags?: any, placementGroup?: any, bidPercentage?: any, launchTemplate?: any, ec2Configuration?: any, updateToLatestImageVersion?: any, type?: any, imageId?: any}
# --updatePolicy shape: {terminateJobsOnUpdate?: any, jobExecutionTimeoutMinutes?: any}
export def "update-computeenvironment update-compute-environment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  compute_environment: string # The name or full Amazon Resource Name (ARN) of the compute environment to update.
  --state: string@state-completer # The state of the compute environment. Compute environments in the ENABLED state can accept jobs from a queue and scale in or out automatically based on the workload demand of its associated queues. If the state is ENABLED, then the Batch scheduler can attempt to place jobs from an associated job queue on the compute resources within the environment. If the compute environment is managed, then it can scale its instances out or in automatically, based on the job queue demand. If the state is DISABLED, then the Batch scheduler doesn't attempt to place jobs within the environment. Jobs in a STARTING or RUNNING state continue to progress normally. Managed compute environments in the DISABLED state don't scale out. Compute environments in a DISABLED state may continue to incur billing charges. To prevent additional charges, turn off and then delete the compute environment. For more information, see State (https://docs.aws.amazon.com/batch/latest/userguide/compute_environment_parameters.html#compute_environment_state) in the Batch User Guide. When an instance is idle, the instance scales down to the minvCpus value. However, the instance size doesn't change. For example, consider a c5.8xlarge instance with a minvCpus value of 4 and a desiredvCpus value of 36. This instance doesn't scale down to a c5.large instance.
  --unmanagedv-cpus: int # The maximum number of vCPUs expected to be used for an unmanaged compute environment. Don't specify this parameter for a managed compute environment. This parameter is only used for fair share scheduling to reserve vCPU capacity for new share identifiers. If this parameter isn't provided for a fair share job queue, no vCPU capacity is reserved.
  --compute-resources: record # An object that represents the attributes of a compute environment that can be updated. For more information, see Updating compute environments (https://docs.aws.amazon.com/batch/latest/userguide/updating-compute-environments.html) in the Batch User Guide. — shape: {minvCpus?: any, maxvCpus?: any, desiredvCpus?: any, subnets?: any, securityGroupIds?: any, allocationStrategy?: any, instanceTypes?: any, ec2KeyPair?: any, instanceRole?: any, tags?: any, placementGroup?: any, bidPercentage?: any, launchTemplate?: any, ec2Configuration?: any, updateToLatestImageVersion?: any, type?: any, imageId?: any}
  --service-role: string # The full Amazon Resource Name (ARN) of the IAM role that allows Batch to make calls to other Amazon Web Services services on your behalf. For more information, see Batch service IAM role (https://docs.aws.amazon.com/batch/latest/userguide/service_IAM_role.html) in the Batch User Guide. If the compute environment has a service-linked role, it can't be changed to use a regular IAM role. Likewise, if the compute environment has a regular IAM role, it can't be changed to use a service-linked role. To update the parameters for the compute environment that require an infrastructure update to change, the AWSServiceRoleForBatch service-linked role must be used. For more information, see Updating compute environments (https://docs.aws.amazon.com/batch/latest/userguide/updating-compute-environments.html) in the Batch User Guide. If your specified role has a path other than /, then you must either specify the full role ARN (recommended) or prefix the role name with the path. Depending on how you created your Batch service role, its ARN might contain the service-role path prefix. When you only specify the name of the service role, Batch assumes that your ARN doesn't use the service-role path prefix. Because of this, we recommend that you specify the full ARN of your service role when you create compute environments.
  --update-policy: record # Specifies the infrastructure update policy for the compute environment. For more information about infrastructure updates, see Updating compute environments (https://docs.aws.amazon.com/batch/latest/userguide/updating-compute-environments.html) in the Batch User Guide. — shape: {terminateJobsOnUpdate?: any, jobExecutionTimeoutMinutes?: any}
]: any -> record<computeEnvironmentName: record, computeEnvironmentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/updatecomputeenvironment" $auth.query)
  let req_body = {"computeEnvironment": $compute_environment, "state": $state, "unmanagedvCpus": $unmanagedv_cpus, "computeResources": $compute_resources, "serviceRole": $service_role, "updatePolicy": $update_policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates a job queue.
#
# POST /v1/updatejobqueue
# operationId: UpdateJobQueue
# --computeEnvironmentOrder item shape: {order: any, computeEnvironment: any}
export def "update-jobqueue update-job-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  job_queue: string # The name or the Amazon Resource Name (ARN) of the job queue.
  --state: string@state-completer # Describes the queue's ability to accept new jobs. If the job queue state is ENABLED, it can accept jobs. If the job queue state is DISABLED, new jobs can't be added to the queue, but jobs already in the queue can finish.
  --scheduling-policy-arn: string # Amazon Resource Name (ARN) of the fair share scheduling policy. Once a job queue is created, the fair share scheduling policy can be replaced but not removed. The format is aws:Partition:batch:Region:Account:scheduling-policy/Name . For example, aws:aws:batch:us-west-2:123456789012:scheduling-policy/MySchedulingPolicy.
  --priority: int # The priority of the job queue. Job queues with a higher priority (or a higher integer value for the priority parameter) are evaluated first when associated with the same compute environment. Priority is determined in descending order. For example, a job queue with a priority value of 10 is given scheduling preference over a job queue with a priority value of 1. All of the compute environments must be either EC2 (EC2 or SPOT) or Fargate (FARGATE or FARGATE_SPOT). EC2 and Fargate compute environments can't be mixed.
  --compute-environment-order: list # Details the set of compute environments mapped to a job queue and their order relative to each other. This is one of the parameters used by the job scheduler to determine which compute environment runs a given job. Compute environments must be in the VALID state before you can associate them with a job queue. All of the compute environments must be either EC2 (EC2 or SPOT) or Fargate (FARGATE or FARGATE_SPOT). EC2 and Fargate compute environments can't be mixed. All compute environments that are associated with a job queue must share the same architecture. Batch doesn't support mixing compute environment architecture types in a single job queue. — item shape: {order: any, computeEnvironment: any}
]: any -> record<jobQueueName: record, jobQueueArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/updatejobqueue" $auth.query)
  let req_body = {"jobQueue": $job_queue, "state": $state, "schedulingPolicyArn": $scheduling_policy_arn, "priority": $priority, "computeEnvironmentOrder": $compute_environment_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates a scheduling policy.
#
# POST /v1/updateschedulingpolicy
# operationId: UpdateSchedulingPolicy
# --fairsharePolicy shape: {shareDecaySeconds?: any, computeReservation?: any, shareDistribution?: any}
export def "update-schedulingpolicy update-scheduling-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  arn: string # The Amazon Resource Name (ARN) of the scheduling policy to update.
  --fairshare-policy: record # The fair share policy for a scheduling policy. — shape: {shareDecaySeconds?: any, computeReservation?: any, shareDistribution?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/updateschedulingpolicy" $auth.query)
  let req_body = {"arn": $arn, "fairsharePolicy": $fairshare_policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
