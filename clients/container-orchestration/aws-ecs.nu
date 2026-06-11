# Auto-generated client for Amazon EC2 Container Service v2014-11-13
# Source: https://api.apis.guru/v2/specs/amazonaws.com/ecs/2014-11-13/openapi.json
# Auth: --token flag or $env.AMAZON_EC2_CONTAINER_SERVICE_TOKEN

const BASE_URL = "http://ecs.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_EC2_CONTAINER_SERVICE_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["http://ecs.us-east-1.amazonaws.com" "http://ecs.us-east-2.amazonaws.com" "http://ecs.us-west-1.amazonaws.com" "http://ecs.us-west-2.amazonaws.com" "http://ecs.us-gov-west-1.amazonaws.com" "http://ecs.us-gov-east-1.amazonaws.com" "http://ecs.ca-central-1.amazonaws.com" "http://ecs.eu-north-1.amazonaws.com" "http://ecs.eu-west-1.amazonaws.com" "http://ecs.eu-west-2.amazonaws.com" "http://ecs.eu-west-3.amazonaws.com" "http://ecs.eu-central-1.amazonaws.com" "http://ecs.eu-south-1.amazonaws.com" "http://ecs.af-south-1.amazonaws.com" "http://ecs.ap-northeast-1.amazonaws.com" "http://ecs.ap-northeast-2.amazonaws.com" "http://ecs.ap-northeast-3.amazonaws.com" "http://ecs.ap-southeast-1.amazonaws.com" "http://ecs.ap-southeast-2.amazonaws.com" "http://ecs.ap-east-1.amazonaws.com" "http://ecs.ap-south-1.amazonaws.com" "http://ecs.sa-east-1.amazonaws.com" "http://ecs.me-south-1.amazonaws.com" "https://ecs.us-east-1.amazonaws.com" "https://ecs.us-east-2.amazonaws.com" "https://ecs.us-west-1.amazonaws.com" "https://ecs.us-west-2.amazonaws.com" "https://ecs.us-gov-west-1.amazonaws.com" "https://ecs.us-gov-east-1.amazonaws.com" "https://ecs.ca-central-1.amazonaws.com" "https://ecs.eu-north-1.amazonaws.com" "https://ecs.eu-west-1.amazonaws.com" "https://ecs.eu-west-2.amazonaws.com" "https://ecs.eu-west-3.amazonaws.com" "https://ecs.eu-central-1.amazonaws.com" "https://ecs.eu-south-1.amazonaws.com" "https://ecs.af-south-1.amazonaws.com" "https://ecs.ap-northeast-1.amazonaws.com" "https://ecs.ap-northeast-2.amazonaws.com" "https://ecs.ap-northeast-3.amazonaws.com" "https://ecs.ap-southeast-1.amazonaws.com" "https://ecs.ap-southeast-2.amazonaws.com" "https://ecs.ap-east-1.amazonaws.com" "https://ecs.ap-south-1.amazonaws.com" "https://ecs.sa-east-1.amazonaws.com" "https://ecs.me-south-1.amazonaws.com" "http://ecs.cn-north-1.amazonaws.com.cn" "http://ecs.cn-northwest-1.amazonaws.com.cn" "https://ecs.cn-north-1.amazonaws.com.cn" "https://ecs.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def X-Amz-Target-completer [] { ["AmazonEC2ContainerServiceV20141113.CreateCapacityProvider"] }
def X-Amz-Target-completer-1 [] { ["AmazonEC2ContainerServiceV20141113.CreateCluster"] }
def X-Amz-Target-completer-2 [] { ["AmazonEC2ContainerServiceV20141113.CreateService"] }
def X-Amz-Target-completer-3 [] { ["AmazonEC2ContainerServiceV20141113.CreateTaskSet"] }
def X-Amz-Target-completer-4 [] { ["AmazonEC2ContainerServiceV20141113.DeleteAccountSetting"] }
def X-Amz-Target-completer-5 [] { ["AmazonEC2ContainerServiceV20141113.DeleteAttributes"] }
def X-Amz-Target-completer-6 [] { ["AmazonEC2ContainerServiceV20141113.DeleteCapacityProvider"] }
def X-Amz-Target-completer-7 [] { ["AmazonEC2ContainerServiceV20141113.DeleteCluster"] }
def X-Amz-Target-completer-8 [] { ["AmazonEC2ContainerServiceV20141113.DeleteService"] }
def X-Amz-Target-completer-9 [] { ["AmazonEC2ContainerServiceV20141113.DeleteTaskDefinitions"] }
def X-Amz-Target-completer-10 [] { ["AmazonEC2ContainerServiceV20141113.DeleteTaskSet"] }
def X-Amz-Target-completer-11 [] { ["AmazonEC2ContainerServiceV20141113.DeregisterContainerInstance"] }
def X-Amz-Target-completer-12 [] { ["AmazonEC2ContainerServiceV20141113.DeregisterTaskDefinition"] }
def X-Amz-Target-completer-13 [] { ["AmazonEC2ContainerServiceV20141113.DescribeCapacityProviders"] }
def X-Amz-Target-completer-14 [] { ["AmazonEC2ContainerServiceV20141113.DescribeClusters"] }
def X-Amz-Target-completer-15 [] { ["AmazonEC2ContainerServiceV20141113.DescribeContainerInstances"] }
def X-Amz-Target-completer-16 [] { ["AmazonEC2ContainerServiceV20141113.DescribeServices"] }
def X-Amz-Target-completer-17 [] { ["AmazonEC2ContainerServiceV20141113.DescribeTaskDefinition"] }
def X-Amz-Target-completer-18 [] { ["AmazonEC2ContainerServiceV20141113.DescribeTaskSets"] }
def X-Amz-Target-completer-19 [] { ["AmazonEC2ContainerServiceV20141113.DescribeTasks"] }
def X-Amz-Target-completer-20 [] { ["AmazonEC2ContainerServiceV20141113.DiscoverPollEndpoint"] }
def X-Amz-Target-completer-21 [] { ["AmazonEC2ContainerServiceV20141113.ExecuteCommand"] }
def X-Amz-Target-completer-22 [] { ["AmazonEC2ContainerServiceV20141113.GetTaskProtection"] }
def X-Amz-Target-completer-23 [] { ["AmazonEC2ContainerServiceV20141113.ListAccountSettings"] }
def X-Amz-Target-completer-24 [] { ["AmazonEC2ContainerServiceV20141113.ListAttributes"] }
def X-Amz-Target-completer-25 [] { ["AmazonEC2ContainerServiceV20141113.ListClusters"] }
def X-Amz-Target-completer-26 [] { ["AmazonEC2ContainerServiceV20141113.ListContainerInstances"] }
def X-Amz-Target-completer-27 [] { ["AmazonEC2ContainerServiceV20141113.ListServices"] }
def X-Amz-Target-completer-28 [] { ["AmazonEC2ContainerServiceV20141113.ListServicesByNamespace"] }
def X-Amz-Target-completer-29 [] { ["AmazonEC2ContainerServiceV20141113.ListTagsForResource"] }
def X-Amz-Target-completer-30 [] { ["AmazonEC2ContainerServiceV20141113.ListTaskDefinitionFamilies"] }
def X-Amz-Target-completer-31 [] { ["AmazonEC2ContainerServiceV20141113.ListTaskDefinitions"] }
def X-Amz-Target-completer-32 [] { ["AmazonEC2ContainerServiceV20141113.ListTasks"] }
def X-Amz-Target-completer-33 [] { ["AmazonEC2ContainerServiceV20141113.PutAccountSetting"] }
def X-Amz-Target-completer-34 [] { ["AmazonEC2ContainerServiceV20141113.PutAccountSettingDefault"] }
def X-Amz-Target-completer-35 [] { ["AmazonEC2ContainerServiceV20141113.PutAttributes"] }
def X-Amz-Target-completer-36 [] { ["AmazonEC2ContainerServiceV20141113.PutClusterCapacityProviders"] }
def X-Amz-Target-completer-37 [] { ["AmazonEC2ContainerServiceV20141113.RegisterContainerInstance"] }
def X-Amz-Target-completer-38 [] { ["AmazonEC2ContainerServiceV20141113.RegisterTaskDefinition"] }
def X-Amz-Target-completer-39 [] { ["AmazonEC2ContainerServiceV20141113.RunTask"] }
def X-Amz-Target-completer-40 [] { ["AmazonEC2ContainerServiceV20141113.StartTask"] }
def X-Amz-Target-completer-41 [] { ["AmazonEC2ContainerServiceV20141113.StopTask"] }
def X-Amz-Target-completer-42 [] { ["AmazonEC2ContainerServiceV20141113.SubmitAttachmentStateChanges"] }
def X-Amz-Target-completer-43 [] { ["AmazonEC2ContainerServiceV20141113.SubmitContainerStateChange"] }
def X-Amz-Target-completer-44 [] { ["AmazonEC2ContainerServiceV20141113.SubmitTaskStateChange"] }
def X-Amz-Target-completer-45 [] { ["AmazonEC2ContainerServiceV20141113.TagResource"] }
def X-Amz-Target-completer-46 [] { ["AmazonEC2ContainerServiceV20141113.UntagResource"] }
def X-Amz-Target-completer-47 [] { ["AmazonEC2ContainerServiceV20141113.UpdateCapacityProvider"] }
def X-Amz-Target-completer-48 [] { ["AmazonEC2ContainerServiceV20141113.UpdateCluster"] }
def X-Amz-Target-completer-49 [] { ["AmazonEC2ContainerServiceV20141113.UpdateClusterSettings"] }
def X-Amz-Target-completer-50 [] { ["AmazonEC2ContainerServiceV20141113.UpdateContainerAgent"] }
def X-Amz-Target-completer-51 [] { ["AmazonEC2ContainerServiceV20141113.UpdateContainerInstancesState"] }
def X-Amz-Target-completer-52 [] { ["AmazonEC2ContainerServiceV20141113.UpdateService"] }
def X-Amz-Target-completer-53 [] { ["AmazonEC2ContainerServiceV20141113.UpdateServicePrimaryTaskSet"] }
def X-Amz-Target-completer-54 [] { ["AmazonEC2ContainerServiceV20141113.UpdateTaskProtection"] }
def X-Amz-Target-completer-55 [] { ["AmazonEC2ContainerServiceV20141113.UpdateTaskSet"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-amazon-ec2-container-service-v20141113-create-capacity-provider CreateCapacityProvider" } } | get name | first)
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

# <p>Creates a new capacity provider. Capacity providers are associated with an Amazon ECS cluster and are used in capacity provider strategies to facilitate cluster auto scaling.</p> <p>Only capacity providers that use an Auto Scaling group can be created. Amazon ECS tasks on Fargate use the <code>FARGATE</code> and <code>FARGATE_SPOT</code> capacity providers. These providers are available to all accounts in the Amazon Web Services Regions that Fargate supports.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateCapacityProvider
# operationId: CreateCapacityProvider
export def "x-amz-target-amazon-ec2-container-service-v20141113-create-capacity-provider CreateCapacityProvider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer
  name: any
  autoScalingGroupProvider: any
  --tags: any
]: any -> record<capacityProvider: record<capacityProviderArn: record, name: record, status: record, autoScalingGroupProvider: record<autoScalingGroupArn: record, managedScaling: record, managedTerminationProtection: record>, updateStatus: record, updateStatusReason: record, tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateCapacityProvider")
  let body = {name: $name, autoScalingGroupProvider: $autoScalingGroupProvider, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Creates a new Amazon ECS cluster. By default, your account receives a <code>default</code> cluster when you launch your first container instance. However, you can create your own cluster with a unique name with the <code>CreateCluster</code> action.</p> <note> <p>When you call the <a>CreateCluster</a> API operation, Amazon ECS attempts to create the Amazon ECS service-linked role for your account. This is so that it can manage required resources in other Amazon Web Services services on your behalf. However, if the user that makes the call doesn't have permissions to create the service-linked role, it isn't created. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html">Using service-linked roles for Amazon ECS</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateCluster
# operationId: CreateCluster
export def "x-amz-target-amazon-ec2-container-service-v20141113-create-cluster CreateCluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-1
  --clusterName: any
  --tags: any
  --settings: any
  --configuration: any
  --capacityProviders: any
  --defaultCapacityProviderStrategy: any
  --serviceConnectDefaults: any
]: any -> record<cluster: record<clusterArn: record, clusterName: record, configuration: record<executeCommandConfiguration: record>, status: record, registeredContainerInstancesCount: record, runningTasksCount: record, pendingTasksCount: record, activeServicesCount: record, statistics: record, tags: record, settings: record, capacityProviders: record, defaultCapacityProviderStrategy: record, attachments: record, attachmentsStatus: record, serviceConnectDefaults: record<namespace: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateCluster")
  let body = {clusterName: $clusterName, tags: $tags, settings: $settings, configuration: $configuration, capacityProviders: $capacityProviders, defaultCapacityProviderStrategy: $defaultCapacityProviderStrategy, serviceConnectDefaults: $serviceConnectDefaults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Runs and maintains your desired number of tasks from a specified task definition. If the number of tasks running in a service drops below the <code>desiredCount</code>, Amazon ECS runs another copy of the task in the specified cluster. To update an existing service, see the <a>UpdateService</a> action.</p> <note> <p>Starting April 15, 2023, Amazon Web Services will not onboard new customers to Amazon Elastic Inference (EI), and will help current customers migrate their workloads to options that offer better price and performance. After April 15, 2023, new customers will not be able to launch instances with Amazon EI accelerators in Amazon SageMaker, Amazon ECS, or Amazon EC2. However, customers who have used Amazon EI at least once during the past 30-day period are considered current customers and will be able to continue using the service. </p> </note> <p>In addition to maintaining the desired count of tasks in your service, you can optionally run your service behind one or more load balancers. The load balancers distribute traffic across the tasks that are associated with the service. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html">Service load balancing</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Tasks for services that don't use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and are reported as healthy by the load balancer.</p> <p>There are two service scheduler strategies available:</p> <ul> <li> <p> <code>REPLICA</code> - The replica scheduling strategy places and maintains your desired number of tasks across your cluster. By default, the service scheduler spreads tasks across Availability Zones. You can use task placement strategies and constraints to customize task placement decisions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service scheduler concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> <li> <p> <code>DAEMON</code> - The daemon scheduling strategy deploys exactly one task on each active container instance that meets all of the task placement constraints that you specify in your cluster. The service scheduler also evaluates the task placement constraints for running tasks. It also stops tasks that don't meet the placement constraints. When using this strategy, you don't need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service scheduler concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> </ul> <p>You can optionally specify a deployment configuration for your service. The deployment is initiated by changing properties. For example, the deployment might be initiated by the task definition or by your desired count of a service. This is done with an <a>UpdateService</a> operation. The default value for a replica service for <code>minimumHealthyPercent</code> is 100%. The default value for a daemon service for <code>minimumHealthyPercent</code> is 0%.</p> <p>If a service uses the <code>ECS</code> deployment controller, the minimum healthy percent represents a lower limit on the number of tasks in a service that must remain in the <code>RUNNING</code> state during a deployment. Specifically, it represents it as a percentage of your desired number of tasks (rounded up to the nearest integer). This happens when any of your container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. Using this parameter, you can deploy without using additional cluster capacity. For example, if you set your service to have desired number of four tasks and a minimum healthy percent of 50%, the scheduler might stop two existing tasks to free up cluster capacity before starting two new tasks. If they're in the <code>RUNNING</code> state, tasks for services that don't use a load balancer are considered healthy . If they're in the <code>RUNNING</code> state and reported as healthy by the load balancer, tasks for services that <i>do</i> use a load balancer are considered healthy . The default value for minimum healthy percent is 100%.</p> <p>If a service uses the <code>ECS</code> deployment controller, the <b>maximum percent</b> parameter represents an upper limit on the number of tasks in a service that are allowed in the <code>RUNNING</code> or <code>PENDING</code> state during a deployment. Specifically, it represents it as a percentage of the desired number of tasks (rounded down to the nearest integer). This happens when any of your container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. Using this parameter, you can define the deployment batch size. For example, if your service has a desired number of four tasks and a maximum percent value of 200%, the scheduler may start four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available). The default value for maximum percent is 200%.</p> <p>If a service uses either the <code>CODE_DEPLOY</code> or <code>EXTERNAL</code> deployment controller types and tasks that use the EC2 launch type, the <b>minimum healthy percent</b> and <b>maximum percent</b> values are used only to define the lower and upper limit on the number of the tasks in the service that remain in the <code>RUNNING</code> state. This is while the container instances are in the <code>DRAINING</code> state. If the tasks in the service use the Fargate launch type, the minimum healthy percent and maximum percent values aren't used. This is the case even if they're currently visible when describing your service.</p> <p>When creating a service that uses the <code>EXTERNAL</code> deployment controller, you can specify only parameters that aren't controlled at the task set level. The only required parameter is the service name. You control your services using the <a>CreateTaskSet</a> operation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS deployment types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When the service scheduler launches new tasks, it determines task placement. For information about task placement and task placement strategies, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement.html">Amazon ECS task placement</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateService
# operationId: CreateService
export def "x-amz-target-amazon-ec2-container-service-v20141113-create-service CreateService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-2
  --cluster: any
  serviceName: any
  --taskDefinition: any
  --loadBalancers: any
  --serviceRegistries: any
  --desiredCount: any
  --clientToken: any
  --launchType: any
  --capacityProviderStrategy: any
  --platformVersion: any
  --role: any
  --deploymentConfiguration: any
  --placementConstraints: any
  --placementStrategy: any
  --networkConfiguration: any
  --healthCheckGracePeriodSeconds: any
  --schedulingStrategy: any
  --deploymentController: any
  --tags: any
  --enableECSManagedTags: any
  --propagateTags: any
  --enableExecuteCommand: any
  --serviceConnectConfiguration: any
]: any -> record<service: record<serviceArn: record, serviceName: record, clusterArn: record, loadBalancers: record, serviceRegistries: record, status: record, desiredCount: record, runningCount: record, pendingCount: record, launchType: record, capacityProviderStrategy: record, platformVersion: record, platformFamily: record, taskDefinition: record, deploymentConfiguration: record<deploymentCircuitBreaker: record, maximumPercent: record, minimumHealthyPercent: record, alarms: record>, taskSets: record, deployments: record, roleArn: record, events: record, createdAt: record, placementConstraints: record, placementStrategy: record, networkConfiguration: record<awsvpcConfiguration: record>, healthCheckGracePeriodSeconds: record, schedulingStrategy: record, deploymentController: record<type: record>, tags: record, createdBy: record, enableECSManagedTags: record, propagateTags: record, enableExecuteCommand: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateService")
  let body = {cluster: $cluster, serviceName: $serviceName, taskDefinition: $taskDefinition, loadBalancers: $loadBalancers, serviceRegistries: $serviceRegistries, desiredCount: $desiredCount, clientToken: $clientToken, launchType: $launchType, capacityProviderStrategy: $capacityProviderStrategy, platformVersion: $platformVersion, role: $role, deploymentConfiguration: $deploymentConfiguration, placementConstraints: $placementConstraints, placementStrategy: $placementStrategy, networkConfiguration: $networkConfiguration, healthCheckGracePeriodSeconds: $healthCheckGracePeriodSeconds, schedulingStrategy: $schedulingStrategy, deploymentController: $deploymentController, tags: $tags, enableECSManagedTags: $enableECSManagedTags, propagateTags: $propagateTags, enableExecuteCommand: $enableExecuteCommand, serviceConnectConfiguration: $serviceConnectConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a task set in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS deployment types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateTaskSet
# operationId: CreateTaskSet
export def "x-amz-target-amazon-ec2-container-service-v20141113-create-task-set CreateTaskSet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-3
  service: any
  cluster: any
  --externalId: any
  taskDefinition: any
  --networkConfiguration: any
  --loadBalancers: any
  --serviceRegistries: any
  --launchType: any
  --capacityProviderStrategy: any
  --platformVersion: any
  --scale: any
  --clientToken: any
  --tags: any
]: any -> record<taskSet: record<id: record, taskSetArn: record, serviceArn: record, clusterArn: record, startedBy: record, externalId: record, status: record, taskDefinition: record, computedDesiredCount: record, pendingCount: record, runningCount: record, createdAt: record, updatedAt: record, launchType: record, capacityProviderStrategy: record, platformVersion: record, platformFamily: record, networkConfiguration: record<awsvpcConfiguration: record>, loadBalancers: record, serviceRegistries: record, scale: record<value: record, unit: record>, stabilityStatus: record, stabilityStatusAt: record, tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateTaskSet")
  let body = {service: $service, cluster: $cluster, externalId: $externalId, taskDefinition: $taskDefinition, networkConfiguration: $networkConfiguration, loadBalancers: $loadBalancers, serviceRegistries: $serviceRegistries, launchType: $launchType, capacityProviderStrategy: $capacityProviderStrategy, platformVersion: $platformVersion, scale: $scale, clientToken: $clientToken, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disables an account setting for a specified user, role, or the root user for an account.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteAccountSetting
# operationId: DeleteAccountSetting
export def "x-amz-target-amazon-ec2-container-service-v20141113-delete-account-setting DeleteAccountSetting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-4
  name: any
  --principalArn: any
]: any -> record<setting: record<name: record, value: record, principalArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteAccountSetting")
  let body = {name: $name, principalArn: $principalArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes one or more custom attributes from an Amazon ECS resource.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteAttributes
# operationId: DeleteAttributes
export def "x-amz-target-amazon-ec2-container-service-v20141113-delete-attributes DeleteAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-5
  --cluster: any
  attributes: any
]: any -> record<attributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteAttributes")
  let body = {cluster: $cluster, attributes: $attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Deletes the specified capacity provider.</p> <note> <p>The <code>FARGATE</code> and <code>FARGATE_SPOT</code> capacity providers are reserved and can't be deleted. You can disassociate them from a cluster using either the <a>PutClusterCapacityProviders</a> API or by deleting the cluster.</p> </note> <p>Prior to a capacity provider being deleted, the capacity provider must be removed from the capacity provider strategy from all services. The <a>UpdateService</a> API can be used to remove a capacity provider from a service's capacity provider strategy. When updating a service, the <code>forceNewDeployment</code> option can be used to ensure that any tasks using the Amazon EC2 instance capacity provided by the capacity provider are transitioned to use the capacity from the remaining capacity providers. Only capacity providers that aren't associated with a cluster can be deleted. To remove a capacity provider from a cluster, you can either use <a>PutClusterCapacityProviders</a> or delete the cluster.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteCapacityProvider
# operationId: DeleteCapacityProvider
export def "x-amz-target-amazon-ec2-container-service-v20141113-delete-capacity-provider DeleteCapacityProvider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-6
  capacityProvider: any
]: any -> record<capacityProvider: record<capacityProviderArn: record, name: record, status: record, autoScalingGroupProvider: record<autoScalingGroupArn: record, managedScaling: record, managedTerminationProtection: record>, updateStatus: record, updateStatusReason: record, tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteCapacityProvider")
  let body = {capacityProvider: $capacityProvider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Deletes the specified cluster. The cluster transitions to the <code>INACTIVE</code> state. Clusters with an <code>INACTIVE</code> status might remain discoverable in your account for a period of time. However, this behavior is subject to change in the future. We don't recommend that you rely on <code>INACTIVE</code> clusters persisting.</p> <p>You must deregister all container instances from this cluster before you may delete it. You can list the container instances in a cluster with <a>ListContainerInstances</a> and deregister them with <a>DeregisterContainerInstance</a>.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteCluster
# operationId: DeleteCluster
export def "x-amz-target-amazon-ec2-container-service-v20141113-delete-cluster DeleteCluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-7
  cluster: any
]: any -> record<cluster: record<clusterArn: record, clusterName: record, configuration: record<executeCommandConfiguration: record>, status: record, registeredContainerInstancesCount: record, runningTasksCount: record, pendingTasksCount: record, activeServicesCount: record, statistics: record, tags: record, settings: record, capacityProviders: record, defaultCapacityProviderStrategy: record, attachments: record, attachmentsStatus: record, serviceConnectDefaults: record<namespace: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteCluster")
  let body = {cluster: $cluster} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Deletes a specified service within a cluster. You can delete a service if you have no running tasks in it and the desired task count is zero. If the service is actively maintaining tasks, you can't delete it, and you must update the service to a desired task count of zero. For more information, see <a>UpdateService</a>.</p> <note> <p>When you delete a service, if there are still running tasks that require cleanup, the service status moves from <code>ACTIVE</code> to <code>DRAINING</code>, and the service is no longer visible in the console or in the <a>ListServices</a> API operation. After all tasks have transitioned to either <code>STOPPING</code> or <code>STOPPED</code> status, the service status moves from <code>DRAINING</code> to <code>INACTIVE</code>. Services in the <code>DRAINING</code> or <code>INACTIVE</code> status can still be viewed with the <a>DescribeServices</a> API operation. However, in the future, <code>INACTIVE</code> services may be cleaned up and purged from Amazon ECS record keeping, and <a>DescribeServices</a> calls on those services return a <code>ServiceNotFoundException</code> error.</p> </note> <important> <p>If you attempt to create a new service with the same name as an existing service in either <code>ACTIVE</code> or <code>DRAINING</code> status, you receive an error.</p> </important>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteService
# operationId: DeleteService
export def "x-amz-target-amazon-ec2-container-service-v20141113-delete-service DeleteService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-8
  --cluster: any
  service: any
  --force: any
]: any -> record<service: record<serviceArn: record, serviceName: record, clusterArn: record, loadBalancers: record, serviceRegistries: record, status: record, desiredCount: record, runningCount: record, pendingCount: record, launchType: record, capacityProviderStrategy: record, platformVersion: record, platformFamily: record, taskDefinition: record, deploymentConfiguration: record<deploymentCircuitBreaker: record, maximumPercent: record, minimumHealthyPercent: record, alarms: record>, taskSets: record, deployments: record, roleArn: record, events: record, createdAt: record, placementConstraints: record, placementStrategy: record, networkConfiguration: record<awsvpcConfiguration: record>, healthCheckGracePeriodSeconds: record, schedulingStrategy: record, deploymentController: record<type: record>, tags: record, createdBy: record, enableECSManagedTags: record, propagateTags: record, enableExecuteCommand: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteService")
  let body = {cluster: $cluster, service: $service, force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Deletes one or more task definitions.</p> <p>You must deregister a task definition revision before you delete it. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DeregisterTaskDefinition.html">DeregisterTaskDefinition</a>.</p> <p>When you delete a task definition revision, it is immediately transitions from the <code>INACTIVE</code> to <code>DELETE_IN_PROGRESS</code>. Existing tasks and services that reference a <code>DELETE_IN_PROGRESS</code> task definition revision continue to run without disruption. Existing services that reference a <code>DELETE_IN_PROGRESS</code> task definition revision can still scale up or down by modifying the service's desired count.</p> <p>You can't use a <code>DELETE_IN_PROGRESS</code> task definition revision to run new tasks or create new services. You also can't update an existing service to reference a <code>DELETE_IN_PROGRESS</code> task definition revision.</p> <p> A task definition revision will stay in <code>DELETE_IN_PROGRESS</code> status until all the associated tasks and services have been terminated.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteTaskDefinitions
# operationId: DeleteTaskDefinitions
export def "x-amz-target-amazon-ec2-container-service-v20141113-delete-task-definitions DeleteTaskDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-9
  taskDefinitions: any
]: any -> record<taskDefinitions: record, failures: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteTaskDefinitions")
  let body = {taskDefinitions: $taskDefinitions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a specified task set within a service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS deployment types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteTaskSet
# operationId: DeleteTaskSet
export def "x-amz-target-amazon-ec2-container-service-v20141113-delete-task-set DeleteTaskSet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-10
  cluster: any
  service: any
  taskSet: any
  --force: any
]: any -> record<taskSet: record<id: record, taskSetArn: record, serviceArn: record, clusterArn: record, startedBy: record, externalId: record, status: record, taskDefinition: record, computedDesiredCount: record, pendingCount: record, runningCount: record, createdAt: record, updatedAt: record, launchType: record, capacityProviderStrategy: record, platformVersion: record, platformFamily: record, networkConfiguration: record<awsvpcConfiguration: record>, loadBalancers: record, serviceRegistries: record, scale: record<value: record, unit: record>, stabilityStatus: record, stabilityStatusAt: record, tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteTaskSet")
  let body = {cluster: $cluster, service: $service, taskSet: $taskSet, force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Deregisters an Amazon ECS container instance from the specified cluster. This instance is no longer available to run tasks.</p> <p>If you intend to use the container instance for some other purpose after deregistration, we recommend that you stop all of the tasks running on the container instance before deregistration. That prevents any orphaned tasks from consuming resources.</p> <p>Deregistering a container instance removes the instance from a cluster, but it doesn't terminate the EC2 instance. If you are finished using the instance, be sure to terminate it in the Amazon EC2 console to stop billing.</p> <note> <p>If you terminate a running container instance, Amazon ECS automatically deregisters the instance from your cluster (stopped container instances or instances with disconnected agents aren't automatically deregistered when terminated).</p> </note>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeregisterContainerInstance
# operationId: DeregisterContainerInstance
export def "x-amz-target-amazon-ec2-container-service-v20141113-deregister-container-instance DeregisterContainerInstance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-11
  --cluster: any
  containerInstance: any
  --force: any
]: any -> record<containerInstance: record<containerInstanceArn: record, ec2InstanceId: record, capacityProviderName: record, version: record, versionInfo: record<agentVersion: record, agentHash: record, dockerVersion: record>, remainingResources: record, registeredResources: record, status: record, statusReason: record, agentConnected: record, runningTasksCount: record, pendingTasksCount: record, agentUpdateStatus: record, attributes: record, registeredAt: record, attachments: record, tags: record, healthStatus: record<overallStatus: record, details: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeregisterContainerInstance")
  let body = {cluster: $cluster, containerInstance: $containerInstance, force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Deregisters the specified task definition by family and revision. Upon deregistration, the task definition is marked as <code>INACTIVE</code>. Existing tasks and services that reference an <code>INACTIVE</code> task definition continue to run without disruption. Existing services that reference an <code>INACTIVE</code> task definition can still scale up or down by modifying the service's desired count. If you want to delete a task definition revision, you must first deregister the task definition revision.</p> <p>You can't use an <code>INACTIVE</code> task definition to run new tasks or create new services, and you can't update an existing service to reference an <code>INACTIVE</code> task definition. However, there may be up to a 10-minute window following deregistration where these restrictions have not yet taken effect.</p> <note> <p>At this time, <code>INACTIVE</code> task definitions remain discoverable in your account indefinitely. However, this behavior is subject to change in the future. We don't recommend that you rely on <code>INACTIVE</code> task definitions persisting beyond the lifecycle of any associated tasks and services.</p> </note> <p>You must deregister a task definition revision before you delete it. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DeleteTaskDefinitions.html">DeleteTaskDefinitions</a>.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeregisterTaskDefinition
# operationId: DeregisterTaskDefinition
export def "x-amz-target-amazon-ec2-container-service-v20141113-deregister-task-definition DeregisterTaskDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-12
  taskDefinition: any
]: any -> record<taskDefinition: record<taskDefinitionArn: record, containerDefinitions: record, family: record, taskRoleArn: record, executionRoleArn: record, networkMode: record, revision: record, volumes: record, status: record, requiresAttributes: record, placementConstraints: record, compatibilities: record, runtimePlatform: record<cpuArchitecture: record, operatingSystemFamily: record>, requiresCompatibilities: record, cpu: record, memory: record, inferenceAccelerators: record, pidMode: record, ipcMode: record, proxyConfiguration: record<type: record, containerName: record, properties: any>, registeredAt: record, deregisteredAt: record, registeredBy: record, ephemeralStorage: record<sizeInGiB: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeregisterTaskDefinition")
  let body = {taskDefinition: $taskDefinition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Describes one or more of your capacity providers.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeCapacityProviders
# operationId: DescribeCapacityProviders
export def "x-amz-target-amazon-ec2-container-service-v20141113-describe-capacity-providers DescribeCapacityProviders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-13
  --capacityProviders: any
  --include: any
  --maxResults: any
  --nextToken: any
]: any -> record<capacityProviders: record, failures: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeCapacityProviders")
  let body = {capacityProviders: $capacityProviders, include: $include, maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Describes one or more of your clusters.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeClusters
# operationId: DescribeClusters
export def "x-amz-target-amazon-ec2-container-service-v20141113-describe-clusters DescribeClusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-14
  --clusters: any
  --include: any
]: any -> record<clusters: record, failures: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeClusters")
  let body = {clusters: $clusters, include: $include} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Describes one or more container instances. Returns metadata about each container instance requested.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeContainerInstances
# operationId: DescribeContainerInstances
export def "x-amz-target-amazon-ec2-container-service-v20141113-describe-container-instances DescribeContainerInstances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-15
  --cluster: any
  containerInstances: any
  --include: any
]: any -> record<containerInstances: record, failures: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeContainerInstances")
  let body = {cluster: $cluster, containerInstances: $containerInstances, include: $include} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Describes the specified services running in your cluster.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeServices
# operationId: DescribeServices
export def "x-amz-target-amazon-ec2-container-service-v20141113-describe-services DescribeServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-16
  --cluster: any
  services: any
  --include: any
]: any -> record<services: record, failures: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeServices")
  let body = {cluster: $cluster, services: $services, include: $include} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Describes a task definition. You can specify a <code>family</code> and <code>revision</code> to find information about a specific task definition, or you can simply specify the family to find the latest <code>ACTIVE</code> revision in that family.</p> <note> <p>You can only describe <code>INACTIVE</code> task definitions while an active task or service references them.</p> </note>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTaskDefinition
# operationId: DescribeTaskDefinition
export def "x-amz-target-amazon-ec2-container-service-v20141113-describe-task-definition DescribeTaskDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-17
  taskDefinition: any
  --include: any
]: any -> record<taskDefinition: record<taskDefinitionArn: record, containerDefinitions: record, family: record, taskRoleArn: record, executionRoleArn: record, networkMode: record, revision: record, volumes: record, status: record, requiresAttributes: record, placementConstraints: record, compatibilities: record, runtimePlatform: record<cpuArchitecture: record, operatingSystemFamily: record>, requiresCompatibilities: record, cpu: record, memory: record, inferenceAccelerators: record, pidMode: record, ipcMode: record, proxyConfiguration: record<type: record, containerName: record, properties: any>, registeredAt: record, deregisteredAt: record, registeredBy: record, ephemeralStorage: record<sizeInGiB: record>>, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTaskDefinition")
  let body = {taskDefinition: $taskDefinition, include: $include} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Describes the task sets in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTaskSets
# operationId: DescribeTaskSets
export def "x-amz-target-amazon-ec2-container-service-v20141113-describe-task-sets DescribeTaskSets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-18
  cluster: any
  service: any
  --taskSets: any
  --include: any
]: any -> record<taskSets: record, failures: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTaskSets")
  let body = {cluster: $cluster, service: $service, taskSets: $taskSets, include: $include} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Describes a specified task or tasks.</p> <p>Currently, stopped tasks appear in the returned results for at least one hour.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTasks
# operationId: DescribeTasks
export def "x-amz-target-amazon-ec2-container-service-v20141113-describe-tasks DescribeTasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-19
  --cluster: any
  tasks: any
  --include: any
]: any -> record<tasks: record, failures: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTasks")
  let body = {cluster: $cluster, tasks: $tasks, include: $include} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Returns an endpoint for the Amazon ECS agent to poll for updates.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DiscoverPollEndpoint
# operationId: DiscoverPollEndpoint
export def "x-amz-target-amazon-ec2-container-service-v20141113-discover-poll-endpoint DiscoverPollEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-20
  --containerInstance: any
  --cluster: any
]: any -> record<endpoint: record, telemetryEndpoint: record, serviceConnectEndpoint: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DiscoverPollEndpoint")
  let body = {containerInstance: $containerInstance, cluster: $cluster} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Runs a command remotely on a container within a task.</p> <p>If you use a condition key in your IAM policy to refine the conditions for the policy statement, for example limit the actions to a specific cluster, you receive an <code>AccessDeniedException</code> when there is a mismatch between the condition key value and the corresponding parameter value.</p> <p>For information about required permissions and considerations, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html">Using Amazon ECS Exec for debugging</a> in the <i>Amazon ECS Developer Guide</i>. </p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ExecuteCommand
# operationId: ExecuteCommand
export def "x-amz-target-amazon-ec2-container-service-v20141113-execute-command ExecuteCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-21
  --cluster: any
  --container: any
  command: any
  interactive: any
  task: any
]: any -> record<clusterArn: record, containerArn: record, containerName: record, interactive: record, session: record<sessionId: record, streamUrl: record, tokenValue: record>, taskArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ExecuteCommand")
  let body = {cluster: $cluster, container: $container, command: $command, interactive: $interactive, task: $task} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the protection status of tasks in an Amazon ECS service.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.GetTaskProtection
# operationId: GetTaskProtection
export def "x-amz-target-amazon-ec2-container-service-v20141113-get-task-protection GetTaskProtection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-22
  cluster: any
  --tasks: any
]: any -> record<protectedTasks: record, failures: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.GetTaskProtection")
  let body = {cluster: $cluster, tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the account settings for a specified principal.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListAccountSettings
# operationId: ListAccountSettings
export def "x-amz-target-amazon-ec2-container-service-v20141113-list-account-settings ListAccountSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-23
  --name: any
  --value: any
  --principalArn: any
  --effectiveSettings: any
  --nextToken: any
  --maxResults: any
]: any -> record<settings: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListAccountSettings" $qp)
  let body = {name: $name, value: $value, principalArn: $principalArn, effectiveSettings: $effectiveSettings, nextToken: $nextToken, maxResults: $maxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the attributes for Amazon ECS resources within a specified target type and cluster. When you specify a target type and cluster, <code>ListAttributes</code> returns a list of attribute objects, one for each attribute on each resource. You can filter the list of results to a single attribute name to only return results that have that name. You can also filter the results by attribute name and value. You can do this, for example, to see which container instances in a cluster are running a Linux AMI (<code>ecs.os-type=linux</code>). 
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListAttributes
# operationId: ListAttributes
export def "x-amz-target-amazon-ec2-container-service-v20141113-list-attributes ListAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-24
  --cluster: any
  targetType: any
  --attributeName: any
  --attributeValue: any
  --nextToken: any
  --maxResults: any
]: any -> record<attributes: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListAttributes" $qp)
  let body = {cluster: $cluster, targetType: $targetType, attributeName: $attributeName, attributeValue: $attributeValue, nextToken: $nextToken, maxResults: $maxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of existing clusters.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListClusters
# operationId: ListClusters
export def "x-amz-target-amazon-ec2-container-service-v20141113-list-clusters ListClusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-25
  --nextToken: any
  --maxResults: any
]: any -> record<clusterArns: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListClusters" $qp)
  let body = {nextToken: $nextToken, maxResults: $maxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of container instances in a specified cluster. You can filter the results of a <code>ListContainerInstances</code> operation with cluster query language statements inside the <code>filter</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html">Cluster Query Language</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListContainerInstances
# operationId: ListContainerInstances
export def "x-amz-target-amazon-ec2-container-service-v20141113-list-container-instances ListContainerInstances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-26
  --cluster: any
  --filter: any
  --nextToken: any
  --maxResults: any
  --status: any
]: any -> record<containerInstanceArns: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListContainerInstances" $qp)
  let body = {cluster: $cluster, filter: $filter, nextToken: $nextToken, maxResults: $maxResults, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of services. You can filter the results by cluster, launch type, and scheduling strategy.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListServices
# operationId: ListServices
export def "x-amz-target-amazon-ec2-container-service-v20141113-list-services ListServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-27
  --cluster: any
  --nextToken: any
  --maxResults: any
  --launchType: any
  --schedulingStrategy: any
]: any -> record<serviceArns: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListServices" $qp)
  let body = {cluster: $cluster, nextToken: $nextToken, maxResults: $maxResults, launchType: $launchType, schedulingStrategy: $schedulingStrategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This operation lists all of the services that are associated with a Cloud Map namespace. This list might include services in different clusters. In contrast, <code>ListServices</code> can only list services in one cluster at a time. If you need to filter the list of services in a single cluster by various parameters, use <code>ListServices</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html">Service Connect</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListServicesByNamespace
# operationId: ListServicesByNamespace
export def "x-amz-target-amazon-ec2-container-service-v20141113-list-services-by-namespace ListServicesByNamespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-28
  namespace: any
  --nextToken: any
  --maxResults: any
]: any -> record<serviceArns: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListServicesByNamespace" $qp)
  let body = {namespace: $namespace, nextToken: $nextToken, maxResults: $maxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the tags for an Amazon ECS resource.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTagsForResource
# operationId: ListTagsForResource
export def "x-amz-target-amazon-ec2-container-service-v20141113-list-tags-for-resource ListTagsForResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-29
  resourceArn: any
]: any -> record<tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTagsForResource")
  let body = {resourceArn: $resourceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Returns a list of task definition families that are registered to your account. This list includes task definition families that no longer have any <code>ACTIVE</code> task definition revisions.</p> <p>You can filter out task definition families that don't contain any <code>ACTIVE</code> task definition revisions by setting the <code>status</code> parameter to <code>ACTIVE</code>. You can also filter the results with the <code>familyPrefix</code> parameter.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTaskDefinitionFamilies
# operationId: ListTaskDefinitionFamilies
export def "x-amz-target-amazon-ec2-container-service-v20141113-list-task-definition-families ListTaskDefinitionFamilies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-30
  --familyPrefix: any
  --status: any
  --nextToken: any
  --maxResults: any
]: any -> record<families: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTaskDefinitionFamilies" $qp)
  let body = {familyPrefix: $familyPrefix, status: $status, nextToken: $nextToken, maxResults: $maxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of task definitions that are registered to your account. You can filter the results by family name with the <code>familyPrefix</code> parameter or by status with the <code>status</code> parameter.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTaskDefinitions
# operationId: ListTaskDefinitions
export def "x-amz-target-amazon-ec2-container-service-v20141113-list-task-definitions ListTaskDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-31
  --familyPrefix: any
  --status: any
  --body-sort: any
  --nextToken: any
  --maxResults: any
]: any -> record<taskDefinitionArns: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTaskDefinitions" $qp)
  let body = {familyPrefix: $familyPrefix, status: $status, sort: $body_sort, nextToken: $nextToken, maxResults: $maxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Returns a list of tasks. You can filter the results by cluster, task definition family, container instance, launch type, what IAM principal started the task, or by the desired status of the task.</p> <p>Recently stopped tasks might appear in the returned results. Currently, stopped tasks appear in the returned results for at least one hour.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTasks
# operationId: ListTasks
export def "x-amz-target-amazon-ec2-container-service-v20141113-list-tasks ListTasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-32
  --cluster: any
  --containerInstance: any
  --family: any
  --nextToken: any
  --maxResults: any
  --startedBy: any
  --serviceName: any
  --desiredStatus: any
  --launchType: any
]: any -> record<taskArns: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTasks" $qp)
  let body = {cluster: $cluster, containerInstance: $containerInstance, family: $family, nextToken: $nextToken, maxResults: $maxResults, startedBy: $startedBy, serviceName: $serviceName, desiredStatus: $desiredStatus, launchType: $launchType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Modifies an account setting. Account settings are set on a per-Region basis.</p> <p>If you change the root user account setting, the default settings are reset for users and roles that do not have specified individual account settings. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html">Account Settings</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>serviceLongArnFormat</code>, <code>taskLongArnFormat</code>, or <code>containerInstanceLongArnFormat</code> are specified, the Amazon Resource Name (ARN) and resource ID format of the resource type for a specified user, role, or the root user for an account is affected. The opt-in and opt-out account setting must be set for each Amazon ECS resource separately. The ARN and resource ID format of a resource is defined by the opt-in status of the user or role that created the resource. You must turn on this setting to use Amazon ECS features such as resource tagging.</p> <p>When <code>awsvpcTrunking</code> is specified, the elastic network interface (ENI) limit for any new container instances that support the feature is changed. If <code>awsvpcTrunking</code> is turned on, any new container instances that support the feature are launched have the increased ENI limits available to them. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html">Elastic Network Interface Trunking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>containerInsights</code> is specified, the default setting indicating whether Amazon Web Services CloudWatch Container Insights is turned on for your clusters is changed. If <code>containerInsights</code> is turned on, any new clusters that are created will have Container Insights turned on unless you disable it during cluster creation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-container-insights.html">CloudWatch Container Insights</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Amazon ECS is introducing tagging authorization for resource creation. Users must have permissions for actions that create the resource, such as <code>ecsCreateCluster</code>. If tags are specified when you create a resource, Amazon Web Services performs additional authorization to verify if users or roles have permissions to create tags. Therefore, you must grant explicit permissions to use the <code>ecs:TagResource</code> action. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/supported-iam-actions-tagging.html">Grant permission to tag resources on creation</a> in the <i>Amazon ECS Developer Guide</i>.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAccountSetting
# operationId: PutAccountSetting
export def "x-amz-target-amazon-ec2-container-service-v20141113-put-account-setting PutAccountSetting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-33
  name: any
  value: any
  --principalArn: any
]: any -> record<setting: record<name: record, value: record, principalArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAccountSetting")
  let body = {name: $name, value: $value, principalArn: $principalArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Modifies an account setting for all users on an account for whom no individual account setting has been specified. Account settings are set on a per-Region basis.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAccountSettingDefault
# operationId: PutAccountSettingDefault
export def "x-amz-target-amazon-ec2-container-service-v20141113-put-account-setting-default PutAccountSettingDefault" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-34
  name: any
  value: any
]: any -> record<setting: record<name: record, value: record, principalArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAccountSettingDefault")
  let body = {name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or update an attribute on an Amazon ECS resource. If the attribute doesn't exist, it's created. If the attribute exists, its value is replaced with the specified value. To delete an attribute, use <a>DeleteAttributes</a>. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#attributes">Attributes</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAttributes
# operationId: PutAttributes
export def "x-amz-target-amazon-ec2-container-service-v20141113-put-attributes PutAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-35
  --cluster: any
  attributes: any
]: any -> record<attributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAttributes")
  let body = {cluster: $cluster, attributes: $attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Modifies the available capacity providers and the default capacity provider strategy for a cluster.</p> <p>You must specify both the available capacity providers and a default capacity provider strategy for the cluster. If the specified cluster has existing capacity providers associated with it, you must specify all existing capacity providers in addition to any new ones you want to add. Any existing capacity providers that are associated with a cluster that are omitted from a <a>PutClusterCapacityProviders</a> API call will be disassociated with the cluster. You can only disassociate an existing capacity provider from a cluster if it's not being used by any existing tasks.</p> <p>When creating a service or running a task on a cluster, if no capacity provider or launch type is specified, then the cluster's default capacity provider strategy is used. We recommend that you define a default capacity provider strategy for your cluster. However, you must specify an empty array (<code>[]</code>) to bypass defining a default strategy.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutClusterCapacityProviders
# operationId: PutClusterCapacityProviders
export def "x-amz-target-amazon-ec2-container-service-v20141113-put-cluster-capacity-providers PutClusterCapacityProviders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-36
  cluster: any
  capacityProviders: any
  defaultCapacityProviderStrategy: any
]: any -> record<cluster: record<clusterArn: record, clusterName: record, configuration: record<executeCommandConfiguration: record>, status: record, registeredContainerInstancesCount: record, runningTasksCount: record, pendingTasksCount: record, activeServicesCount: record, statistics: record, tags: record, settings: record, capacityProviders: record, defaultCapacityProviderStrategy: record, attachments: record, attachmentsStatus: record, serviceConnectDefaults: record<namespace: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutClusterCapacityProviders")
  let body = {cluster: $cluster, capacityProviders: $capacityProviders, defaultCapacityProviderStrategy: $defaultCapacityProviderStrategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Registers an EC2 instance into the specified cluster. This instance becomes available to place containers on.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RegisterContainerInstance
# operationId: RegisterContainerInstance
export def "x-amz-target-amazon-ec2-container-service-v20141113-register-container-instance RegisterContainerInstance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-37
  --cluster: any
  --instanceIdentityDocument: any
  --instanceIdentityDocumentSignature: any
  --totalResources: any
  --versionInfo: any
  --containerInstanceArn: any
  --attributes: any
  --platformDevices: any
  --tags: any
]: any -> record<containerInstance: record<containerInstanceArn: record, ec2InstanceId: record, capacityProviderName: record, version: record, versionInfo: record<agentVersion: record, agentHash: record, dockerVersion: record>, remainingResources: record, registeredResources: record, status: record, statusReason: record, agentConnected: record, runningTasksCount: record, pendingTasksCount: record, agentUpdateStatus: record, attributes: record, registeredAt: record, attachments: record, tags: record, healthStatus: record<overallStatus: record, details: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RegisterContainerInstance")
  let body = {cluster: $cluster, instanceIdentityDocument: $instanceIdentityDocument, instanceIdentityDocumentSignature: $instanceIdentityDocumentSignature, totalResources: $totalResources, versionInfo: $versionInfo, containerInstanceArn: $containerInstanceArn, attributes: $attributes, platformDevices: $platformDevices, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Registers a new task definition from the supplied <code>family</code> and <code>containerDefinitions</code>. Optionally, you can add data volumes to your containers with the <code>volumes</code> parameter. For more information about task definition parameters and defaults, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_defintions.html">Amazon ECS Task Definitions</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify a role for your task with the <code>taskRoleArn</code> parameter. When you specify a role for a task, its containers can then use the latest versions of the CLI or SDKs to make API requests to the Amazon Web Services services that are specified in the policy that's associated with the role. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html">IAM Roles for Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify a Docker networking mode for the containers in your task definition with the <code>networkMode</code> parameter. The available network modes correspond to those described in <a href="https://docs.docker.com/engine/reference/run/#/network-settings">Network settings</a> in the Docker run reference. If you specify the <code>awsvpc</code> network mode, the task is allocated an elastic network interface, and you must specify a <a>NetworkConfiguration</a> when you create a service or run a task with the task definition. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html">Task Networking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RegisterTaskDefinition
# operationId: RegisterTaskDefinition
export def "x-amz-target-amazon-ec2-container-service-v20141113-register-task-definition RegisterTaskDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-38
  family: any
  --taskRoleArn: any
  --executionRoleArn: any
  --networkMode: any
  containerDefinitions: any
  --volumes: any
  --placementConstraints: any
  --requiresCompatibilities: any
  --cpu: any
  --memory: any
  --tags: any
  --pidMode: any
  --ipcMode: any
  --proxyConfiguration: any
  --inferenceAccelerators: any
  --ephemeralStorage: any
  --runtimePlatform: any
]: any -> record<taskDefinition: record<taskDefinitionArn: record, containerDefinitions: record, family: record, taskRoleArn: record, executionRoleArn: record, networkMode: record, revision: record, volumes: record, status: record, requiresAttributes: record, placementConstraints: record, compatibilities: record, runtimePlatform: record<cpuArchitecture: record, operatingSystemFamily: record>, requiresCompatibilities: record, cpu: record, memory: record, inferenceAccelerators: record, pidMode: record, ipcMode: record, proxyConfiguration: record<type: record, containerName: record, properties: any>, registeredAt: record, deregisteredAt: record, registeredBy: record, ephemeralStorage: record<sizeInGiB: record>>, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RegisterTaskDefinition")
  let body = {family: $family, taskRoleArn: $taskRoleArn, executionRoleArn: $executionRoleArn, networkMode: $networkMode, containerDefinitions: $containerDefinitions, volumes: $volumes, placementConstraints: $placementConstraints, requiresCompatibilities: $requiresCompatibilities, cpu: $cpu, memory: $memory, tags: $tags, pidMode: $pidMode, ipcMode: $ipcMode, proxyConfiguration: $proxyConfiguration, inferenceAccelerators: $inferenceAccelerators, ephemeralStorage: $ephemeralStorage, runtimePlatform: $runtimePlatform} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Starts a new task using the specified task definition.</p> <p>You can allow Amazon ECS to place tasks for you, or you can customize how Amazon ECS places tasks using placement constraints and placement strategies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Alternatively, you can use <a>StartTask</a> to use your own scheduler or place tasks manually on specific container instances.</p> <note> <p>Starting April 15, 2023, Amazon Web Services will not onboard new customers to Amazon Elastic Inference (EI), and will help current customers migrate their workloads to options that offer better price and performance. After April 15, 2023, new customers will not be able to launch instances with Amazon EI accelerators in Amazon SageMaker, Amazon ECS, or Amazon EC2. However, customers who have used Amazon EI at least once during the past 30-day period are considered current customers and will be able to continue using the service. </p> </note> <p>The Amazon ECS API follows an eventual consistency model. This is because of the distributed nature of the system supporting the API. This means that the result of an API command you run that affects your Amazon ECS resources might not be immediately visible to all subsequent commands you run. Keep this in mind when you carry out an API command that immediately follows a previous API command.</p> <p>To manage eventual consistency, you can do the following:</p> <ul> <li> <p>Confirm the state of the resource before you run a command to modify it. Run the DescribeTasks command using an exponential backoff algorithm to ensure that you allow enough time for the previous command to propagate through the system. To do this, run the DescribeTasks command repeatedly, starting with a couple of seconds of wait time and increasing gradually up to five minutes of wait time.</p> </li> <li> <p>Add wait time between subsequent commands, even if the DescribeTasks command returns an accurate response. Apply an exponential backoff algorithm starting with a couple of seconds of wait time, and increase gradually up to about five minutes of wait time.</p> </li> </ul>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RunTask
# operationId: RunTask
export def "x-amz-target-amazon-ec2-container-service-v20141113-run-task RunTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-39
  --capacityProviderStrategy: any
  --cluster: any
  --count: any
  --enableECSManagedTags: any
  --enableExecuteCommand: any
  --group: any
  --launchType: any
  --networkConfiguration: any
  --overrides: any
  --placementConstraints: any
  --placementStrategy: any
  --platformVersion: any
  --propagateTags: any
  --referenceId: any
  --startedBy: any
  --tags: any
  taskDefinition: any
]: any -> record<tasks: record, failures: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RunTask")
  let body = {capacityProviderStrategy: $capacityProviderStrategy, cluster: $cluster, count: $count, enableECSManagedTags: $enableECSManagedTags, enableExecuteCommand: $enableExecuteCommand, group: $group, launchType: $launchType, networkConfiguration: $networkConfiguration, overrides: $overrides, placementConstraints: $placementConstraints, placementStrategy: $placementStrategy, platformVersion: $platformVersion, propagateTags: $propagateTags, referenceId: $referenceId, startedBy: $startedBy, tags: $tags, taskDefinition: $taskDefinition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Starts a new task from the specified task definition on the specified container instance or instances.</p> <note> <p>Starting April 15, 2023, Amazon Web Services will not onboard new customers to Amazon Elastic Inference (EI), and will help current customers migrate their workloads to options that offer better price and performance. After April 15, 2023, new customers will not be able to launch instances with Amazon EI accelerators in Amazon SageMaker, Amazon ECS, or Amazon EC2. However, customers who have used Amazon EI at least once during the past 30-day period are considered current customers and will be able to continue using the service. </p> </note> <p>Alternatively, you can use <a>RunTask</a> to place tasks for you. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.StartTask
# operationId: StartTask
export def "x-amz-target-amazon-ec2-container-service-v20141113-start-task StartTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-40
  --cluster: any
  containerInstances: any
  --enableECSManagedTags: any
  --enableExecuteCommand: any
  --group: any
  --networkConfiguration: any
  --overrides: any
  --propagateTags: any
  --referenceId: any
  --startedBy: any
  --tags: any
  taskDefinition: any
]: any -> record<tasks: record, failures: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.StartTask")
  let body = {cluster: $cluster, containerInstances: $containerInstances, enableECSManagedTags: $enableECSManagedTags, enableExecuteCommand: $enableExecuteCommand, group: $group, networkConfiguration: $networkConfiguration, overrides: $overrides, propagateTags: $propagateTags, referenceId: $referenceId, startedBy: $startedBy, tags: $tags, taskDefinition: $taskDefinition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Stops a running task. Any tags associated with the task will be deleted.</p> <p>When <a>StopTask</a> is called on a task, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> value and a default 30-second timeout, after which the <code>SIGKILL</code> value is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> value gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> value is sent.</p> <note> <p>The default 30-second timeout can be configured on the Amazon ECS container agent with the <code>ECS_CONTAINER_STOP_TIMEOUT</code> variable. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html">Amazon ECS Container Agent Configuration</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.StopTask
# operationId: StopTask
export def "x-amz-target-amazon-ec2-container-service-v20141113-stop-task StopTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-41
  --cluster: any
  task: any
  --reason: any
]: any -> record<task: record<attachments: record, attributes: record, availabilityZone: record, capacityProviderName: record, clusterArn: record, connectivity: record, connectivityAt: record, containerInstanceArn: record, containers: record, cpu: record, createdAt: record, desiredStatus: record, enableExecuteCommand: record, executionStoppedAt: record, group: record, healthStatus: record, inferenceAccelerators: record, lastStatus: record, launchType: record, memory: record, overrides: record<containerOverrides: record, cpu: record, inferenceAcceleratorOverrides: record, executionRoleArn: record, memory: record, taskRoleArn: record, ephemeralStorage: record>, platformVersion: record, platformFamily: record, pullStartedAt: record, pullStoppedAt: record, startedAt: record, startedBy: record, stopCode: record, stoppedAt: record, stoppedReason: record, stoppingAt: record, tags: record, taskArn: record, taskDefinitionArn: record, version: record, ephemeralStorage: record<sizeInGiB: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.StopTask")
  let body = {cluster: $cluster, task: $task, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that an attachment changed states.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitAttachmentStateChanges
# operationId: SubmitAttachmentStateChanges
export def "x-amz-target-amazon-ec2-container-service-v20141113-submit-attachment-state-changes SubmitAttachmentStateChanges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-42
  --cluster: any
  attachments: any
]: any -> record<acknowledgment: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitAttachmentStateChanges")
  let body = {cluster: $cluster, attachments: $attachments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a container changed states.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitContainerStateChange
# operationId: SubmitContainerStateChange
export def "x-amz-target-amazon-ec2-container-service-v20141113-submit-container-state-change SubmitContainerStateChange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-43
  --cluster: any
  --task: any
  --containerName: any
  --runtimeId: any
  --status: any
  --exitCode: any
  --reason: any
  --networkBindings: any
]: any -> record<acknowledgment: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitContainerStateChange")
  let body = {cluster: $cluster, task: $task, containerName: $containerName, runtimeId: $runtimeId, status: $status, exitCode: $exitCode, reason: $reason, networkBindings: $networkBindings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a task changed states.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitTaskStateChange
# operationId: SubmitTaskStateChange
export def "x-amz-target-amazon-ec2-container-service-v20141113-submit-task-state-change SubmitTaskStateChange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-44
  --cluster: any
  --task: any
  --status: any
  --reason: any
  --containers: any
  --attachments: any
  --managedAgents: any
  --pullStartedAt: any
  --pullStoppedAt: any
  --executionStoppedAt: any
]: any -> record<acknowledgment: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitTaskStateChange")
  let body = {cluster: $cluster, task: $task, status: $status, reason: $reason, containers: $containers, attachments: $attachments, managedAgents: $managedAgents, pullStartedAt: $pullStartedAt, pullStoppedAt: $pullStoppedAt, executionStoppedAt: $executionStoppedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource aren't specified in the request parameters, they aren't changed. When a resource is deleted, the tags that are associated with that resource are deleted as well.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.TagResource
# operationId: TagResource
export def "x-amz-target-amazon-ec2-container-service-v20141113-tag-resource TagResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-45
  resourceArn: any
  tags: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.TagResource")
  let body = {resourceArn: $resourceArn, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes specified tags from a resource.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UntagResource
# operationId: UntagResource
export def "x-amz-target-amazon-ec2-container-service-v20141113-untag-resource UntagResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-46
  resourceArn: any
  tagKeys: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UntagResource")
  let body = {resourceArn: $resourceArn, tagKeys: $tagKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Modifies the parameters for a capacity provider.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateCapacityProvider
# operationId: UpdateCapacityProvider
export def "x-amz-target-amazon-ec2-container-service-v20141113-update-capacity-provider UpdateCapacityProvider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-47
  name: any
  autoScalingGroupProvider: any
]: any -> record<capacityProvider: record<capacityProviderArn: record, name: record, status: record, autoScalingGroupProvider: record<autoScalingGroupArn: record, managedScaling: record, managedTerminationProtection: record>, updateStatus: record, updateStatusReason: record, tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateCapacityProvider")
  let body = {name: $name, autoScalingGroupProvider: $autoScalingGroupProvider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the cluster.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateCluster
# operationId: UpdateCluster
export def "x-amz-target-amazon-ec2-container-service-v20141113-update-cluster UpdateCluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-48
  cluster: any
  --settings: any
  --configuration: any
  --serviceConnectDefaults: any
]: any -> record<cluster: record<clusterArn: record, clusterName: record, configuration: record<executeCommandConfiguration: record>, status: record, registeredContainerInstancesCount: record, runningTasksCount: record, pendingTasksCount: record, activeServicesCount: record, statistics: record, tags: record, settings: record, capacityProviders: record, defaultCapacityProviderStrategy: record, attachments: record, attachmentsStatus: record, serviceConnectDefaults: record<namespace: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateCluster")
  let body = {cluster: $cluster, settings: $settings, configuration: $configuration, serviceConnectDefaults: $serviceConnectDefaults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Modifies the settings to use for a cluster.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateClusterSettings
# operationId: UpdateClusterSettings
export def "x-amz-target-amazon-ec2-container-service-v20141113-update-cluster-settings UpdateClusterSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-49
  cluster: any
  settings: any
]: any -> record<cluster: record<clusterArn: record, clusterName: record, configuration: record<executeCommandConfiguration: record>, status: record, registeredContainerInstancesCount: record, runningTasksCount: record, pendingTasksCount: record, activeServicesCount: record, statistics: record, tags: record, settings: record, capacityProviders: record, defaultCapacityProviderStrategy: record, attachments: record, attachmentsStatus: record, serviceConnectDefaults: record<namespace: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateClusterSettings")
  let body = {cluster: $cluster, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Updates the Amazon ECS container agent on a specified container instance. Updating the Amazon ECS container agent doesn't interrupt running tasks or services on the container instance. The process for updating the agent differs depending on whether your container instance was launched with the Amazon ECS-optimized AMI or another operating system.</p> <note> <p>The <code>UpdateContainerAgent</code> API isn't supported for container instances using the Amazon ECS-optimized Amazon Linux 2 (arm64) AMI. To update the container agent, you can update the <code>ecs-init</code> package. This updates the agent. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/agent-update-ecs-ami.html">Updating the Amazon ECS container agent</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note> <note> <p>Agent updates with the <code>UpdateContainerAgent</code> API operation do not apply to Windows container instances. We recommend that you launch new container instances to update the agent version in your Windows clusters.</p> </note> <p>The <code>UpdateContainerAgent</code> API requires an Amazon ECS-optimized AMI or Amazon Linux AMI with the <code>ecs-init</code> service installed and running. For help updating the Amazon ECS container agent on other operating systems, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-update.html#manually_update_agent">Manually updating the Amazon ECS container agent</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateContainerAgent
# operationId: UpdateContainerAgent
export def "x-amz-target-amazon-ec2-container-service-v20141113-update-container-agent UpdateContainerAgent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-50
  --cluster: any
  containerInstance: any
]: any -> record<containerInstance: record<containerInstanceArn: record, ec2InstanceId: record, capacityProviderName: record, version: record, versionInfo: record<agentVersion: record, agentHash: record, dockerVersion: record>, remainingResources: record, registeredResources: record, status: record, statusReason: record, agentConnected: record, runningTasksCount: record, pendingTasksCount: record, agentUpdateStatus: record, attributes: record, registeredAt: record, attachments: record, tags: record, healthStatus: record<overallStatus: record, details: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateContainerAgent")
  let body = {cluster: $cluster, containerInstance: $containerInstance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Modifies the status of an Amazon ECS container instance.</p> <p>Once a container instance has reached an <code>ACTIVE</code> state, you can change the status of a container instance to <code>DRAINING</code> to manually remove an instance from a cluster, for example to perform system updates, update the Docker daemon, or scale down the cluster size.</p> <important> <p>A container instance can't be changed to <code>DRAINING</code> until it has reached an <code>ACTIVE</code> status. If the instance is in any other status, an error will be received.</p> </important> <p>When you set a container instance to <code>DRAINING</code>, Amazon ECS prevents new tasks from being scheduled for placement on the container instance and replacement service tasks are started on other container instances in the cluster if the resources are available. Service tasks on the container instance that are in the <code>PENDING</code> state are stopped immediately.</p> <p>Service tasks on the container instance that are in the <code>RUNNING</code> state are stopped and replaced according to the service's deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>. You can change the deployment configuration of your service using <a>UpdateService</a>.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during task replacement. For example, <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. If the minimum is 100%, the service scheduler can't remove existing tasks until the replacement tasks are considered healthy. Tasks for services that do not use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and are reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during task replacement. You can use this to define the replacement batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four tasks to be drained, provided that the cluster resources required to do this are available. If the maximum is 100%, then replacement tasks can't start until the draining tasks have stopped.</p> </li> </ul> <p>Any <code>PENDING</code> or <code>RUNNING</code> tasks that do not belong to a service aren't affected. You must wait for them to finish or stop them manually.</p> <p>A container instance has completed draining when it has no more <code>RUNNING</code> tasks. You can verify this using <a>ListTasks</a>.</p> <p>When a container instance has been drained, you can set a container instance to <code>ACTIVE</code> status and once it has reached that status the Amazon ECS scheduler can begin scheduling tasks on the instance again.</p>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateContainerInstancesState
# operationId: UpdateContainerInstancesState
export def "x-amz-target-amazon-ec2-container-service-v20141113-update-container-instances-state UpdateContainerInstancesState" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-51
  --cluster: any
  containerInstances: any
  status: any
]: any -> record<containerInstances: record, failures: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateContainerInstancesState")
  let body = {cluster: $cluster, containerInstances: $containerInstances, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Modifies the parameters of a service.</p> <p>For services using the rolling update (<code>ECS</code>) you can update the desired count, deployment configuration, network configuration, load balancers, service registries, enable ECS managed tags option, propagate tags option, task placement constraints and strategies, and task definition. When you update any of these parameters, Amazon ECS starts new tasks with the new configuration. </p> <p>For services using the blue/green (<code>CODE_DEPLOY</code>) deployment controller, only the desired count, deployment configuration, health check grace period, task placement constraints and strategies, enable ECS managed tags option, and propagate tags can be updated using this API. If the network configuration, platform version, task definition, or load balancer need to be updated, create a new CodeDeploy deployment. For more information, see <a href="https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html">CreateDeployment</a> in the <i>CodeDeploy API Reference</i>.</p> <p>For services using an external deployment controller, you can update only the desired count, task placement constraints and strategies, health check grace period, enable ECS managed tags option, and propagate tags option, using this API. If the launch type, load balancer, network configuration, platform version, or task definition need to be updated, create a new task set For more information, see <a>CreateTaskSet</a>.</p> <p>You can add to or subtract from the number of instantiations of a task definition in a service by specifying the cluster that the service is running in and a new <code>desiredCount</code> parameter.</p> <p>If you have updated the Docker image of your application, you can create a new task definition with that image and deploy it to your service. The service scheduler uses the minimum healthy percent and maximum percent parameters (in the service's deployment configuration) to determine the deployment strategy.</p> <note> <p>If your updated Docker image uses the same tag as what is in the existing task definition for your service (for example, <code>my_image:latest</code>), you don't need to create a new revision of your task definition. You can update the service using the <code>forceNewDeployment</code> option. The new tasks launched by the deployment pull the current image/tag combination from your repository when they start.</p> </note> <p>You can also update the deployment configuration of a service. When a deployment is triggered by updating the task definition of a service, the service scheduler uses the deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>, to determine the deployment strategy.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during a deployment. For example, if <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. Tasks for services that don't use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and are reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during a deployment. You can use it to define the deployment batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available).</p> </li> </ul> <p>When <a>UpdateService</a> stops a task during a deployment, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> and a 30-second timeout. After this, <code>SIGKILL</code> is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> is sent.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster with the following logic.</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition. For example, they have the required CPU, memory, ports, and container instance attributes.</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner even though you can choose a different placement strategy.</p> <ul> <li> <p>Sort the valid container instances by the fewest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul> <p>When the service scheduler stops running tasks, it attempts to maintain balance across the Availability Zones in your cluster using the following logic: </p> <ul> <li> <p>Sort the container instances by the largest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have two, container instances in either zone B or C are considered optimal for termination.</p> </li> <li> <p>Stop the task on a container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the largest number of running tasks for this service.</p> </li> </ul> <note> <p>You must have a service-linked role when you update any of the following service properties. If you specified a custom role when you created the service, Amazon ECS automatically replaces the <a href="https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_Service.html#ECS-Type-Service-roleArn">roleARN</a> associated with the service with the ARN of your service-linked role. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html">Service-linked roles</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <ul> <li> <p> <code>loadBalancers,</code> </p> </li> <li> <p> <code>serviceRegistries</code> </p> </li> </ul> </note>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateService
# operationId: UpdateService
export def "x-amz-target-amazon-ec2-container-service-v20141113-update-service UpdateService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-52
  --cluster: any
  service: any
  --desiredCount: any
  --taskDefinition: any
  --capacityProviderStrategy: any
  --deploymentConfiguration: any
  --networkConfiguration: any
  --placementConstraints: any
  --placementStrategy: any
  --platformVersion: any
  --forceNewDeployment: any
  --healthCheckGracePeriodSeconds: any
  --enableExecuteCommand: any
  --enableECSManagedTags: any
  --loadBalancers: any
  --propagateTags: any
  --serviceRegistries: any
  --serviceConnectConfiguration: any
]: any -> record<service: record<serviceArn: record, serviceName: record, clusterArn: record, loadBalancers: record, serviceRegistries: record, status: record, desiredCount: record, runningCount: record, pendingCount: record, launchType: record, capacityProviderStrategy: record, platformVersion: record, platformFamily: record, taskDefinition: record, deploymentConfiguration: record<deploymentCircuitBreaker: record, maximumPercent: record, minimumHealthyPercent: record, alarms: record>, taskSets: record, deployments: record, roleArn: record, events: record, createdAt: record, placementConstraints: record, placementStrategy: record, networkConfiguration: record<awsvpcConfiguration: record>, healthCheckGracePeriodSeconds: record, schedulingStrategy: record, deploymentController: record<type: record>, tags: record, createdBy: record, enableECSManagedTags: record, propagateTags: record, enableExecuteCommand: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateService")
  let body = {cluster: $cluster, service: $service, desiredCount: $desiredCount, taskDefinition: $taskDefinition, capacityProviderStrategy: $capacityProviderStrategy, deploymentConfiguration: $deploymentConfiguration, networkConfiguration: $networkConfiguration, placementConstraints: $placementConstraints, placementStrategy: $placementStrategy, platformVersion: $platformVersion, forceNewDeployment: $forceNewDeployment, healthCheckGracePeriodSeconds: $healthCheckGracePeriodSeconds, enableExecuteCommand: $enableExecuteCommand, enableECSManagedTags: $enableECSManagedTags, loadBalancers: $loadBalancers, propagateTags: $propagateTags, serviceRegistries: $serviceRegistries, serviceConnectConfiguration: $serviceConnectConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Modifies which task set in a service is the primary task set. Any parameters that are updated on the primary task set in a service will transition to the service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateServicePrimaryTaskSet
# operationId: UpdateServicePrimaryTaskSet
export def "x-amz-target-amazon-ec2-container-service-v20141113-update-service-primary-task-set UpdateServicePrimaryTaskSet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-53
  cluster: any
  service: any
  primaryTaskSet: any
]: any -> record<taskSet: record<id: record, taskSetArn: record, serviceArn: record, clusterArn: record, startedBy: record, externalId: record, status: record, taskDefinition: record, computedDesiredCount: record, pendingCount: record, runningCount: record, createdAt: record, updatedAt: record, launchType: record, capacityProviderStrategy: record, platformVersion: record, platformFamily: record, networkConfiguration: record<awsvpcConfiguration: record>, loadBalancers: record, serviceRegistries: record, scale: record<value: record, unit: record>, stabilityStatus: record, stabilityStatusAt: record, tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateServicePrimaryTaskSet")
  let body = {cluster: $cluster, service: $service, primaryTaskSet: $primaryTaskSet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Updates the protection status of a task. You can set <code>protectionEnabled</code> to <code>true</code> to protect your task from termination during scale-in events from <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html">Service Autoscaling</a> or <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">deployments</a>.</p> <p>Task-protection, by default, expires after 2 hours at which point Amazon ECS clears the <code>protectionEnabled</code> property making the task eligible for termination by a subsequent scale-in event.</p> <p>You can specify a custom expiration period for task protection from 1 minute to up to 2,880 minutes (48 hours). To specify the custom expiration period, set the <code>expiresInMinutes</code> property. The <code>expiresInMinutes</code> property is always reset when you invoke this operation for a task that already has <code>protectionEnabled</code> set to <code>true</code>. You can keep extending the protection expiration period of a task by invoking this operation repeatedly.</p> <p>To learn more about Amazon ECS task protection, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-scale-in-protection.html">Task scale-in protection</a> in the <i> <i>Amazon Elastic Container Service Developer Guide</i> </i>.</p> <note> <p>This operation is only supported for tasks belonging to an Amazon ECS service. Invoking this operation for a standalone task will result in an <code>TASK_NOT_VALID</code> failure. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/api_failures_messages.html">API failure reasons</a>.</p> </note> <important> <p>If you prefer to set task protection from within the container, we recommend using the <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-scale-in-protection-endpoint.html">Task scale-in protection endpoint</a>.</p> </important>
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateTaskProtection
# operationId: UpdateTaskProtection
export def "x-amz-target-amazon-ec2-container-service-v20141113-update-task-protection UpdateTaskProtection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-54
  cluster: any
  tasks: any
  protectionEnabled: any
  --expiresInMinutes: any
]: any -> record<protectedTasks: record, failures: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateTaskProtection")
  let body = {cluster: $cluster, tasks: $tasks, protectionEnabled: $protectionEnabled, expiresInMinutes: $expiresInMinutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Modifies a task set. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
#
# POST /#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateTaskSet
# operationId: UpdateTaskSet
export def "x-amz-target-amazon-ec2-container-service-v20141113-update-task-set UpdateTaskSet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-55
  cluster: any
  service: any
  taskSet: any
  scale: any
]: any -> record<taskSet: record<id: record, taskSetArn: record, serviceArn: record, clusterArn: record, startedBy: record, externalId: record, status: record, taskDefinition: record, computedDesiredCount: record, pendingCount: record, runningCount: record, createdAt: record, updatedAt: record, launchType: record, capacityProviderStrategy: record, platformVersion: record, platformFamily: record, networkConfiguration: record<awsvpcConfiguration: record>, loadBalancers: record, serviceRegistries: record, scale: record<value: record, unit: record>, stabilityStatus: record, stabilityStatusAt: record, tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateTaskSet")
  let body = {cluster: $cluster, service: $service, taskSet: $taskSet, scale: $scale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
