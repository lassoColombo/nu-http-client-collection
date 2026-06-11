# Auto-generated client for AWS App Runner v2020-05-15
# Source: https://api.apis.guru/v2/specs/amazonaws.com/apprunner/2020-05-15/openapi.json
# Auth: --token flag or $env.AWS_APP_RUNNER_TOKEN

const BASE_URL = "http://apprunner.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_APP_RUNNER_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["http://apprunner.us-east-1.amazonaws.com" "http://apprunner.us-east-2.amazonaws.com" "http://apprunner.us-west-1.amazonaws.com" "http://apprunner.us-west-2.amazonaws.com" "http://apprunner.us-gov-west-1.amazonaws.com" "http://apprunner.us-gov-east-1.amazonaws.com" "http://apprunner.ca-central-1.amazonaws.com" "http://apprunner.eu-north-1.amazonaws.com" "http://apprunner.eu-west-1.amazonaws.com" "http://apprunner.eu-west-2.amazonaws.com" "http://apprunner.eu-west-3.amazonaws.com" "http://apprunner.eu-central-1.amazonaws.com" "http://apprunner.eu-south-1.amazonaws.com" "http://apprunner.af-south-1.amazonaws.com" "http://apprunner.ap-northeast-1.amazonaws.com" "http://apprunner.ap-northeast-2.amazonaws.com" "http://apprunner.ap-northeast-3.amazonaws.com" "http://apprunner.ap-southeast-1.amazonaws.com" "http://apprunner.ap-southeast-2.amazonaws.com" "http://apprunner.ap-east-1.amazonaws.com" "http://apprunner.ap-south-1.amazonaws.com" "http://apprunner.sa-east-1.amazonaws.com" "http://apprunner.me-south-1.amazonaws.com" "https://apprunner.us-east-1.amazonaws.com" "https://apprunner.us-east-2.amazonaws.com" "https://apprunner.us-west-1.amazonaws.com" "https://apprunner.us-west-2.amazonaws.com" "https://apprunner.us-gov-west-1.amazonaws.com" "https://apprunner.us-gov-east-1.amazonaws.com" "https://apprunner.ca-central-1.amazonaws.com" "https://apprunner.eu-north-1.amazonaws.com" "https://apprunner.eu-west-1.amazonaws.com" "https://apprunner.eu-west-2.amazonaws.com" "https://apprunner.eu-west-3.amazonaws.com" "https://apprunner.eu-central-1.amazonaws.com" "https://apprunner.eu-south-1.amazonaws.com" "https://apprunner.af-south-1.amazonaws.com" "https://apprunner.ap-northeast-1.amazonaws.com" "https://apprunner.ap-northeast-2.amazonaws.com" "https://apprunner.ap-northeast-3.amazonaws.com" "https://apprunner.ap-southeast-1.amazonaws.com" "https://apprunner.ap-southeast-2.amazonaws.com" "https://apprunner.ap-east-1.amazonaws.com" "https://apprunner.ap-south-1.amazonaws.com" "https://apprunner.sa-east-1.amazonaws.com" "https://apprunner.me-south-1.amazonaws.com" "http://apprunner.cn-north-1.amazonaws.com.cn" "http://apprunner.cn-northwest-1.amazonaws.com.cn" "https://apprunner.cn-north-1.amazonaws.com.cn" "https://apprunner.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def X-Amz-Target-completer [] { ["AppRunner.AssociateCustomDomain"] }
def X-Amz-Target-completer-1 [] { ["AppRunner.CreateAutoScalingConfiguration"] }
def X-Amz-Target-completer-2 [] { ["AppRunner.CreateConnection"] }
def X-Amz-Target-completer-3 [] { ["AppRunner.CreateObservabilityConfiguration"] }
def X-Amz-Target-completer-4 [] { ["AppRunner.CreateService"] }
def X-Amz-Target-completer-5 [] { ["AppRunner.CreateVpcConnector"] }
def X-Amz-Target-completer-6 [] { ["AppRunner.CreateVpcIngressConnection"] }
def X-Amz-Target-completer-7 [] { ["AppRunner.DeleteAutoScalingConfiguration"] }
def X-Amz-Target-completer-8 [] { ["AppRunner.DeleteConnection"] }
def X-Amz-Target-completer-9 [] { ["AppRunner.DeleteObservabilityConfiguration"] }
def X-Amz-Target-completer-10 [] { ["AppRunner.DeleteService"] }
def X-Amz-Target-completer-11 [] { ["AppRunner.DeleteVpcConnector"] }
def X-Amz-Target-completer-12 [] { ["AppRunner.DeleteVpcIngressConnection"] }
def X-Amz-Target-completer-13 [] { ["AppRunner.DescribeAutoScalingConfiguration"] }
def X-Amz-Target-completer-14 [] { ["AppRunner.DescribeCustomDomains"] }
def X-Amz-Target-completer-15 [] { ["AppRunner.DescribeObservabilityConfiguration"] }
def X-Amz-Target-completer-16 [] { ["AppRunner.DescribeService"] }
def X-Amz-Target-completer-17 [] { ["AppRunner.DescribeVpcConnector"] }
def X-Amz-Target-completer-18 [] { ["AppRunner.DescribeVpcIngressConnection"] }
def X-Amz-Target-completer-19 [] { ["AppRunner.DisassociateCustomDomain"] }
def X-Amz-Target-completer-20 [] { ["AppRunner.ListAutoScalingConfigurations"] }
def X-Amz-Target-completer-21 [] { ["AppRunner.ListConnections"] }
def X-Amz-Target-completer-22 [] { ["AppRunner.ListObservabilityConfigurations"] }
def X-Amz-Target-completer-23 [] { ["AppRunner.ListOperations"] }
def X-Amz-Target-completer-24 [] { ["AppRunner.ListServices"] }
def X-Amz-Target-completer-25 [] { ["AppRunner.ListTagsForResource"] }
def X-Amz-Target-completer-26 [] { ["AppRunner.ListVpcConnectors"] }
def X-Amz-Target-completer-27 [] { ["AppRunner.ListVpcIngressConnections"] }
def X-Amz-Target-completer-28 [] { ["AppRunner.PauseService"] }
def X-Amz-Target-completer-29 [] { ["AppRunner.ResumeService"] }
def X-Amz-Target-completer-30 [] { ["AppRunner.StartDeployment"] }
def X-Amz-Target-completer-31 [] { ["AppRunner.TagResource"] }
def X-Amz-Target-completer-32 [] { ["AppRunner.UntagResource"] }
def X-Amz-Target-completer-33 [] { ["AppRunner.UpdateService"] }
def X-Amz-Target-completer-34 [] { ["AppRunner.UpdateVpcIngressConnection"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-app-runner-associate-custom-domain AssociateCustomDomain" } } | get name | first)
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

# <p>Associate your own domain name with the App Runner subdomain URL of your App Runner service.</p> <p>After you call <code>AssociateCustomDomain</code> and receive a successful response, use the information in the <a>CustomDomain</a> record that's returned to add CNAME records to your Domain Name System (DNS). For each mapped domain name, add a mapping to the target App Runner subdomain and one or more certificate validation records. App Runner then performs DNS validation to verify that you own or control the domain name that you associated. App Runner tracks domain validity in a certificate stored in <a href="https://docs.aws.amazon.com/acm/latest/userguide">AWS Certificate Manager (ACM)</a>.</p>
#
# POST /#X-Amz-Target=AppRunner.AssociateCustomDomain
# operationId: AssociateCustomDomain
export def "x-amz-target-app-runner-associate-custom-domain AssociateCustomDomain" [
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
  ServiceArn: any
  DomainName: any
  --EnableWWWSubdomain: any
]: any -> record<DNSTarget: record, ServiceArn: record, CustomDomain: record<DomainName: record, EnableWWWSubdomain: record, CertificateValidationRecords: record, Status: record>, VpcDNSTargets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.AssociateCustomDomain")
  let body = {ServiceArn: $ServiceArn, DomainName: $DomainName, EnableWWWSubdomain: $EnableWWWSubdomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Create an App Runner automatic scaling configuration resource. App Runner requires this resource when you create or update App Runner services and you require non-default auto scaling settings. You can share an auto scaling configuration across multiple services.</p> <p>Create multiple revisions of a configuration by calling this action multiple times using the same <code>AutoScalingConfigurationName</code>. The call returns incremental <code>AutoScalingConfigurationRevision</code> values. When you create a service and configure an auto scaling configuration resource, the service uses the latest active revision of the auto scaling configuration by default. You can optionally configure the service to use a specific revision.</p> <p>Configure a higher <code>MinSize</code> to increase the spread of your App Runner service over more Availability Zones in the Amazon Web Services Region. The tradeoff is a higher minimal cost.</p> <p>Configure a lower <code>MaxSize</code> to control your cost. The tradeoff is lower responsiveness during peak demand.</p>
#
# POST /#X-Amz-Target=AppRunner.CreateAutoScalingConfiguration
# operationId: CreateAutoScalingConfiguration
export def "x-amz-target-app-runner-create-auto-scaling-configuration CreateAutoScalingConfiguration" [
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
  AutoScalingConfigurationName: any
  --MaxConcurrency: any
  --MinSize: any
  --MaxSize: any
  --Tags: any
]: any -> record<AutoScalingConfiguration: record<AutoScalingConfigurationArn: record, AutoScalingConfigurationName: record, AutoScalingConfigurationRevision: record, Latest: record, Status: record, MaxConcurrency: record, MinSize: record, MaxSize: record, CreatedAt: record, DeletedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.CreateAutoScalingConfiguration")
  let body = {AutoScalingConfigurationName: $AutoScalingConfigurationName, MaxConcurrency: $MaxConcurrency, MinSize: $MinSize, MaxSize: $MaxSize, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Create an App Runner connection resource. App Runner requires a connection resource when you create App Runner services that access private repositories from certain third-party providers. You can share a connection across multiple services.</p> <p>A connection resource is needed to access GitHub repositories. GitHub requires a user interface approval process through the App Runner console before you can use the connection.</p>
#
# POST /#X-Amz-Target=AppRunner.CreateConnection
# operationId: CreateConnection
export def "x-amz-target-app-runner-create-connection CreateConnection" [
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
  ConnectionName: any
  ProviderType: any
  --Tags: any
]: any -> record<Connection: record<ConnectionName: record, ConnectionArn: record, ProviderType: record, Status: record, CreatedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.CreateConnection")
  let body = {ConnectionName: $ConnectionName, ProviderType: $ProviderType, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Create an App Runner observability configuration resource. App Runner requires this resource when you create or update App Runner services and you want to enable non-default observability features. You can share an observability configuration across multiple services.</p> <p>Create multiple revisions of a configuration by calling this action multiple times using the same <code>ObservabilityConfigurationName</code>. The call returns incremental <code>ObservabilityConfigurationRevision</code> values. When you create a service and configure an observability configuration resource, the service uses the latest active revision of the observability configuration by default. You can optionally configure the service to use a specific revision.</p> <p>The observability configuration resource is designed to configure multiple features (currently one feature, tracing). This action takes optional parameters that describe the configuration of these features (currently one parameter, <code>TraceConfiguration</code>). If you don't specify a feature parameter, App Runner doesn't enable the feature.</p>
#
# POST /#X-Amz-Target=AppRunner.CreateObservabilityConfiguration
# operationId: CreateObservabilityConfiguration
export def "x-amz-target-app-runner-create-observability-configuration CreateObservabilityConfiguration" [
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
  ObservabilityConfigurationName: any
  --TraceConfiguration: any
  --Tags: any
]: any -> record<ObservabilityConfiguration: record<ObservabilityConfigurationArn: record, ObservabilityConfigurationName: record, TraceConfiguration: record<Vendor: record>, ObservabilityConfigurationRevision: record, Latest: record, Status: record, CreatedAt: record, DeletedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.CreateObservabilityConfiguration")
  let body = {ObservabilityConfigurationName: $ObservabilityConfigurationName, TraceConfiguration: $TraceConfiguration, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Create an App Runner service. After the service is created, the action also automatically starts a deployment.</p> <p>This is an asynchronous operation. On a successful call, you can use the returned <code>OperationId</code> and the <a href="https://docs.aws.amazon.com/apprunner/latest/api/API_ListOperations.html">ListOperations</a> call to track the operation's progress.</p>
#
# POST /#X-Amz-Target=AppRunner.CreateService
# operationId: CreateService
export def "x-amz-target-app-runner-create-service CreateService" [
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
  ServiceName: any
  SourceConfiguration: any
  --InstanceConfiguration: any
  --Tags: any
  --EncryptionConfiguration: any
  --HealthCheckConfiguration: any
  --AutoScalingConfigurationArn: any
  --NetworkConfiguration: any
  --ObservabilityConfiguration: any
]: any -> record<Service: record<ServiceName: record, ServiceId: record, ServiceArn: record, ServiceUrl: record, CreatedAt: record, UpdatedAt: record, DeletedAt: record, Status: record, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: record, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: record, Memory: record, InstanceRoleArn: record>, EncryptionConfiguration: record<KmsKey: record>, HealthCheckConfiguration: record<Protocol: record, Path: record, Interval: record, Timeout: record, HealthyThreshold: record, UnhealthyThreshold: record>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: record, AutoScalingConfigurationName: record, AutoScalingConfigurationRevision: record>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: record, ObservabilityConfigurationArn: record>>, OperationId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.CreateService")
  let body = {ServiceName: $ServiceName, SourceConfiguration: $SourceConfiguration, InstanceConfiguration: $InstanceConfiguration, Tags: $Tags, EncryptionConfiguration: $EncryptionConfiguration, HealthCheckConfiguration: $HealthCheckConfiguration, AutoScalingConfigurationArn: $AutoScalingConfigurationArn, NetworkConfiguration: $NetworkConfiguration, ObservabilityConfiguration: $ObservabilityConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an App Runner VPC connector resource. App Runner requires this resource when you want to associate your App Runner service to a custom Amazon Virtual Private Cloud (Amazon VPC).
#
# POST /#X-Amz-Target=AppRunner.CreateVpcConnector
# operationId: CreateVpcConnector
export def "x-amz-target-app-runner-create-vpc-connector CreateVpcConnector" [
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
  VpcConnectorName: any
  Subnets: any
  --SecurityGroups: any
  --Tags: any
]: any -> record<VpcConnector: record<VpcConnectorName: record, VpcConnectorArn: record, VpcConnectorRevision: record, Subnets: record, SecurityGroups: record, Status: record, CreatedAt: record, DeletedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.CreateVpcConnector")
  let body = {VpcConnectorName: $VpcConnectorName, Subnets: $Subnets, SecurityGroups: $SecurityGroups, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an App Runner VPC Ingress Connection resource. App Runner requires this resource when you want to associate your App Runner service with an Amazon VPC endpoint.
#
# POST /#X-Amz-Target=AppRunner.CreateVpcIngressConnection
# operationId: CreateVpcIngressConnection
export def "x-amz-target-app-runner-create-vpc-ingress-connection CreateVpcIngressConnection" [
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
  ServiceArn: any
  VpcIngressConnectionName: any
  IngressVpcConfiguration: any
  --Tags: any
]: any -> record<VpcIngressConnection: record<VpcIngressConnectionArn: record, VpcIngressConnectionName: record, ServiceArn: record, Status: record, AccountId: record, DomainName: record, IngressVpcConfiguration: record<VpcId: record, VpcEndpointId: record>, CreatedAt: record, DeletedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.CreateVpcIngressConnection")
  let body = {ServiceArn: $ServiceArn, VpcIngressConnectionName: $VpcIngressConnectionName, IngressVpcConfiguration: $IngressVpcConfiguration, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an App Runner automatic scaling configuration resource. You can delete a specific revision or the latest active revision. You can't delete a configuration that's used by one or more App Runner services.
#
# POST /#X-Amz-Target=AppRunner.DeleteAutoScalingConfiguration
# operationId: DeleteAutoScalingConfiguration
export def "x-amz-target-app-runner-delete-auto-scaling-configuration DeleteAutoScalingConfiguration" [
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
  AutoScalingConfigurationArn: any
]: any -> record<AutoScalingConfiguration: record<AutoScalingConfigurationArn: record, AutoScalingConfigurationName: record, AutoScalingConfigurationRevision: record, Latest: record, Status: record, MaxConcurrency: record, MinSize: record, MaxSize: record, CreatedAt: record, DeletedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.DeleteAutoScalingConfiguration")
  let body = {AutoScalingConfigurationArn: $AutoScalingConfigurationArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an App Runner connection. You must first ensure that there are no running App Runner services that use this connection. If there are any, the <code>DeleteConnection</code> action fails.
#
# POST /#X-Amz-Target=AppRunner.DeleteConnection
# operationId: DeleteConnection
export def "x-amz-target-app-runner-delete-connection DeleteConnection" [
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
  ConnectionArn: any
]: any -> record<Connection: record<ConnectionName: record, ConnectionArn: record, ProviderType: record, Status: record, CreatedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.DeleteConnection")
  let body = {ConnectionArn: $ConnectionArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an App Runner observability configuration resource. You can delete a specific revision or the latest active revision. You can't delete a configuration that's used by one or more App Runner services.
#
# POST /#X-Amz-Target=AppRunner.DeleteObservabilityConfiguration
# operationId: DeleteObservabilityConfiguration
export def "x-amz-target-app-runner-delete-observability-configuration DeleteObservabilityConfiguration" [
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
  ObservabilityConfigurationArn: any
]: any -> record<ObservabilityConfiguration: record<ObservabilityConfigurationArn: record, ObservabilityConfigurationName: record, TraceConfiguration: record<Vendor: record>, ObservabilityConfigurationRevision: record, Latest: record, Status: record, CreatedAt: record, DeletedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.DeleteObservabilityConfiguration")
  let body = {ObservabilityConfigurationArn: $ObservabilityConfigurationArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Delete an App Runner service.</p> <p>This is an asynchronous operation. On a successful call, you can use the returned <code>OperationId</code> and the <a>ListOperations</a> call to track the operation's progress.</p> <note> <p>Make sure that you don't have any active VPCIngressConnections associated with the service you want to delete. </p> </note>
#
# POST /#X-Amz-Target=AppRunner.DeleteService
# operationId: DeleteService
export def "x-amz-target-app-runner-delete-service DeleteService" [
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
  ServiceArn: any
]: any -> record<Service: record<ServiceName: record, ServiceId: record, ServiceArn: record, ServiceUrl: record, CreatedAt: record, UpdatedAt: record, DeletedAt: record, Status: record, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: record, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: record, Memory: record, InstanceRoleArn: record>, EncryptionConfiguration: record<KmsKey: record>, HealthCheckConfiguration: record<Protocol: record, Path: record, Interval: record, Timeout: record, HealthyThreshold: record, UnhealthyThreshold: record>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: record, AutoScalingConfigurationName: record, AutoScalingConfigurationRevision: record>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: record, ObservabilityConfigurationArn: record>>, OperationId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.DeleteService")
  let body = {ServiceArn: $ServiceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an App Runner VPC connector resource. You can't delete a connector that's used by one or more App Runner services.
#
# POST /#X-Amz-Target=AppRunner.DeleteVpcConnector
# operationId: DeleteVpcConnector
export def "x-amz-target-app-runner-delete-vpc-connector DeleteVpcConnector" [
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
  VpcConnectorArn: any
]: any -> record<VpcConnector: record<VpcConnectorName: record, VpcConnectorArn: record, VpcConnectorRevision: record, Subnets: record, SecurityGroups: record, Status: record, CreatedAt: record, DeletedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.DeleteVpcConnector")
  let body = {VpcConnectorArn: $VpcConnectorArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Delete an App Runner VPC Ingress Connection resource that's associated with an App Runner service. The VPC Ingress Connection must be in one of the following states to be deleted: </p> <ul> <li> <p> <code>AVAILABLE</code> </p> </li> <li> <p> <code>FAILED_CREATION</code> </p> </li> <li> <p> <code>FAILED_UPDATE</code> </p> </li> <li> <p> <code>FAILED_DELETION</code> </p> </li> </ul>
#
# POST /#X-Amz-Target=AppRunner.DeleteVpcIngressConnection
# operationId: DeleteVpcIngressConnection
export def "x-amz-target-app-runner-delete-vpc-ingress-connection DeleteVpcIngressConnection" [
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
  VpcIngressConnectionArn: any
]: any -> record<VpcIngressConnection: record<VpcIngressConnectionArn: record, VpcIngressConnectionName: record, ServiceArn: record, Status: record, AccountId: record, DomainName: record, IngressVpcConfiguration: record<VpcId: record, VpcEndpointId: record>, CreatedAt: record, DeletedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.DeleteVpcIngressConnection")
  let body = {VpcIngressConnectionArn: $VpcIngressConnectionArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a full description of an App Runner automatic scaling configuration resource.
#
# POST /#X-Amz-Target=AppRunner.DescribeAutoScalingConfiguration
# operationId: DescribeAutoScalingConfiguration
export def "x-amz-target-app-runner-describe-auto-scaling-configuration DescribeAutoScalingConfiguration" [
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
  AutoScalingConfigurationArn: any
]: any -> record<AutoScalingConfiguration: record<AutoScalingConfigurationArn: record, AutoScalingConfigurationName: record, AutoScalingConfigurationRevision: record, Latest: record, Status: record, MaxConcurrency: record, MinSize: record, MaxSize: record, CreatedAt: record, DeletedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.DescribeAutoScalingConfiguration")
  let body = {AutoScalingConfigurationArn: $AutoScalingConfigurationArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a description of custom domain names that are associated with an App Runner service.
#
# POST /#X-Amz-Target=AppRunner.DescribeCustomDomains
# operationId: DescribeCustomDomains
export def "x-amz-target-app-runner-describe-custom-domains DescribeCustomDomains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-14
  ServiceArn: any
  --NextToken: any
  --MaxResults: any
]: any -> record<DNSTarget: record, ServiceArn: record, CustomDomains: record, VpcDNSTargets: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.DescribeCustomDomains" $qp)
  let body = {ServiceArn: $ServiceArn, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a full description of an App Runner observability configuration resource.
#
# POST /#X-Amz-Target=AppRunner.DescribeObservabilityConfiguration
# operationId: DescribeObservabilityConfiguration
export def "x-amz-target-app-runner-describe-observability-configuration DescribeObservabilityConfiguration" [
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
  ObservabilityConfigurationArn: any
]: any -> record<ObservabilityConfiguration: record<ObservabilityConfigurationArn: record, ObservabilityConfigurationName: record, TraceConfiguration: record<Vendor: record>, ObservabilityConfigurationRevision: record, Latest: record, Status: record, CreatedAt: record, DeletedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.DescribeObservabilityConfiguration")
  let body = {ObservabilityConfigurationArn: $ObservabilityConfigurationArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a full description of an App Runner service.
#
# POST /#X-Amz-Target=AppRunner.DescribeService
# operationId: DescribeService
export def "x-amz-target-app-runner-describe-service DescribeService" [
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
  ServiceArn: any
]: any -> record<Service: record<ServiceName: record, ServiceId: record, ServiceArn: record, ServiceUrl: record, CreatedAt: record, UpdatedAt: record, DeletedAt: record, Status: record, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: record, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: record, Memory: record, InstanceRoleArn: record>, EncryptionConfiguration: record<KmsKey: record>, HealthCheckConfiguration: record<Protocol: record, Path: record, Interval: record, Timeout: record, HealthyThreshold: record, UnhealthyThreshold: record>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: record, AutoScalingConfigurationName: record, AutoScalingConfigurationRevision: record>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: record, ObservabilityConfigurationArn: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.DescribeService")
  let body = {ServiceArn: $ServiceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a description of an App Runner VPC connector resource.
#
# POST /#X-Amz-Target=AppRunner.DescribeVpcConnector
# operationId: DescribeVpcConnector
export def "x-amz-target-app-runner-describe-vpc-connector DescribeVpcConnector" [
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
  VpcConnectorArn: any
]: any -> record<VpcConnector: record<VpcConnectorName: record, VpcConnectorArn: record, VpcConnectorRevision: record, Subnets: record, SecurityGroups: record, Status: record, CreatedAt: record, DeletedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.DescribeVpcConnector")
  let body = {VpcConnectorArn: $VpcConnectorArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a full description of an App Runner VPC Ingress Connection resource.
#
# POST /#X-Amz-Target=AppRunner.DescribeVpcIngressConnection
# operationId: DescribeVpcIngressConnection
export def "x-amz-target-app-runner-describe-vpc-ingress-connection DescribeVpcIngressConnection" [
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
  VpcIngressConnectionArn: any
]: any -> record<VpcIngressConnection: record<VpcIngressConnectionArn: record, VpcIngressConnectionName: record, ServiceArn: record, Status: record, AccountId: record, DomainName: record, IngressVpcConfiguration: record<VpcId: record, VpcEndpointId: record>, CreatedAt: record, DeletedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.DescribeVpcIngressConnection")
  let body = {VpcIngressConnectionArn: $VpcIngressConnectionArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Disassociate a custom domain name from an App Runner service.</p> <p>Certificates tracking domain validity are associated with a custom domain and are stored in <a href="https://docs.aws.amazon.com/acm/latest/userguide">AWS Certificate Manager (ACM)</a>. These certificates aren't deleted as part of this action. App Runner delays certificate deletion for 30 days after a domain is disassociated from your service.</p>
#
# POST /#X-Amz-Target=AppRunner.DisassociateCustomDomain
# operationId: DisassociateCustomDomain
export def "x-amz-target-app-runner-disassociate-custom-domain DisassociateCustomDomain" [
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
  ServiceArn: any
  DomainName: any
]: any -> record<DNSTarget: record, ServiceArn: record, CustomDomain: record<DomainName: record, EnableWWWSubdomain: record, CertificateValidationRecords: record, Status: record>, VpcDNSTargets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.DisassociateCustomDomain")
  let body = {ServiceArn: $ServiceArn, DomainName: $DomainName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Returns a list of active App Runner automatic scaling configurations in your Amazon Web Services account. You can query the revisions for a specific configuration name or the revisions for all active configurations in your account. You can optionally query only the latest revision of each requested name.</p> <p>To retrieve a full description of a particular configuration revision, call and provide one of the ARNs returned by <code>ListAutoScalingConfigurations</code>.</p>
#
# POST /#X-Amz-Target=AppRunner.ListAutoScalingConfigurations
# operationId: ListAutoScalingConfigurations
export def "x-amz-target-app-runner-list-auto-scaling-configurations ListAutoScalingConfigurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-20
  --AutoScalingConfigurationName: any
  --LatestOnly: any
  --MaxResults: any
  --NextToken: any
]: any -> record<AutoScalingConfigurationSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.ListAutoScalingConfigurations" $qp)
  let body = {AutoScalingConfigurationName: $AutoScalingConfigurationName, LatestOnly: $LatestOnly, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of App Runner connections that are associated with your Amazon Web Services account.
#
# POST /#X-Amz-Target=AppRunner.ListConnections
# operationId: ListConnections
export def "x-amz-target-app-runner-list-connections ListConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-21
  --ConnectionName: any
  --MaxResults: any
  --NextToken: any
]: any -> record<ConnectionSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.ListConnections" $qp)
  let body = {ConnectionName: $ConnectionName, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Returns a list of active App Runner observability configurations in your Amazon Web Services account. You can query the revisions for a specific configuration name or the revisions for all active configurations in your account. You can optionally query only the latest revision of each requested name.</p> <p>To retrieve a full description of a particular configuration revision, call and provide one of the ARNs returned by <code>ListObservabilityConfigurations</code>.</p>
#
# POST /#X-Amz-Target=AppRunner.ListObservabilityConfigurations
# operationId: ListObservabilityConfigurations
export def "x-amz-target-app-runner-list-observability-configurations ListObservabilityConfigurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-22
  --ObservabilityConfigurationName: any
  --LatestOnly: any
  --MaxResults: any
  --NextToken: any
]: any -> record<ObservabilityConfigurationSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.ListObservabilityConfigurations" $qp)
  let body = {ObservabilityConfigurationName: $ObservabilityConfigurationName, LatestOnly: $LatestOnly, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Return a list of operations that occurred on an App Runner service.</p> <p>The resulting list of <a>OperationSummary</a> objects is sorted in reverse chronological order. The first object on the list represents the last started operation.</p>
#
# POST /#X-Amz-Target=AppRunner.ListOperations
# operationId: ListOperations
export def "x-amz-target-app-runner-list-operations ListOperations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-23
  ServiceArn: any
  --NextToken: any
  --MaxResults: any
]: any -> record<OperationSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.ListOperations" $qp)
  let body = {ServiceArn: $ServiceArn, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of running App Runner services in your Amazon Web Services account.
#
# POST /#X-Amz-Target=AppRunner.ListServices
# operationId: ListServices
export def "x-amz-target-app-runner-list-services ListServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-24
  --NextToken: any
  --MaxResults: any
]: any -> record<ServiceSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.ListServices" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List tags that are associated with for an App Runner resource. The response contains a list of tag key-value pairs.
#
# POST /#X-Amz-Target=AppRunner.ListTagsForResource
# operationId: ListTagsForResource
export def "x-amz-target-app-runner-list-tags-for-resource ListTagsForResource" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-25
  ResourceArn: any
]: any -> record<Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.ListTagsForResource")
  let body = {ResourceArn: $ResourceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of App Runner VPC connectors in your Amazon Web Services account.
#
# POST /#X-Amz-Target=AppRunner.ListVpcConnectors
# operationId: ListVpcConnectors
export def "x-amz-target-app-runner-list-vpc-connectors ListVpcConnectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-26
  --MaxResults: any
  --NextToken: any
]: any -> record<VpcConnectors: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.ListVpcConnectors" $qp)
  let body = {MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a list of App Runner VPC Ingress Connections in your Amazon Web Services account.
#
# POST /#X-Amz-Target=AppRunner.ListVpcIngressConnections
# operationId: ListVpcIngressConnections
export def "x-amz-target-app-runner-list-vpc-ingress-connections ListVpcIngressConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-27
  --Filter: any
  --MaxResults: any
  --NextToken: any
]: any -> record<VpcIngressConnectionSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.ListVpcIngressConnections" $qp)
  let body = {Filter: $Filter, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Pause an active App Runner service. App Runner reduces compute capacity for the service to zero and loses state (for example, ephemeral storage is removed).</p> <p>This is an asynchronous operation. On a successful call, you can use the returned <code>OperationId</code> and the <a>ListOperations</a> call to track the operation's progress.</p>
#
# POST /#X-Amz-Target=AppRunner.PauseService
# operationId: PauseService
export def "x-amz-target-app-runner-pause-service PauseService" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-28
  ServiceArn: any
]: any -> record<Service: record<ServiceName: record, ServiceId: record, ServiceArn: record, ServiceUrl: record, CreatedAt: record, UpdatedAt: record, DeletedAt: record, Status: record, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: record, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: record, Memory: record, InstanceRoleArn: record>, EncryptionConfiguration: record<KmsKey: record>, HealthCheckConfiguration: record<Protocol: record, Path: record, Interval: record, Timeout: record, HealthyThreshold: record, UnhealthyThreshold: record>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: record, AutoScalingConfigurationName: record, AutoScalingConfigurationRevision: record>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: record, ObservabilityConfigurationArn: record>>, OperationId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.PauseService")
  let body = {ServiceArn: $ServiceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Resume an active App Runner service. App Runner provisions compute capacity for the service.</p> <p>This is an asynchronous operation. On a successful call, you can use the returned <code>OperationId</code> and the <a>ListOperations</a> call to track the operation's progress.</p>
#
# POST /#X-Amz-Target=AppRunner.ResumeService
# operationId: ResumeService
export def "x-amz-target-app-runner-resume-service ResumeService" [
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
  ServiceArn: any
]: any -> record<Service: record<ServiceName: record, ServiceId: record, ServiceArn: record, ServiceUrl: record, CreatedAt: record, UpdatedAt: record, DeletedAt: record, Status: record, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: record, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: record, Memory: record, InstanceRoleArn: record>, EncryptionConfiguration: record<KmsKey: record>, HealthCheckConfiguration: record<Protocol: record, Path: record, Interval: record, Timeout: record, HealthyThreshold: record, UnhealthyThreshold: record>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: record, AutoScalingConfigurationName: record, AutoScalingConfigurationRevision: record>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: record, ObservabilityConfigurationArn: record>>, OperationId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.ResumeService")
  let body = {ServiceArn: $ServiceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Initiate a manual deployment of the latest commit in a source code repository or the latest image in a source image repository to an App Runner service.</p> <p>For a source code repository, App Runner retrieves the commit and builds a Docker image. For a source image repository, App Runner retrieves the latest Docker image. In both cases, App Runner then deploys the new image to your service and starts a new container instance.</p> <p>This is an asynchronous operation. On a successful call, you can use the returned <code>OperationId</code> and the <a>ListOperations</a> call to track the operation's progress.</p>
#
# POST /#X-Amz-Target=AppRunner.StartDeployment
# operationId: StartDeployment
export def "x-amz-target-app-runner-start-deployment StartDeployment" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-30
  ServiceArn: any
]: any -> record<OperationId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.StartDeployment")
  let body = {ServiceArn: $ServiceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add tags to, or update the tag values of, an App Runner resource. A tag is a key-value pair.
#
# POST /#X-Amz-Target=AppRunner.TagResource
# operationId: TagResource
export def "x-amz-target-app-runner-tag-resource TagResource" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-31
  ResourceArn: any
  Tags: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.TagResource")
  let body = {ResourceArn: $ResourceArn, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove tags from an App Runner resource.
#
# POST /#X-Amz-Target=AppRunner.UntagResource
# operationId: UntagResource
export def "x-amz-target-app-runner-untag-resource UntagResource" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-32
  ResourceArn: any
  TagKeys: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.UntagResource")
  let body = {ResourceArn: $ResourceArn, TagKeys: $TagKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Update an App Runner service. You can update the source configuration and instance configuration of the service. You can also update the ARN of the auto scaling configuration resource that's associated with the service. However, you can't change the name or the encryption configuration of the service. These can be set only when you create the service.</p> <p>To update the tags applied to your service, use the separate actions <a>TagResource</a> and <a>UntagResource</a>.</p> <p>This is an asynchronous operation. On a successful call, you can use the returned <code>OperationId</code> and the <a>ListOperations</a> call to track the operation's progress.</p>
#
# POST /#X-Amz-Target=AppRunner.UpdateService
# operationId: UpdateService
export def "x-amz-target-app-runner-update-service UpdateService" [
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
  ServiceArn: any
  --SourceConfiguration: any
  --InstanceConfiguration: any
  --AutoScalingConfigurationArn: any
  --HealthCheckConfiguration: any
  --NetworkConfiguration: any
  --ObservabilityConfiguration: any
]: any -> record<Service: record<ServiceName: record, ServiceId: record, ServiceArn: record, ServiceUrl: record, CreatedAt: record, UpdatedAt: record, DeletedAt: record, Status: record, SourceConfiguration: record<CodeRepository: record, ImageRepository: record, AutoDeploymentsEnabled: record, AuthenticationConfiguration: record>, InstanceConfiguration: record<Cpu: record, Memory: record, InstanceRoleArn: record>, EncryptionConfiguration: record<KmsKey: record>, HealthCheckConfiguration: record<Protocol: record, Path: record, Interval: record, Timeout: record, HealthyThreshold: record, UnhealthyThreshold: record>, AutoScalingConfigurationSummary: record<AutoScalingConfigurationArn: record, AutoScalingConfigurationName: record, AutoScalingConfigurationRevision: record>, NetworkConfiguration: record<EgressConfiguration: record, IngressConfiguration: record>, ObservabilityConfiguration: record<ObservabilityEnabled: record, ObservabilityConfigurationArn: record>>, OperationId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.UpdateService")
  let body = {ServiceArn: $ServiceArn, SourceConfiguration: $SourceConfiguration, InstanceConfiguration: $InstanceConfiguration, AutoScalingConfigurationArn: $AutoScalingConfigurationArn, HealthCheckConfiguration: $HealthCheckConfiguration, NetworkConfiguration: $NetworkConfiguration, ObservabilityConfiguration: $ObservabilityConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Update an existing App Runner VPC Ingress Connection resource. The VPC Ingress Connection must be in one of the following states to be updated:</p> <ul> <li> <p> AVAILABLE </p> </li> <li> <p> FAILED_CREATION </p> </li> <li> <p> FAILED_UPDATE </p> </li> </ul>
#
# POST /#X-Amz-Target=AppRunner.UpdateVpcIngressConnection
# operationId: UpdateVpcIngressConnection
export def "x-amz-target-app-runner-update-vpc-ingress-connection UpdateVpcIngressConnection" [
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
  VpcIngressConnectionArn: any
  IngressVpcConfiguration: any
]: any -> record<VpcIngressConnection: record<VpcIngressConnectionArn: record, VpcIngressConnectionName: record, ServiceArn: record, Status: record, AccountId: record, DomainName: record, IngressVpcConfiguration: record<VpcId: record, VpcEndpointId: record>, CreatedAt: record, DeletedAt: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AppRunner.UpdateVpcIngressConnection")
  let body = {VpcIngressConnectionArn: $VpcIngressConnectionArn, IngressVpcConfiguration: $IngressVpcConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
