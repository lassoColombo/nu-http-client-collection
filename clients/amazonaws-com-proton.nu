# Auto-generated client for AWS Proton v2020-07-20
# Source: https://api.apis.guru/v2/specs/amazonaws.com/proton/2020-07-20/openapi.json
# Auth: --token flag or $env.AWS_PROTON_TOKEN

const BASE_URL = "http://proton.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_PROTON_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://proton.us-east-1.amazonaws.com" "http://proton.us-east-2.amazonaws.com" "http://proton.us-west-1.amazonaws.com" "http://proton.us-west-2.amazonaws.com" "http://proton.us-gov-west-1.amazonaws.com" "http://proton.us-gov-east-1.amazonaws.com" "http://proton.ca-central-1.amazonaws.com" "http://proton.eu-north-1.amazonaws.com" "http://proton.eu-west-1.amazonaws.com" "http://proton.eu-west-2.amazonaws.com" "http://proton.eu-west-3.amazonaws.com" "http://proton.eu-central-1.amazonaws.com" "http://proton.eu-south-1.amazonaws.com" "http://proton.af-south-1.amazonaws.com" "http://proton.ap-northeast-1.amazonaws.com" "http://proton.ap-northeast-2.amazonaws.com" "http://proton.ap-northeast-3.amazonaws.com" "http://proton.ap-southeast-1.amazonaws.com" "http://proton.ap-southeast-2.amazonaws.com" "http://proton.ap-east-1.amazonaws.com" "http://proton.ap-south-1.amazonaws.com" "http://proton.sa-east-1.amazonaws.com" "http://proton.me-south-1.amazonaws.com" "https://proton.us-east-1.amazonaws.com" "https://proton.us-east-2.amazonaws.com" "https://proton.us-west-1.amazonaws.com" "https://proton.us-west-2.amazonaws.com" "https://proton.us-gov-west-1.amazonaws.com" "https://proton.us-gov-east-1.amazonaws.com" "https://proton.ca-central-1.amazonaws.com" "https://proton.eu-north-1.amazonaws.com" "https://proton.eu-west-1.amazonaws.com" "https://proton.eu-west-2.amazonaws.com" "https://proton.eu-west-3.amazonaws.com" "https://proton.eu-central-1.amazonaws.com" "https://proton.eu-south-1.amazonaws.com" "https://proton.af-south-1.amazonaws.com" "https://proton.ap-northeast-1.amazonaws.com" "https://proton.ap-northeast-2.amazonaws.com" "https://proton.ap-northeast-3.amazonaws.com" "https://proton.ap-southeast-1.amazonaws.com" "https://proton.ap-southeast-2.amazonaws.com" "https://proton.ap-east-1.amazonaws.com" "https://proton.ap-south-1.amazonaws.com" "https://proton.sa-east-1.amazonaws.com" "https://proton.me-south-1.amazonaws.com" "http://proton.cn-north-1.amazonaws.com.cn" "http://proton.cn-northwest-1.amazonaws.com.cn" "https://proton.cn-north-1.amazonaws.com.cn" "https://proton.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AwsProton20200720.AcceptEnvironmentAccountConnection"] }
def x-amz-target-completer-1 [] { ["AwsProton20200720.CancelComponentDeployment"] }
def x-amz-target-completer-2 [] { ["AwsProton20200720.CancelEnvironmentDeployment"] }
def x-amz-target-completer-3 [] { ["AwsProton20200720.CancelServiceInstanceDeployment"] }
def x-amz-target-completer-4 [] { ["AwsProton20200720.CancelServicePipelineDeployment"] }
def x-amz-target-completer-5 [] { ["AwsProton20200720.CreateComponent"] }
def x-amz-target-completer-6 [] { ["AwsProton20200720.CreateEnvironment"] }
def x-amz-target-completer-7 [] { ["AwsProton20200720.CreateEnvironmentAccountConnection"] }
def provisioning-completer [] { ["CUSTOMER_MANAGED"] }
def x-amz-target-completer-8 [] { ["AwsProton20200720.CreateEnvironmentTemplate"] }
def x-amz-target-completer-9 [] { ["AwsProton20200720.CreateEnvironmentTemplateVersion"] }
def provider-completer [] { ["BITBUCKET" "GITHUB" "GITHUB_ENTERPRISE"] }
def x-amz-target-completer-10 [] { ["AwsProton20200720.CreateRepository"] }
def x-amz-target-completer-11 [] { ["AwsProton20200720.CreateService"] }
def x-amz-target-completer-12 [] { ["AwsProton20200720.CreateServiceInstance"] }
def repository-provider-completer [] { ["BITBUCKET" "GITHUB" "GITHUB_ENTERPRISE"] }
def x-amz-target-completer-13 [] { ["AwsProton20200720.CreateServiceSyncConfig"] }
def pipeline-provisioning-completer [] { ["CUSTOMER_MANAGED"] }
def x-amz-target-completer-14 [] { ["AwsProton20200720.CreateServiceTemplate"] }
def x-amz-target-completer-15 [] { ["AwsProton20200720.CreateServiceTemplateVersion"] }
def template-type-completer [] { ["ENVIRONMENT" "SERVICE"] }
def x-amz-target-completer-16 [] { ["AwsProton20200720.CreateTemplateSyncConfig"] }
def x-amz-target-completer-17 [] { ["AwsProton20200720.DeleteComponent"] }
def x-amz-target-completer-18 [] { ["AwsProton20200720.DeleteEnvironment"] }
def x-amz-target-completer-19 [] { ["AwsProton20200720.DeleteEnvironmentAccountConnection"] }
def x-amz-target-completer-20 [] { ["AwsProton20200720.DeleteEnvironmentTemplate"] }
def x-amz-target-completer-21 [] { ["AwsProton20200720.DeleteEnvironmentTemplateVersion"] }
def x-amz-target-completer-22 [] { ["AwsProton20200720.DeleteRepository"] }
def x-amz-target-completer-23 [] { ["AwsProton20200720.DeleteService"] }
def x-amz-target-completer-24 [] { ["AwsProton20200720.DeleteServiceSyncConfig"] }
def x-amz-target-completer-25 [] { ["AwsProton20200720.DeleteServiceTemplate"] }
def x-amz-target-completer-26 [] { ["AwsProton20200720.DeleteServiceTemplateVersion"] }
def x-amz-target-completer-27 [] { ["AwsProton20200720.DeleteTemplateSyncConfig"] }
def x-amz-target-completer-28 [] { ["AwsProton20200720.GetAccountSettings"] }
def x-amz-target-completer-29 [] { ["AwsProton20200720.GetComponent"] }
def x-amz-target-completer-30 [] { ["AwsProton20200720.GetEnvironment"] }
def x-amz-target-completer-31 [] { ["AwsProton20200720.GetEnvironmentAccountConnection"] }
def x-amz-target-completer-32 [] { ["AwsProton20200720.GetEnvironmentTemplate"] }
def x-amz-target-completer-33 [] { ["AwsProton20200720.GetEnvironmentTemplateVersion"] }
def x-amz-target-completer-34 [] { ["AwsProton20200720.GetRepository"] }
def sync-type-completer [] { ["SERVICE_SYNC" "TEMPLATE_SYNC"] }
def x-amz-target-completer-35 [] { ["AwsProton20200720.GetRepositorySyncStatus"] }
def x-amz-target-completer-36 [] { ["AwsProton20200720.GetResourcesSummary"] }
def x-amz-target-completer-37 [] { ["AwsProton20200720.GetService"] }
def x-amz-target-completer-38 [] { ["AwsProton20200720.GetServiceInstance"] }
def x-amz-target-completer-39 [] { ["AwsProton20200720.GetServiceInstanceSyncStatus"] }
def x-amz-target-completer-40 [] { ["AwsProton20200720.GetServiceSyncBlockerSummary"] }
def x-amz-target-completer-41 [] { ["AwsProton20200720.GetServiceSyncConfig"] }
def x-amz-target-completer-42 [] { ["AwsProton20200720.GetServiceTemplate"] }
def x-amz-target-completer-43 [] { ["AwsProton20200720.GetServiceTemplateVersion"] }
def x-amz-target-completer-44 [] { ["AwsProton20200720.GetTemplateSyncConfig"] }
def x-amz-target-completer-45 [] { ["AwsProton20200720.GetTemplateSyncStatus"] }
def x-amz-target-completer-46 [] { ["AwsProton20200720.ListComponentOutputs"] }
def x-amz-target-completer-47 [] { ["AwsProton20200720.ListComponentProvisionedResources"] }
def x-amz-target-completer-48 [] { ["AwsProton20200720.ListComponents"] }
def requested-by-completer [] { ["ENVIRONMENT_ACCOUNT" "MANAGEMENT_ACCOUNT"] }
def x-amz-target-completer-49 [] { ["AwsProton20200720.ListEnvironmentAccountConnections"] }
def x-amz-target-completer-50 [] { ["AwsProton20200720.ListEnvironmentOutputs"] }
def x-amz-target-completer-51 [] { ["AwsProton20200720.ListEnvironmentProvisionedResources"] }
def x-amz-target-completer-52 [] { ["AwsProton20200720.ListEnvironmentTemplateVersions"] }
def x-amz-target-completer-53 [] { ["AwsProton20200720.ListEnvironmentTemplates"] }
def x-amz-target-completer-54 [] { ["AwsProton20200720.ListEnvironments"] }
def x-amz-target-completer-55 [] { ["AwsProton20200720.ListRepositories"] }
def x-amz-target-completer-56 [] { ["AwsProton20200720.ListRepositorySyncDefinitions"] }
def x-amz-target-completer-57 [] { ["AwsProton20200720.ListServiceInstanceOutputs"] }
def x-amz-target-completer-58 [] { ["AwsProton20200720.ListServiceInstanceProvisionedResources"] }
def sort-by-completer [] { ["createdAt" "deploymentStatus" "environmentName" "lastDeploymentAttemptedAt" "name" "serviceName" "templateName"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def x-amz-target-completer-59 [] { ["AwsProton20200720.ListServiceInstances"] }
def x-amz-target-completer-60 [] { ["AwsProton20200720.ListServicePipelineOutputs"] }
def x-amz-target-completer-61 [] { ["AwsProton20200720.ListServicePipelineProvisionedResources"] }
def x-amz-target-completer-62 [] { ["AwsProton20200720.ListServiceTemplateVersions"] }
def x-amz-target-completer-63 [] { ["AwsProton20200720.ListServiceTemplates"] }
def x-amz-target-completer-64 [] { ["AwsProton20200720.ListServices"] }
def x-amz-target-completer-65 [] { ["AwsProton20200720.ListTagsForResource"] }
def status-completer [] { ["FAILED" "IN_PROGRESS" "SUCCEEDED"] }
def x-amz-target-completer-66 [] { ["AwsProton20200720.NotifyResourceDeploymentStatusChange"] }
def x-amz-target-completer-67 [] { ["AwsProton20200720.RejectEnvironmentAccountConnection"] }
def x-amz-target-completer-68 [] { ["AwsProton20200720.TagResource"] }
def x-amz-target-completer-69 [] { ["AwsProton20200720.UntagResource"] }
def x-amz-target-completer-70 [] { ["AwsProton20200720.UpdateAccountSettings"] }
def deployment-type-completer [] { ["CURRENT_VERSION" "NONE"] }
def x-amz-target-completer-71 [] { ["AwsProton20200720.UpdateComponent"] }
def deployment-type-completer-1 [] { ["CURRENT_VERSION" "MAJOR_VERSION" "MINOR_VERSION" "NONE"] }
def x-amz-target-completer-72 [] { ["AwsProton20200720.UpdateEnvironment"] }
def x-amz-target-completer-73 [] { ["AwsProton20200720.UpdateEnvironmentAccountConnection"] }
def x-amz-target-completer-74 [] { ["AwsProton20200720.UpdateEnvironmentTemplate"] }
def status-completer-1 [] { ["DRAFT" "PUBLISHED" "REGISTRATION_FAILED" "REGISTRATION_IN_PROGRESS"] }
def x-amz-target-completer-75 [] { ["AwsProton20200720.UpdateEnvironmentTemplateVersion"] }
def x-amz-target-completer-76 [] { ["AwsProton20200720.UpdateService"] }
def x-amz-target-completer-77 [] { ["AwsProton20200720.UpdateServiceInstance"] }
def x-amz-target-completer-78 [] { ["AwsProton20200720.UpdateServicePipeline"] }
def x-amz-target-completer-79 [] { ["AwsProton20200720.UpdateServiceSyncBlocker"] }
def x-amz-target-completer-80 [] { ["AwsProton20200720.UpdateServiceSyncConfig"] }
def x-amz-target-completer-81 [] { ["AwsProton20200720.UpdateServiceTemplate"] }
def x-amz-target-completer-82 [] { ["AwsProton20200720.UpdateServiceTemplateVersion"] }
def x-amz-target-completer-83 [] { ["AwsProton20200720.UpdateTemplateSyncConfig"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accept-environment-account-connection" } } | get name | first)
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

# In a management account, an environment account connection request is accepted. When the environment account connection request is accepted, Proton can use the associated IAM role to provision environment infrastructure resources in the associated environment account. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# operationId: AcceptEnvironmentAccountConnection
export def "accept-environment-account-connection" [
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
  --x-amz-target: string@x-amz-target-completer # required
  id: string # The ID of the environment account connection.
]: any -> record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.AcceptEnvironmentAccountConnection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Attempts to cancel a component deployment (for a component that is in the IN_PROGRESS deployment status). For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# operationId: CancelComponentDeployment
export def "cancel-component-deployment" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  component_name: string # The name of the component with the deployment to cancel.
]: any -> record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CancelComponentDeployment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"componentName": $component_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Attempts to cancel an environment deployment on an UpdateEnvironment action, if the deployment is IN_PROGRESS. For more information, see Update an environment (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-update.html) in the Proton User guide. The following list includes potential cancellation scenarios. If the cancellation attempt succeeds, the resulting deployment state is CANCELLED. If the cancellation attempt fails, the resulting deployment state is FAILED. If the current UpdateEnvironment action succeeds before the cancellation attempt starts, the resulting deployment state is SUCCEEDED and the cancellation attempt has no effect.
#
# POST /
# operationId: CancelEnvironmentDeployment
export def "cancel-environment-deployment" [
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
  --x-amz-target: string@x-amz-target-completer-2 # required
  environment_name: string # The name of the environment with the deployment to cancel.
]: any -> record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CancelEnvironmentDeployment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"environmentName": $environment_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Attempts to cancel a service instance deployment on an UpdateServiceInstance action, if the deployment is IN_PROGRESS. For more information, see Update a service instance (https://docs.aws.amazon.com/proton/latest/userguide/ag-svc-instance-update.html) in the Proton User guide. The following list includes potential cancellation scenarios. If the cancellation attempt succeeds, the resulting deployment state is CANCELLED. If the cancellation attempt fails, the resulting deployment state is FAILED. If the current UpdateServiceInstance action succeeds before the cancellation attempt starts, the resulting deployment state is SUCCEEDED and the cancellation attempt has no effect.
#
# POST /
# operationId: CancelServiceInstanceDeployment
export def "cancel-service-instance-deployment" [
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
  --x-amz-target: string@x-amz-target-completer-3 # required
  service_instance_name: string # The name of the service instance with the deployment to cancel.
  service_name: string # The name of the service with the service instance deployment to cancel.
]: any -> record<serviceInstance: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CancelServiceInstanceDeployment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"serviceInstanceName": $service_instance_name, "serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Attempts to cancel a service pipeline deployment on an UpdateServicePipeline action, if the deployment is IN_PROGRESS. For more information, see Update a service pipeline (https://docs.aws.amazon.com/proton/latest/userguide/ag-svc-pipeline-update.html) in the Proton User guide. The following list includes potential cancellation scenarios. If the cancellation attempt succeeds, the resulting deployment state is CANCELLED. If the cancellation attempt fails, the resulting deployment state is FAILED. If the current UpdateServicePipeline action succeeds before the cancellation attempt starts, the resulting deployment state is SUCCEEDED and the cancellation attempt has no effect.
#
# POST /
# operationId: CancelServicePipelineDeployment
export def "cancel-service-pipeline-deployment" [
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  service_name: string # The name of the service with the service pipeline deployment to cancel.
]: any -> record<pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CancelServicePipelineDeployment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Create an Proton component. A component is an infrastructure extension for a service instance. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# operationId: CreateComponent
# --tags item shape: {key: string, value: string}
export def "create-component" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  --client-token: string # The client token for the created component.
  --description: string # An optional customer-provided description of the component. (format: password)
  --environment-name: string # The name of the Proton environment that you want to associate this component with. You must specify this when you don't specify serviceInstanceName and serviceName.
  manifest: string # A path to a manifest file that lists the Infrastructure as Code (IaC) file, template language, and rendering engine for infrastructure that a custom component provisions. (format: password)
  name: string # The customer-provided name of the component.
  --service-instance-name: string # The name of the service instance that you want to attach this component to. If you don't specify this, the component isn't attached to any service instance. Specify both serviceInstanceName and serviceName or neither of them.
  --service-name: string # The name of the service that serviceInstanceName is associated with. If you don't specify this, the component isn't attached to any service instance. Specify both serviceInstanceName and serviceName or neither of them.
  --service-spec: string # The service spec that you want the component to use to access service inputs. Set this only when you attach the component to a service instance. (format: password)
  --tags: list # An optional list of metadata items that you can associate with the Proton component. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
  template_file: string # A path to the Infrastructure as Code (IaC) file describing infrastructure that a custom component provisions. Components support a single IaC file, even if you use Terraform as your template language. (format: password)
]: any -> record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CreateComponent")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"clientToken": $client_token, "description": $description, "environmentName": $environment_name, "manifest": $manifest, "name": $name, "serviceInstanceName": $service_instance_name, "serviceName": $service_name, "serviceSpec": $service_spec, "tags": $tags, "templateFile": $template_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Deploy a new environment. An Proton environment is created from an environment template that defines infrastructure and resources that can be shared across services. You can provision environments using the following methods: Amazon Web Services-managed provisioning: Proton makes direct calls to provision your resources. Self-managed provisioning: Proton makes pull requests on your repository to provide compiled infrastructure as code (IaC) files that your IaC engine uses to provision resources. For more information, see Environments (https://docs.aws.amazon.com/proton/latest/userguide/ag-environments.html) and Provisioning methods (https://docs.aws.amazon.com/proton/latest/userguide/ag-works-prov-methods.html) in the Proton User Guide.
#
# POST /
# operationId: CreateEnvironment
# --provisioningRepository shape: {branch: string, name: string, provider: "GITHUB"|"GITHUB_ENTERPRISE"|"BITBUCKET"}
# --tags item shape: {key: string, value: string}
export def "create-environment" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  --codebuild-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that allows Proton to provision infrastructure using CodeBuild-based provisioning on your behalf. To use CodeBuild-based provisioning for the environment or for any service instance running in the environment, specify either the environmentAccountConnectionId or codebuildRoleArn parameter.
  --component-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that Proton uses when provisioning directly defined components in this environment. It determines the scope of infrastructure that a component can provision. You must specify componentRoleArn to allow directly defined components to be associated with this environment. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
  --description: string # A description of the environment that's being created and deployed. (format: password)
  --environment-account-connection-id: string # The ID of the environment account connection that you provide if you're provisioning your environment infrastructure resources to an environment account. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide. To use Amazon Web Services-managed provisioning for the environment, specify either the environmentAccountConnectionId or protonServiceRoleArn parameter and omit the provisioningRepository parameter.
  name: string # The name of the environment.
  --proton-service-role-arn: string # The Amazon Resource Name (ARN) of the Proton service role that allows Proton to make calls to other services on your behalf. To use Amazon Web Services-managed provisioning for the environment, specify either the environmentAccountConnectionId or protonServiceRoleArn parameter and omit the provisioningRepository parameter.
  --provisioning-repository: record # Detail input data for a linked repository branch. — shape: {branch: string, name: string, provider: "GITHUB"|"GITHUB_ENTERPRISE"|"BITBUCKET"}
  spec: string # A YAML formatted string that provides inputs as defined in the environment template bundle schema file. For more information, see Environments (https://docs.aws.amazon.com/proton/latest/userguide/ag-environments.html) in the Proton User Guide. (format: password)
  --tags: list # An optional list of metadata items that you can associate with the Proton environment. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
  template_major_version: string # The major version of the environment template.
  --template-minor-version: string # The minor version of the environment template.
  template_name: string # The name of the environment template. For more information, see Environment Templates (https://docs.aws.amazon.com/proton/latest/userguide/ag-templates.html) in the Proton User Guide.
]: any -> record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CreateEnvironment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"codebuildRoleArn": $codebuild_role_arn, "componentRoleArn": $component_role_arn, "description": $description, "environmentAccountConnectionId": $environment_account_connection_id, "name": $name, "protonServiceRoleArn": $proton_service_role_arn, "provisioningRepository": $provisioning_repository, "spec": $spec, "tags": $tags, "templateMajorVersion": $template_major_version, "templateMinorVersion": $template_minor_version, "templateName": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Create an environment account connection in an environment account so that environment infrastructure resources can be provisioned in the environment account from a management account. An environment account connection is a secure bi-directional connection between a management account and an environment account that maintains authorization and permissions. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# operationId: CreateEnvironmentAccountConnection
# --tags item shape: {key: string, value: string}
export def "create-environment-account-connection" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  --client-token: string # When included, if two identical requests are made with the same client token, Proton returns the environment account connection that the first request created.
  --codebuild-role-arn: string # The Amazon Resource Name (ARN) of an IAM service role in the environment account. Proton uses this role to provision infrastructure resources using CodeBuild-based provisioning in the associated environment account.
  --component-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that Proton uses when provisioning directly defined components in the associated environment account. It determines the scope of infrastructure that a component can provision in the account. You must specify componentRoleArn to allow directly defined components to be associated with any environments running in this account. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
  environment_name: string # The name of the Proton environment that's created in the associated management account.
  management_account_id: string # The ID of the management account that accepts or rejects the environment account connection. You create and manage the Proton environment in this account. If the management account accepts the environment account connection, Proton can use the associated IAM role to provision environment infrastructure resources in the associated environment account.
  --role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that's created in the environment account. Proton uses this role to provision infrastructure resources in the associated environment account.
  --tags: list # An optional list of metadata items that you can associate with the Proton environment account connection. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
]: any -> record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CreateEnvironmentAccountConnection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"clientToken": $client_token, "codebuildRoleArn": $codebuild_role_arn, "componentRoleArn": $component_role_arn, "environmentName": $environment_name, "managementAccountId": $management_account_id, "roleArn": $role_arn, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Create an environment template for Proton. For more information, see Environment Templates (https://docs.aws.amazon.com/proton/latest/userguide/ag-templates.html) in the Proton User Guide. You can create an environment template in one of the two following ways: Register and publish a standard environment template that instructs Proton to deploy and manage environment infrastructure. Register and publish a customer managed environment template that connects Proton to your existing provisioned infrastructure that you manage. Proton doesn't manage your existing provisioned infrastructure. To create an environment template for customer provisioned and managed infrastructure, include the provisioning parameter and set the value to CUSTOMER_MANAGED. For more information, see Register and publish an environment template (https://docs.aws.amazon.com/proton/latest/userguide/template-create.html) in the Proton User Guide.
#
# POST /
# operationId: CreateEnvironmentTemplate
# --tags item shape: {key: string, value: string}
export def "create-environment-template" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  --description: string # A description of the environment template. (format: password)
  --display-name: string # The environment template name as displayed in the developer interface. (format: password)
  --encryption-key: string # A customer provided encryption key that Proton uses to encrypt data.
  name: string # The name of the environment template.
  --provisioning: string@provisioning-completer # When included, indicates that the environment template is for customer provisioned and managed infrastructure.
  --tags: list # An optional list of metadata items that you can associate with the Proton environment template. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
]: any -> record<environmentTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CreateEnvironmentTemplate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"description": $description, "displayName": $display_name, "encryptionKey": $encryption_key, "name": $name, "provisioning": $provisioning, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Create a new major or minor version of an environment template. A major version of an environment template is a version that isn't backwards compatible. A minor version of an environment template is a version that's backwards compatible within its major version.
#
# POST /
# operationId: CreateEnvironmentTemplateVersion
# --source shape: {s3?: record}
# --tags item shape: {key: string, value: string}
export def "create-environment-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  --client-token: string # When included, if two identical requests are made with the same client token, Proton returns the environment template version that the first request created.
  --description: string # A description of the new version of an environment template. (format: password)
  --major-version: string # To create a new minor version of the environment template, include major Version. To create a new major and minor version of the environment template, exclude major Version.
  source: record # Template version source data. — shape: {s3?: record}
  --tags: list # An optional list of metadata items that you can associate with the Proton environment template version. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
  template_name: string # The name of the environment template.
]: any -> record<environmentTemplateVersion: record<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CreateEnvironmentTemplateVersion")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"clientToken": $client_token, "description": $description, "majorVersion": $major_version, "source": $source, "tags": $tags, "templateName": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Create and register a link to a repository. Proton uses the link to repeatedly access the repository, to either push to it (self-managed provisioning) or pull from it (template sync). You can share a linked repository across multiple resources (like environments using self-managed provisioning, or synced templates). When you create a repository link, Proton creates a service-linked role (https://docs.aws.amazon.com/proton/latest/userguide/using-service-linked-roles.html) for you. For more information, see Self-managed provisioning (https://docs.aws.amazon.com/proton/latest/userguide/ag-works-prov-methods.html#ag-works-prov-methods-self), Template bundles (https://docs.aws.amazon.com/proton/latest/userguide/ag-template-authoring.html#ag-template-bundles), and Template sync configurations (https://docs.aws.amazon.com/proton/latest/userguide/ag-template-sync-configs.html) in the Proton User Guide.
#
# POST /
# operationId: CreateRepository
# --tags item shape: {key: string, value: string}
export def "create-repository" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  connection_arn: string # The Amazon Resource Name (ARN) of your AWS CodeStar connection that connects Proton to your repository provider account. For more information, see Setting up for Proton (https://docs.aws.amazon.com/proton/latest/userguide/setting-up-for-service.html) in the Proton User Guide.
  --encryption-key: string # The ARN of your customer Amazon Web Services Key Management Service (Amazon Web Services KMS) key.
  name: string # The repository name (for example, myrepos/myrepo).
  provider: string@provider-completer # The repository provider.
  --tags: list # An optional list of metadata items that you can associate with the Proton repository. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
]: any -> record<repository: record<arn: string, connectionArn: string, encryptionKey: string, name: string, provider: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CreateRepository")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"connectionArn": $connection_arn, "encryptionKey": $encryption_key, "name": $name, "provider": $provider, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Create an Proton service. An Proton service is an instantiation of a service template and often includes several service instances and pipeline. For more information, see Services (https://docs.aws.amazon.com/proton/latest/userguide/ag-services.html) in the Proton User Guide.
#
# POST /
# operationId: CreateService
# --tags item shape: {key: string, value: string}
export def "create-service" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  --branch-name: string # The name of the code repository branch that holds the code that's deployed in Proton. Don't include this parameter if your service template doesn't include a service pipeline.
  --description: string # A description of the Proton service. (format: password)
  name: string # The service name.
  --repository-connection-arn: string # The Amazon Resource Name (ARN) of the repository connection. For more information, see Setting up an AWS CodeStar connection (https://docs.aws.amazon.com/proton/latest/userguide/setting-up-for-service.html#setting-up-vcontrol) in the Proton User Guide. Don't include this parameter if your service template doesn't include a service pipeline.
  --repository-id: string # The ID of the code repository. Don't include this parameter if your service template doesn't include a service pipeline.
  spec: string # A link to a spec file that provides inputs as defined in the service template bundle schema file. The spec file is in YAML format. Don’t include pipeline inputs in the spec if your service template doesn’t include a service pipeline. For more information, see Create a service (https://docs.aws.amazon.com/proton/latest/userguide/ag-create-svc.html) in the Proton User Guide. (format: password)
  --tags: list # An optional list of metadata items that you can associate with the Proton service. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
  template_major_version: string # The major version of the service template that was used to create the service.
  --template-minor-version: string # The minor version of the service template that was used to create the service.
  template_name: string # The name of the service template that's used to create the service.
]: any -> record<service: record<arn: string, branchName: string, createdAt: string, description: string, lastModifiedAt: string, name: string, pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, repositoryConnectionArn: string, repositoryId: string, spec: string, status: string, statusMessage: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CreateService")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"branchName": $branch_name, "description": $description, "name": $name, "repositoryConnectionArn": $repository_connection_arn, "repositoryId": $repository_id, "spec": $spec, "tags": $tags, "templateMajorVersion": $template_major_version, "templateMinorVersion": $template_minor_version, "templateName": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Create a service instance.
#
# POST /
# operationId: CreateServiceInstance
# --tags item shape: {key: string, value: string}
export def "create-service-instance" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  --client-token: string # The client token of the service instance to create.
  name: string # The name of the service instance to create.
  service_name: string # The name of the service the service instance is added to.
  spec: string # The spec for the service instance you want to create. (format: password)
  --tags: list # An optional list of metadata items that you can associate with the Proton service instance. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
  --template-major-version: string # To create a new major and minor version of the service template, exclude major Version.
  --template-minor-version: string # To create a new minor version of the service template, include a major Version.
]: any -> record<serviceInstance: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CreateServiceInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"clientToken": $client_token, "name": $name, "serviceName": $service_name, "spec": $spec, "tags": $tags, "templateMajorVersion": $template_major_version, "templateMinorVersion": $template_minor_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Create the Proton Ops configuration file.
#
# POST /
# operationId: CreateServiceSyncConfig
export def "create-service-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  branch: string # The repository branch for your Proton Ops file.
  file_path: string # The path to the Proton Ops file.
  repository_name: string # The repository name.
  repository_provider: string@repository-provider-completer # The provider type for your repository.
  service_name: string # The name of the service the Proton Ops file is for.
]: any -> record<serviceSyncConfig: record<branch: string, filePath: string, repositoryName: string, repositoryProvider: string, serviceName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CreateServiceSyncConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"branch": $branch, "filePath": $file_path, "repositoryName": $repository_name, "repositoryProvider": $repository_provider, "serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Create a service template. The administrator creates a service template to define standardized infrastructure and an optional CI/CD service pipeline. Developers, in turn, select the service template from Proton. If the selected service template includes a service pipeline definition, they provide a link to their source code repository. Proton then deploys and manages the infrastructure defined by the selected service template. For more information, see Proton templates (https://docs.aws.amazon.com/proton/latest/userguide/ag-templates.html) in the Proton User Guide.
#
# POST /
# operationId: CreateServiceTemplate
# --tags item shape: {key: string, value: string}
export def "create-service-template" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  --description: string # A description of the service template. (format: password)
  --display-name: string # The name of the service template as displayed in the developer interface. (format: password)
  --encryption-key: string # A customer provided encryption key that's used to encrypt data.
  name: string # The name of the service template.
  --pipeline-provisioning: string@pipeline-provisioning-completer # By default, Proton provides a service pipeline for your service. When this parameter is included, it indicates that an Proton service pipeline isn't provided for your service. After it's included, it can't be changed. For more information, see Template bundles (https://docs.aws.amazon.com/proton/latest/userguide/ag-template-authoring.html#ag-template-bundles) in the Proton User Guide.
  --tags: list # An optional list of metadata items that you can associate with the Proton service template. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
]: any -> record<serviceTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CreateServiceTemplate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"description": $description, "displayName": $display_name, "encryptionKey": $encryption_key, "name": $name, "pipelineProvisioning": $pipeline_provisioning, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Create a new major or minor version of a service template. A major version of a service template is a version that isn't backward compatible. A minor version of a service template is a version that's backward compatible within its major version.
#
# POST /
# operationId: CreateServiceTemplateVersion
# --compatibleEnvironmentTemplates item shape: {majorVersion: string, templateName: string}
# --source shape: {s3?: record}
# --tags item shape: {key: string, value: string}
export def "create-service-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  --client-token: string # When included, if two identical requests are made with the same client token, Proton returns the service template version that the first request created.
  compatible_environment_templates: list # An array of environment template objects that are compatible with the new service template version. A service instance based on this service template version can run in environments based on compatible templates. — item shape: {majorVersion: string, templateName: string}
  --description: string # A description of the new version of a service template. (format: password)
  --major-version: string # To create a new minor version of the service template, include a major Version. To create a new major and minor version of the service template, exclude major Version.
  source: record # Template version source data. — shape: {s3?: record}
  --supported-component-sources: list<string> # An array of supported component sources. Components with supported sources can be attached to service instances based on this service template version. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
  --tags: list # An optional list of metadata items that you can associate with the Proton service template version. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
  template_name: string # The name of the service template.
]: any -> record<serviceTemplateVersion: record<arn: string, compatibleEnvironmentTemplates: list<record>, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, supportedComponentSources: list<string>, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CreateServiceTemplateVersion")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"clientToken": $client_token, "compatibleEnvironmentTemplates": $compatible_environment_templates, "description": $description, "majorVersion": $major_version, "source": $source, "supportedComponentSources": $supported_component_sources, "tags": $tags, "templateName": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Set up a template to create new template versions automatically by tracking a linked repository. A linked repository is a repository that has been registered with Proton. For more information, see CreateRepository. When a commit is pushed to your linked repository, Proton checks for changes to your repository template bundles. If it detects a template bundle change, a new major or minor version of its template is created, if the version doesn’t already exist. For more information, see Template sync configurations (https://docs.aws.amazon.com/proton/latest/userguide/ag-template-sync-configs.html) in the Proton User Guide.
#
# POST /
# operationId: CreateTemplateSyncConfig
export def "create-template-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  branch: string # The repository branch for your template.
  repository_name: string # The repository name (for example, myrepos/myrepo).
  repository_provider: string@repository-provider-completer # The provider type for your repository.
  --subdirectory: string # A repository subdirectory path to your template bundle directory. When included, Proton limits the template bundle search to this repository directory.
  template_name: string # The name of your registered template.
  template_type: string@template-type-completer # The type of the registered template.
]: any -> record<templateSyncConfig: record<branch: string, repositoryName: string, repositoryProvider: string, subdirectory: string, templateName: string, templateType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.CreateTemplateSyncConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"branch": $branch, "repositoryName": $repository_name, "repositoryProvider": $repository_provider, "subdirectory": $subdirectory, "templateName": $template_name, "templateType": $template_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Delete an Proton component resource. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# operationId: DeleteComponent
export def "delete-component" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  name: string # The name of the component to delete.
]: any -> record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.DeleteComponent")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Delete an environment.
#
# POST /
# operationId: DeleteEnvironment
export def "delete-environment" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  name: string # The name of the environment to delete.
]: any -> record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.DeleteEnvironment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# In an environment account, delete an environment account connection. After you delete an environment account connection that’s in use by an Proton environment, Proton can’t manage the environment infrastructure resources until a new environment account connection is accepted for the environment account and associated environment. You're responsible for cleaning up provisioned resources that remain without an environment connection. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# operationId: DeleteEnvironmentAccountConnection
export def "delete-environment-account-connection" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  id: string # The ID of the environment account connection to delete.
]: any -> record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.DeleteEnvironmentAccountConnection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# If no other major or minor versions of an environment template exist, delete the environment template.
#
# POST /
# operationId: DeleteEnvironmentTemplate
export def "delete-environment-template" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  name: string # The name of the environment template to delete.
]: any -> record<environmentTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.DeleteEnvironmentTemplate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# If no other minor versions of an environment template exist, delete a major version of the environment template if it's not the Recommended version. Delete the Recommended version of the environment template if no other major versions or minor versions of the environment template exist. A major version of an environment template is a version that's not backward compatible. Delete a minor version of an environment template if it isn't the Recommended version. Delete a Recommended minor version of the environment template if no other minor versions of the environment template exist. A minor version of an environment template is a version that's backward compatible.
#
# POST /
# operationId: DeleteEnvironmentTemplateVersion
export def "delete-environment-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  major_version: string # The environment template major version to delete.
  minor_version: string # The environment template minor version to delete.
  template_name: string # The name of the environment template.
]: any -> record<environmentTemplateVersion: record<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.DeleteEnvironmentTemplateVersion")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"majorVersion": $major_version, "minorVersion": $minor_version, "templateName": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# De-register and unlink your repository.
#
# POST /
# operationId: DeleteRepository
export def "delete-repository" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  name: string # The repository name.
  provider: string@provider-completer # The repository provider.
]: any -> record<repository: record<arn: string, connectionArn: string, encryptionKey: string, name: string, provider: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.DeleteRepository")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name, "provider": $provider} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Delete a service, with its instances and pipeline. You can't delete a service if it has any service instances that have components attached to them. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# operationId: DeleteService
export def "delete-service" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  name: string # The name of the service to delete.
]: any -> record<service: record<arn: string, branchName: string, createdAt: string, description: string, lastModifiedAt: string, name: string, pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, repositoryConnectionArn: string, repositoryId: string, spec: string, status: string, statusMessage: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.DeleteService")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Delete the Proton Ops file.
#
# POST /
# operationId: DeleteServiceSyncConfig
export def "delete-service-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  service_name: string # The name of the service that you want to delete the service sync configuration for.
]: any -> record<serviceSyncConfig: record<branch: string, filePath: string, repositoryName: string, repositoryProvider: string, serviceName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.DeleteServiceSyncConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# If no other major or minor versions of the service template exist, delete the service template.
#
# POST /
# operationId: DeleteServiceTemplate
export def "delete-service-template" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  name: string # The name of the service template to delete.
]: any -> record<serviceTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.DeleteServiceTemplate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# If no other minor versions of a service template exist, delete a major version of the service template if it's not the Recommended version. Delete the Recommended version of the service template if no other major versions or minor versions of the service template exist. A major version of a service template is a version that isn't backwards compatible. Delete a minor version of a service template if it's not the Recommended version. Delete a Recommended minor version of the service template if no other minor versions of the service template exist. A minor version of a service template is a version that's backwards compatible.
#
# POST /
# operationId: DeleteServiceTemplateVersion
export def "delete-service-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  major_version: string # The service template major version to delete.
  minor_version: string # The service template minor version to delete.
  template_name: string # The name of the service template.
]: any -> record<serviceTemplateVersion: record<arn: string, compatibleEnvironmentTemplates: list<record>, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, supportedComponentSources: list<string>, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.DeleteServiceTemplateVersion")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"majorVersion": $major_version, "minorVersion": $minor_version, "templateName": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Delete a template sync configuration.
#
# POST /
# operationId: DeleteTemplateSyncConfig
export def "delete-template-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  template_name: string # The template name.
  template_type: string@template-type-completer # The template type.
]: any -> record<templateSyncConfig: record<branch: string, repositoryName: string, repositoryProvider: string, subdirectory: string, templateName: string, templateType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.DeleteTemplateSyncConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"templateName": $template_name, "templateType": $template_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get detail data for Proton account-wide settings.
#
# POST /
# operationId: GetAccountSettings
export def "get-account-settings" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  --body: record
]: any -> record<accountSettings: record<pipelineCodebuildRoleArn: string, pipelineProvisioningRepository: record<arn: string, branch: string, name: string, provider: string>, pipelineServiceRoleArn: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetAccountSettings")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get detailed data for a component. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# operationId: GetComponent
export def "get-component" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  name: string # The name of the component that you want to get the detailed data for.
]: any -> record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetComponent")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get detailed data for an environment.
#
# POST /
# operationId: GetEnvironment
export def "get-environment" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  name: string # The name of the environment that you want to get the detailed data for.
]: any -> record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetEnvironment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# In an environment account, get the detailed data for an environment account connection. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# operationId: GetEnvironmentAccountConnection
export def "get-environment-account-connection" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  id: string # The ID of the environment account connection that you want to get the detailed data for.
]: any -> record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetEnvironmentAccountConnection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get detailed data for an environment template.
#
# POST /
# operationId: GetEnvironmentTemplate
export def "get-environment-template" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  name: string # The name of the environment template that you want to get the detailed data for.
]: any -> record<environmentTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetEnvironmentTemplate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get detailed data for a major or minor version of an environment template.
#
# POST /
# operationId: GetEnvironmentTemplateVersion
export def "get-environment-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  major_version: string # To get environment template major version detail data, include major Version.
  minor_version: string # To get environment template minor version detail data, include minorVersion.
  template_name: string # The name of the environment template a version of which you want to get detailed data for.
]: any -> record<environmentTemplateVersion: record<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetEnvironmentTemplateVersion")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"majorVersion": $major_version, "minorVersion": $minor_version, "templateName": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get detail data for a linked repository.
#
# POST /
# operationId: GetRepository
export def "get-repository" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  name: string # The repository name, for example myrepos/myrepo.
  provider: string@provider-completer # The repository provider.
]: any -> record<repository: record<arn: string, connectionArn: string, encryptionKey: string, name: string, provider: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetRepository")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name, "provider": $provider} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get the sync status of a repository used for Proton template sync. For more information about template sync, see . A repository sync status isn't tied to the Proton Repository resource (or any other Proton resource). Therefore, tags on an Proton Repository resource have no effect on this action. Specifically, you can't use these tags to control access to this action using Attribute-based access control (ABAC). For more information about ABAC, see ABAC (https://docs.aws.amazon.com/proton/latest/userguide/security_iam_service-with-iam.html#security_iam_service-with-iam-tags) in the Proton User Guide.
#
# POST /
# operationId: GetRepositorySyncStatus
export def "get-repository-sync-status" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  branch: string # The repository branch.
  repository_name: string # The repository name.
  repository_provider: string@repository-provider-completer # The repository provider.
  sync_type: string@sync-type-completer # The repository sync type.
]: any -> record<latestSync: record<events: list<record>, startedAt: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetRepositorySyncStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"branch": $branch, "repositoryName": $repository_name, "repositoryProvider": $repository_provider, "syncType": $sync_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get counts of Proton resources. For infrastructure-provisioning resources (environments, services, service instances, pipelines), the action returns staleness counts. A resource is stale when it's behind the recommended version of the Proton template that it uses and it needs an update to become current. The action returns staleness counts (counts of resources that are up-to-date, behind a template major version, or behind a template minor version), the total number of resources, and the number of resources that are in a failed state, grouped by resource type. Components, environments, and service templates return less information - see the components, environments, and serviceTemplates field descriptions. For context, the action also returns the total number of each type of Proton template in the Amazon Web Services account. For more information, see Proton dashboard (https://docs.aws.amazon.com/proton/latest/userguide/monitoring-dashboard.html) in the Proton User Guide.
#
# POST /
# operationId: GetResourcesSummary
export def "get-resources-summary" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  --body: record
]: any -> record<counts: record<components: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, environmentTemplates: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, environments: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, pipelines: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, serviceInstances: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, serviceTemplates: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, services: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetResourcesSummary")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get detailed data for a service.
#
# POST /
# operationId: GetService
export def "get-service" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  name: string # The name of the service that you want to get the detailed data for.
]: any -> record<service: record<arn: string, branchName: string, createdAt: string, description: string, lastModifiedAt: string, name: string, pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, repositoryConnectionArn: string, repositoryId: string, spec: string, status: string, statusMessage: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetService")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get detailed data for a service instance. A service instance is an instantiation of service template and it runs in a specific environment.
#
# POST /
# operationId: GetServiceInstance
export def "get-service-instance" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  name: string # The name of a service instance that you want to get the detailed data for.
  service_name: string # The name of the service that you want the service instance input for.
]: any -> record<serviceInstance: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetServiceInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name, "serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get the status of the synced service instance.
#
# POST /
# operationId: GetServiceInstanceSyncStatus
export def "get-service-instance-sync-status" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  service_instance_name: string # The name of the service instance that you want the sync status input for.
  service_name: string # The name of the service that the service instance belongs to.
]: any -> record<desiredState: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, latestSuccessfulSync: record<events: list<record>, initialRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, startedAt: string, status: string, target: string, targetRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>>, latestSync: record<events: list<record>, initialRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, startedAt: string, status: string, target: string, targetRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetServiceInstanceSyncStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"serviceInstanceName": $service_instance_name, "serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get detailed data for the service sync blocker summary.
#
# POST /
# operationId: GetServiceSyncBlockerSummary
export def "get-service-sync-blocker-summary" [
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
  --x-amz-target: string@x-amz-target-completer-40 # required
  --service-instance-name: string # The name of the service instance that you want to get the service sync blocker summary for. If given bothe the instance name and the service name, only the instance is blocked.
  service_name: string # The name of the service that you want to get the service sync blocker summary for. If given only the service name, all instances are blocked.
]: any -> record<serviceSyncBlockerSummary: record<latestBlockers: list<record>, serviceInstanceName: string, serviceName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetServiceSyncBlockerSummary")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"serviceInstanceName": $service_instance_name, "serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get detailed information for the service sync configuration.
#
# POST /
# operationId: GetServiceSyncConfig
export def "get-service-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  service_name: string # The name of the service that you want to get the service sync configuration for.
]: any -> record<serviceSyncConfig: record<branch: string, filePath: string, repositoryName: string, repositoryProvider: string, serviceName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetServiceSyncConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get detailed data for a service template.
#
# POST /
# operationId: GetServiceTemplate
export def "get-service-template" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  name: string # The name of the service template that you want to get detailed data for.
]: any -> record<serviceTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetServiceTemplate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get detailed data for a major or minor version of a service template.
#
# POST /
# operationId: GetServiceTemplateVersion
export def "get-service-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  major_version: string # To get service template major version detail data, include major Version.
  minor_version: string # To get service template minor version detail data, include minorVersion.
  template_name: string # The name of the service template a version of which you want to get detailed data for.
]: any -> record<serviceTemplateVersion: record<arn: string, compatibleEnvironmentTemplates: list<record>, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, supportedComponentSources: list<string>, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetServiceTemplateVersion")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"majorVersion": $major_version, "minorVersion": $minor_version, "templateName": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get detail data for a template sync configuration.
#
# POST /
# operationId: GetTemplateSyncConfig
export def "get-template-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  template_name: string # The template name.
  template_type: string@template-type-completer # The template type.
]: any -> record<templateSyncConfig: record<branch: string, repositoryName: string, repositoryProvider: string, subdirectory: string, templateName: string, templateType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetTemplateSyncConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"templateName": $template_name, "templateType": $template_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get the status of a template sync.
#
# POST /
# operationId: GetTemplateSyncStatus
export def "get-template-sync-status" [
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  template_name: string # The template name.
  template_type: string@template-type-completer # The template type.
  template_version: string # The template major version.
]: any -> record<desiredState: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, latestSuccessfulSync: record<events: list<record>, initialRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, startedAt: string, status: string, target: string, targetRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>>, latestSync: record<events: list<record>, initialRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, startedAt: string, status: string, target: string, targetRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.GetTemplateSyncStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"templateName": $template_name, "templateType": $template_type, "templateVersion": $template_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get a list of component Infrastructure as Code (IaC) outputs. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# operationId: ListComponentOutputs
export def "list-component-outputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  component_name: string # The name of the component whose outputs you want.
  --next-token-body: string # A token that indicates the location of the next output in the array of outputs, after the list of outputs that was previously requested. (body field)
]: any -> record<nextToken: string, outputs: table<key: string, valueString: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListComponentOutputs")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"componentName": $component_name, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List provisioned resources for a component with details. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# operationId: ListComponentProvisionedResources
export def "list-component-provisioned-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47 # required
  component_name: string # The name of the component whose provisioned resources you want.
  --next-token-body: string # A token that indicates the location of the next provisioned resource in the array of provisioned resources, after the list of provisioned resources that was previously requested. (body field)
]: any -> record<nextToken: string, provisionedResources: table<identifier: string, name: string, provisioningEngine: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListComponentProvisionedResources")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"componentName": $component_name, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List components with summary data. You can filter the result list by environment, service, or a single service instance. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# operationId: ListComponents
export def "list-components" [
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
  --x-amz-target: string@x-amz-target-completer-48 # required
  --environment-name: string # The name of an environment for result list filtering. Proton returns components associated with the environment or attached to service instances running in it.
  --max-results-body: int # The maximum number of components to list. (body field)
  --next-token-body: string # A token that indicates the location of the next component in the array of components, after the list of components that was previously requested. (body field)
  --service-instance-name: string # The name of a service instance for result list filtering. Proton returns the component attached to the service instance, if any.
  --service-name: string # The name of a service for result list filtering. Proton returns components attached to service instances of the service.
]: any -> record<components: table<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string>, nextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListComponents")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"environmentName": $environment_name, "maxResults": $max_results_body, "nextToken": $next_token_body, "serviceInstanceName": $service_instance_name, "serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# View a list of environment account connections. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# operationId: ListEnvironmentAccountConnections
export def "list-environment-account-connections" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  --environment-name: string # The environment name that's associated with each listed environment account connection.
  --max-results-body: int # The maximum number of environment account connections to list. (body field)
  --next-token-body: string # A token that indicates the location of the next environment account connection in the array of environment account connections, after the list of environment account connections that was previously requested. (body field)
  requested_by: string@requested-by-completer # The type of account making the ListEnvironmentAccountConnections request.
  --statuses: list<string> # The status details for each listed environment account connection.
]: any -> record<environmentAccountConnections: table<arn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>, nextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListEnvironmentAccountConnections")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"environmentName": $environment_name, "maxResults": $max_results_body, "nextToken": $next_token_body, "requestedBy": $requested_by, "statuses": $statuses} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# List the infrastructure as code outputs for your environment.
#
# POST /
# operationId: ListEnvironmentOutputs
export def "list-environment-outputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-50 # required
  environment_name: string # The environment name.
  --next-token-body: string # A token that indicates the location of the next environment output in the array of environment outputs, after the list of environment outputs that was previously requested. (body field)
]: any -> record<nextToken: string, outputs: table<key: string, valueString: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListEnvironmentOutputs")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"environmentName": $environment_name, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List the provisioned resources for your environment.
#
# POST /
# operationId: ListEnvironmentProvisionedResources
export def "list-environment-provisioned-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-51 # required
  environment_name: string # The environment name.
  --next-token-body: string # A token that indicates the location of the next environment provisioned resource in the array of environment provisioned resources, after the list of environment provisioned resources that was previously requested. (body field)
]: any -> record<nextToken: string, provisionedResources: table<identifier: string, name: string, provisioningEngine: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListEnvironmentProvisionedResources")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"environmentName": $environment_name, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List major or minor versions of an environment template with detail data.
#
# POST /
# operationId: ListEnvironmentTemplateVersions
export def "list-environment-template-versions" [
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
  --x-amz-target: string@x-amz-target-completer-52 # required
  --major-version: string # To view a list of minor of versions under a major version of an environment template, include major Version. To view a list of major versions of an environment template, exclude major Version.
  --max-results-body: int # The maximum number of major or minor versions of an environment template to list. (body field)
  --next-token-body: string # A token that indicates the location of the next major or minor version in the array of major or minor versions of an environment template, after the list of major or minor versions that was previously requested. (body field)
  template_name: string # The name of the environment template.
]: any -> record<nextToken: string, templateVersions: table<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, status: string, statusMessage: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListEnvironmentTemplateVersions")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"majorVersion": $major_version, "maxResults": $max_results_body, "nextToken": $next_token_body, "templateName": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# List environment templates.
#
# POST /
# operationId: ListEnvironmentTemplates
export def "list-environment-templates" [
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
  --x-amz-target: string@x-amz-target-completer-53 # required
  --max-results-body: int # The maximum number of environment templates to list. (body field)
  --next-token-body: string # A token that indicates the location of the next environment template in the array of environment templates, after the list of environment templates that was previously requested. (body field)
]: any -> record<nextToken: string, templates: table<arn: string, createdAt: string, description: string, displayName: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListEnvironmentTemplates")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# List environments with detail data summaries.
#
# POST /
# operationId: ListEnvironments
# --environmentTemplates item shape: {majorVersion: string, templateName: string}
export def "list-environments" [
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  --environment-templates: list # An array of the versions of the environment template. — item shape: {majorVersion: string, templateName: string}
  --max-results-body: int # The maximum number of environments to list. (body field)
  --next-token-body: string # A token that indicates the location of the next environment in the array of environments, after the list of environments that was previously requested. (body field)
]: any -> record<environments: table<arn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, nextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListEnvironments")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"environmentTemplates": $environment_templates, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# List linked repositories with detail data.
#
# POST /
# operationId: ListRepositories
export def "list-repositories" [
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  --max-results-body: int # The maximum number of repositories to list. (body field)
  --next-token-body: string # A token that indicates the location of the next repository in the array of repositories, after the list of repositories previously requested. (body field)
]: any -> record<nextToken: string, repositories: table<arn: string, connectionArn: string, name: string, provider: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListRepositories")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# List repository sync definitions with detail data.
#
# POST /
# operationId: ListRepositorySyncDefinitions
export def "list-repository-sync-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-56 # required
  --next-token-body: string # A token that indicates the location of the next repository sync definition in the array of repository sync definitions, after the list of repository sync definitions previously requested. (body field)
  repository_name: string # The repository name.
  repository_provider: string@repository-provider-completer # The repository provider.
  sync_type: string@sync-type-completer # The sync type. The only supported value is TEMPLATE_SYNC.
]: any -> record<nextToken: string, syncDefinitions: table<branch: string, directory: string, parent: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListRepositorySyncDefinitions")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"nextToken": $next_token_body, "repositoryName": $repository_name, "repositoryProvider": $repository_provider, "syncType": $sync_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a list service of instance Infrastructure as Code (IaC) outputs.
#
# POST /
# operationId: ListServiceInstanceOutputs
export def "list-service-instance-outputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-57 # required
  --next-token-body: string # A token that indicates the location of the next output in the array of outputs, after the list of outputs that was previously requested. (body field)
  service_instance_name: string # The name of the service instance whose outputs you want.
  service_name: string # The name of the service that serviceInstanceName is associated to.
]: any -> record<nextToken: string, outputs: table<key: string, valueString: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListServiceInstanceOutputs")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"nextToken": $next_token_body, "serviceInstanceName": $service_instance_name, "serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List provisioned resources for a service instance with details.
#
# POST /
# operationId: ListServiceInstanceProvisionedResources
export def "list-service-instance-provisioned-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-58 # required
  --next-token-body: string # A token that indicates the location of the next provisioned resource in the array of provisioned resources, after the list of provisioned resources that was previously requested. (body field)
  service_instance_name: string # The name of the service instance whose provisioned resources you want.
  service_name: string # The name of the service that serviceInstanceName is associated to.
]: any -> record<nextToken: string, provisionedResources: table<identifier: string, name: string, provisioningEngine: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListServiceInstanceProvisionedResources")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"nextToken": $next_token_body, "serviceInstanceName": $service_instance_name, "serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List service instances with summary data. This action lists service instances of all services in the Amazon Web Services account.
#
# POST /
# operationId: ListServiceInstances
# --filters item shape: {key?: "name"|"deploymentStatus"|"templateName"|"serviceName"|"deployedTemplateVersionStatus"|"environmentName"|"lastDeploymentAttemptedAtBefore"|"lastDeploymentAttemptedAtAfter"|"createdAtBefore"|"createdAtAfter", value?: string}
export def "list-service-instances" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  --filters: list # An array of filtering criteria that scope down the result list. By default, all service instances in the Amazon Web Services account are returned. — item shape: {key?: "name"|"deploymentStatus"|"templateName"|"serviceName"|"deployedTemplateVersionStatus"|"environmentName"|"lastDeploymentAttemptedAtBefore"|"lastDeploymentAttemptedAtAfter"|"createdAtBefore"|"createdAtAfter", value?: string}
  --max-results-body: int # The maximum number of service instances to list. (body field)
  --next-token-body: string # A token that indicates the location of the next service in the array of service instances, after the list of service instances that was previously requested. (body field)
  --service-name: string # The name of the service that the service instance belongs to.
  --sort-by: string@sort-by-completer # The field that the result list is sorted by. When you choose to sort by serviceName, service instances within each service are sorted by service instance name. Default: serviceName
  --sort-order: string@sort-order-completer # Result list sort order. Default: ASCENDING
]: any -> record<nextToken: string, serviceInstances: table<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListServiceInstances")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"filters": $filters, "maxResults": $max_results_body, "nextToken": $next_token_body, "serviceName": $service_name, "sortBy": $sort_by, "sortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Get a list of service pipeline Infrastructure as Code (IaC) outputs.
#
# POST /
# operationId: ListServicePipelineOutputs
export def "list-service-pipeline-outputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-60 # required
  --next-token-body: string # A token that indicates the location of the next output in the array of outputs, after the list of outputs that was previously requested. (body field)
  service_name: string # The name of the service whose pipeline's outputs you want.
]: any -> record<nextToken: string, outputs: table<key: string, valueString: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListServicePipelineOutputs")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"nextToken": $next_token_body, "serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List provisioned resources for a service and pipeline with details.
#
# POST /
# operationId: ListServicePipelineProvisionedResources
export def "list-service-pipeline-provisioned-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-61 # required
  --next-token-body: string # A token that indicates the location of the next provisioned resource in the array of provisioned resources, after the list of provisioned resources that was previously requested. (body field)
  service_name: string # The name of the service whose pipeline's provisioned resources you want.
]: any -> record<nextToken: string, provisionedResources: table<identifier: string, name: string, provisioningEngine: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListServicePipelineProvisionedResources")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"nextToken": $next_token_body, "serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List major or minor versions of a service template with detail data.
#
# POST /
# operationId: ListServiceTemplateVersions
export def "list-service-template-versions" [
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
  --x-amz-target: string@x-amz-target-completer-62 # required
  --major-version: string # To view a list of minor of versions under a major version of a service template, include major Version. To view a list of major versions of a service template, exclude major Version.
  --max-results-body: int # The maximum number of major or minor versions of a service template to list. (body field)
  --next-token-body: string # A token that indicates the location of the next major or minor version in the array of major or minor versions of a service template, after the list of major or minor versions that was previously requested. (body field)
  template_name: string # The name of the service template.
]: any -> record<nextToken: string, templateVersions: table<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, status: string, statusMessage: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListServiceTemplateVersions")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"majorVersion": $major_version, "maxResults": $max_results_body, "nextToken": $next_token_body, "templateName": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# List service templates with detail data.
#
# POST /
# operationId: ListServiceTemplates
export def "list-service-templates" [
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
  --x-amz-target: string@x-amz-target-completer-63 # required
  --max-results-body: int # The maximum number of service templates to list. (body field)
  --next-token-body: string # A token that indicates the location of the next service template in the array of service templates, after the list of service templates previously requested. (body field)
]: any -> record<nextToken: string, templates: table<arn: string, createdAt: string, description: string, displayName: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListServiceTemplates")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# List services with summaries of detail data.
#
# POST /
# operationId: ListServices
export def "list-services" [
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
  --x-amz-target: string@x-amz-target-completer-64 # required
  --max-results-body: int # The maximum number of services to list. (body field)
  --next-token-body: string # A token that indicates the location of the next service in the array of services, after the list of services that was previously requested. (body field)
]: any -> record<nextToken: string, services: table<arn: string, createdAt: string, description: string, lastModifiedAt: string, name: string, status: string, statusMessage: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListServices")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# List tags for a resource. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide.
#
# POST /
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-65 # required
  --max-results-body: int # The maximum number of tags to list. (body field)
  --next-token-body: string # A token that indicates the location of the next resource tag in the array of resource tags, after the list of resource tags that was previously requested. (body field)
  resource_arn: string # The Amazon Resource Name (ARN) of the resource for the listed tags.
]: any -> record<nextToken: string, tags: table<key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.ListTagsForResource")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"maxResults": $max_results_body, "nextToken": $next_token_body, "resourceArn": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Notify Proton of status changes to a provisioned resource when you use self-managed provisioning. For more information, see Self-managed provisioning (https://docs.aws.amazon.com/proton/latest/userguide/ag-works-prov-methods.html#ag-works-prov-methods-self) in the Proton User Guide.
#
# POST /
# operationId: NotifyResourceDeploymentStatusChange
# --outputs item shape: {key?: string, valueString?: string}
export def "notify-resource-deployment-status-change" [
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
  --x-amz-target: string@x-amz-target-completer-66 # required
  --deployment-id: string # The deployment ID for your provisioned resource.
  --outputs: list # The provisioned resource state change detail data that's returned by Proton. — item shape: {key?: string, valueString?: string}
  resource_arn: string # The provisioned resource Amazon Resource Name (ARN).
  --status: string@status-completer # The state that a PR-based deployment can be updated to.
  --status-message: string # The deployment status message for your provisioned resource. (format: password)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.NotifyResourceDeploymentStatusChange")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentId": $deployment_id, "outputs": $outputs, "resourceArn": $resource_arn, "status": $status, "statusMessage": $status_message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# In a management account, reject an environment account connection from another environment account. After you reject an environment account connection request, you can't accept or use the rejected environment account connection. You can’t reject an environment account connection that's connected to an environment. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# operationId: RejectEnvironmentAccountConnection
export def "reject-environment-account-connection" [
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
  --x-amz-target: string@x-amz-target-completer-67 # required
  id: string # The ID of the environment account connection to reject.
]: any -> record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.RejectEnvironmentAccountConnection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Tag a resource. A tag is a key-value pair of metadata that you associate with an Proton resource. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide.
#
# POST /
# operationId: TagResource
# --tags item shape: {key: string, value: string}
export def "tag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-68 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the Proton resource to apply customer tags to.
  tags: list # A list of customer tags to apply to the Proton resource. — item shape: {key: string, value: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"resourceArn": $resource_arn, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Remove a customer tag from a resource. A tag is a key-value pair of metadata associated with an Proton resource. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide.
#
# POST /
# operationId: UntagResource
export def "untag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-69 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource to remove customer tags from.
  tag_keys: list<string> # A list of customer tag keys that indicate the customer tags to be removed from the resource.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"resourceArn": $resource_arn, "tagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Update Proton settings that are used for multiple services in the Amazon Web Services account.
#
# POST /
# operationId: UpdateAccountSettings
# --pipelineProvisioningRepository shape: {branch: string, name: string, provider: "GITHUB"|"GITHUB_ENTERPRISE"|"BITBUCKET"}
export def "update-account-settings" [
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
  --x-amz-target: string@x-amz-target-completer-70 # required
  --delete-pipeline-provisioning-repository: oneof<nothing, bool> # Set to true to remove a configured pipeline repository from the account settings. Don't set this field if you are updating the configured pipeline repository.
  --pipeline-codebuild-role-arn: string # The Amazon Resource Name (ARN) of the service role you want to use for provisioning pipelines. Proton assumes this role for CodeBuild-based provisioning.
  --pipeline-provisioning-repository: record # Detail input data for a linked repository branch. — shape: {branch: string, name: string, provider: "GITHUB"|"GITHUB_ENTERPRISE"|"BITBUCKET"}
  --pipeline-service-role-arn: string # The Amazon Resource Name (ARN) of the service role you want to use for provisioning pipelines. Assumed by Proton for Amazon Web Services-managed provisioning, and by customer-owned automation for self-managed provisioning. To remove a previously configured ARN, specify an empty string.
]: any -> record<accountSettings: record<pipelineCodebuildRoleArn: string, pipelineProvisioningRepository: record<arn: string, branch: string, name: string, provider: string>, pipelineServiceRoleArn: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateAccountSettings")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deletePipelineProvisioningRepository": $delete_pipeline_provisioning_repository, "pipelineCodebuildRoleArn": $pipeline_codebuild_role_arn, "pipelineProvisioningRepository": $pipeline_provisioning_repository, "pipelineServiceRoleArn": $pipeline_service_role_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Update a component. There are a few modes for updating a component. The deploymentType field defines the mode. You can't update a component while its deployment status, or the deployment status of a service instance attached to it, is IN_PROGRESS. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# operationId: UpdateComponent
export def "update-component" [
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
  --x-amz-target: string@x-amz-target-completer-71 # required
  --client-token: string # The client token for the updated component.
  deployment_type: string@deployment-type-completer # The deployment type. It defines the mode for updating a component, as follows: NONE In this mode, a deployment doesn't occur. Only the requested metadata parameters are updated. You can only specify description in this mode. CURRENT_VERSION In this mode, the component is deployed and updated with the new serviceSpec, templateSource, and/or type that you provide. Only requested parameters are updated.
  --description: string # An optional customer-provided description of the component. (format: password)
  name: string # The name of the component to update.
  --service-instance-name: string # The name of the service instance that you want to attach this component to. Don't specify to keep the component's current service instance attachment. Specify an empty string to detach the component from the service instance it's attached to. Specify non-empty values for both serviceInstanceName and serviceName or for neither of them.
  --service-name: string # The name of the service that serviceInstanceName is associated with. Don't specify to keep the component's current service instance attachment. Specify an empty string to detach the component from the service instance it's attached to. Specify non-empty values for both serviceInstanceName and serviceName or for neither of them.
  --service-spec: string # The service spec that you want the component to use to access service inputs. Set this only when the component is attached to a service instance. (format: password)
  --template-file: string # A path to the Infrastructure as Code (IaC) file describing infrastructure that a custom component provisions. Components support a single IaC file, even if you use Terraform as your template language. (format: password)
]: any -> record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateComponent")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"clientToken": $client_token, "deploymentType": $deployment_type, "description": $description, "name": $name, "serviceInstanceName": $service_instance_name, "serviceName": $service_name, "serviceSpec": $service_spec, "templateFile": $template_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Update an environment. If the environment is associated with an environment account connection, don't update or include the protonServiceRoleArn and provisioningRepository parameter to update or connect to an environment account connection. You can only update to a new environment account connection if that connection was created in the same environment account that the current environment account connection was created in. The account connection must also be associated with the current environment. If the environment isn't associated with an environment account connection, don't update or include the environmentAccountConnectionId parameter. You can't update or connect the environment to an environment account connection if it isn't already associated with an environment connection. You can update either the environmentAccountConnectionId or protonServiceRoleArn parameter and value. You can’t update both. If the environment was configured for Amazon Web Services-managed provisioning, omit the provisioningRepository parameter. If the environment was configured for self-managed provisioning, specify the provisioningRepository parameter and omit the protonServiceRoleArn and environmentAccountConnectionId parameters. For more information, see Environments (https://docs.aws.amazon.com/proton/latest/userguide/ag-environments.html) and Provisioning methods (https://docs.aws.amazon.com/proton/latest/userguide/ag-works-prov-methods.html) in the Proton User Guide. There are four modes for updating an environment. The deploymentType field defines the mode. NONE In this mode, a deployment doesn't occur. Only the requested metadata parameters are updated. CURRENT_VERSION In this mode, the environment is deployed and updated with the new spec that you provide. Only requested parameters are updated. Don’t include minor or major version parameters when you use this deployment-type. MINOR_VERSION In this mode, the environment is deployed and updated with the published, recommended (latest) minor version of the current major version in use, by default. You can also specify a different minor version of the current major version in use. MAJOR_VERSION In this mode, the environment is deployed and updated with the published, recommended (latest) major and minor version of the current template, by default. You can also specify a different major version that's higher than the major version in use and a minor version.
#
# POST /
# operationId: UpdateEnvironment
# --provisioningRepository shape: {branch: string, name: string, provider: "GITHUB"|"GITHUB_ENTERPRISE"|"BITBUCKET"}
export def "update-environment" [
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
  --x-amz-target: string@x-amz-target-completer-72 # required
  --codebuild-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that allows Proton to provision infrastructure using CodeBuild-based provisioning on your behalf.
  --component-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that Proton uses when provisioning directly defined components in this environment. It determines the scope of infrastructure that a component can provision. The environment must have a componentRoleArn to allow directly defined components to be associated with the environment. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
  deployment_type: string@deployment-type-completer-1 # There are four modes for updating an environment. The deploymentType field defines the mode. NONE In this mode, a deployment doesn't occur. Only the requested metadata parameters are updated. CURRENT_VERSION In this mode, the environment is deployed and updated with the new spec that you provide. Only requested parameters are updated. Don’t include major or minor version parameters when you use this deployment-type. MINOR_VERSION In this mode, the environment is deployed and updated with the published, recommended (latest) minor version of the current major version in use, by default. You can also specify a different minor version of the current major version in use. MAJOR_VERSION In this mode, the environment is deployed and updated with the published, recommended (latest) major and minor version of the current template, by default. You can also specify a different major version that is higher than the major version in use and a minor version (optional).
  --description: string # A description of the environment update. (format: password)
  --environment-account-connection-id: string # The ID of the environment account connection. You can only update to a new environment account connection if it was created in the same environment account that the current environment account connection was created in and is associated with the current environment.
  name: string # The name of the environment to update.
  --proton-service-role-arn: string # The Amazon Resource Name (ARN) of the Proton service role that allows Proton to make API calls to other services your behalf.
  --provisioning-repository: record # Detail input data for a linked repository branch. — shape: {branch: string, name: string, provider: "GITHUB"|"GITHUB_ENTERPRISE"|"BITBUCKET"}
  --spec: string # The formatted specification that defines the update. (format: password)
  --template-major-version: string # The major version of the environment to update.
  --template-minor-version: string # The minor version of the environment to update.
]: any -> record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateEnvironment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"codebuildRoleArn": $codebuild_role_arn, "componentRoleArn": $component_role_arn, "deploymentType": $deployment_type, "description": $description, "environmentAccountConnectionId": $environment_account_connection_id, "name": $name, "protonServiceRoleArn": $proton_service_role_arn, "provisioningRepository": $provisioning_repository, "spec": $spec, "templateMajorVersion": $template_major_version, "templateMinorVersion": $template_minor_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# In an environment account, update an environment account connection to use a new IAM role. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# operationId: UpdateEnvironmentAccountConnection
export def "update-environment-account-connection" [
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
  --x-amz-target: string@x-amz-target-completer-73 # required
  --codebuild-role-arn: string # The Amazon Resource Name (ARN) of an IAM service role in the environment account. Proton uses this role to provision infrastructure resources using CodeBuild-based provisioning in the associated environment account.
  --component-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that Proton uses when provisioning directly defined components in the associated environment account. It determines the scope of infrastructure that a component can provision in the account. The environment account connection must have a componentRoleArn to allow directly defined components to be associated with any environments running in the account. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
  id: string # The ID of the environment account connection to update.
  --role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that's associated with the environment account connection to update.
]: any -> record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateEnvironmentAccountConnection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"codebuildRoleArn": $codebuild_role_arn, "componentRoleArn": $component_role_arn, "id": $id, "roleArn": $role_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Update an environment template.
#
# POST /
# operationId: UpdateEnvironmentTemplate
export def "update-environment-template" [
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
  --x-amz-target: string@x-amz-target-completer-74 # required
  --description: string # A description of the environment template update. (format: password)
  --display-name: string # The name of the environment template to update as displayed in the developer interface. (format: password)
  name: string # The name of the environment template to update.
]: any -> record<environmentTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateEnvironmentTemplate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"description": $description, "displayName": $display_name, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Update a major or minor version of an environment template.
#
# POST /
# operationId: UpdateEnvironmentTemplateVersion
export def "update-environment-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-75 # required
  --description: string # A description of environment template version to update. (format: password)
  major_version: string # To update a major version of an environment template, include major Version.
  minor_version: string # To update a minor version of an environment template, include minorVersion.
  --status: string@status-completer-1 # The status of the environment template minor version to update.
  template_name: string # The name of the environment template.
]: any -> record<environmentTemplateVersion: record<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateEnvironmentTemplateVersion")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"description": $description, "majorVersion": $major_version, "minorVersion": $minor_version, "status": $status, "templateName": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Edit a service description or use a spec to add and delete service instances. Existing service instances and the service pipeline can't be edited using this API. They can only be deleted. Use the description parameter to modify the description. Edit the spec parameter to add or delete instances. You can't delete a service instance (remove it from the spec) if it has an attached component. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# operationId: UpdateService
export def "update-service" [
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
  --x-amz-target: string@x-amz-target-completer-76 # required
  --description: string # The edited service description. (format: password)
  name: string # The name of the service to edit.
  --spec: string # Lists the service instances to add and the existing service instances to remain. Omit the existing service instances to delete from the list. Don't include edits to the existing service instances or pipeline. For more information, see Edit a service (https://docs.aws.amazon.com/proton/latest/userguide/ag-svc-update.html) in the Proton User Guide. (format: password)
]: any -> record<service: record<arn: string, branchName: string, createdAt: string, description: string, lastModifiedAt: string, name: string, pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, repositoryConnectionArn: string, repositoryId: string, spec: string, status: string, statusMessage: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateService")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"description": $description, "name": $name, "spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Update a service instance. There are a few modes for updating a service instance. The deploymentType field defines the mode. You can't update a service instance while its deployment status, or the deployment status of a component attached to it, is IN_PROGRESS. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# operationId: UpdateServiceInstance
export def "update-service-instance" [
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
  --x-amz-target: string@x-amz-target-completer-77 # required
  --client-token: string # The client token of the service instance to update.
  deployment_type: string@deployment-type-completer-1 # The deployment type. It defines the mode for updating a service instance, as follows: NONE In this mode, a deployment doesn't occur. Only the requested metadata parameters are updated. CURRENT_VERSION In this mode, the service instance is deployed and updated with the new spec that you provide. Only requested parameters are updated. Don’t include major or minor version parameters when you use this deployment type. MINOR_VERSION In this mode, the service instance is deployed and updated with the published, recommended (latest) minor version of the current major version in use, by default. You can also specify a different minor version of the current major version in use. MAJOR_VERSION In this mode, the service instance is deployed and updated with the published, recommended (latest) major and minor version of the current template, by default. You can specify a different major version that's higher than the major version in use and a minor version.
  name: string # The name of the service instance to update.
  service_name: string # The name of the service that the service instance belongs to.
  --spec: string # The formatted specification that defines the service instance update. (format: password)
  --template-major-version: string # The major version of the service template to update.
  --template-minor-version: string # The minor version of the service template to update.
]: any -> record<serviceInstance: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateServiceInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"clientToken": $client_token, "deploymentType": $deployment_type, "name": $name, "serviceName": $service_name, "spec": $spec, "templateMajorVersion": $template_major_version, "templateMinorVersion": $template_minor_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Update the service pipeline. There are four modes for updating a service pipeline. The deploymentType field defines the mode. NONE In this mode, a deployment doesn't occur. Only the requested metadata parameters are updated. CURRENT_VERSION In this mode, the service pipeline is deployed and updated with the new spec that you provide. Only requested parameters are updated. Don’t include major or minor version parameters when you use this deployment-type. MINOR_VERSION In this mode, the service pipeline is deployed and updated with the published, recommended (latest) minor version of the current major version in use, by default. You can specify a different minor version of the current major version in use. MAJOR_VERSION In this mode, the service pipeline is deployed and updated with the published, recommended (latest) major and minor version of the current template by default. You can specify a different major version that's higher than the major version in use and a minor version.
#
# POST /
# operationId: UpdateServicePipeline
export def "update-service-pipeline" [
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
  --x-amz-target: string@x-amz-target-completer-78 # required
  deployment_type: string@deployment-type-completer-1 # The deployment type. There are four modes for updating a service pipeline. The deploymentType field defines the mode. NONE In this mode, a deployment doesn't occur. Only the requested metadata parameters are updated. CURRENT_VERSION In this mode, the service pipeline is deployed and updated with the new spec that you provide. Only requested parameters are updated. Don’t include major or minor version parameters when you use this deployment-type. MINOR_VERSION In this mode, the service pipeline is deployed and updated with the published, recommended (latest) minor version of the current major version in use, by default. You can specify a different minor version of the current major version in use. MAJOR_VERSION In this mode, the service pipeline is deployed and updated with the published, recommended (latest) major and minor version of the current template, by default. You can specify a different major version that's higher than the major version in use and a minor version.
  service_name: string # The name of the service to that the pipeline is associated with.
  spec: string # The spec for the service pipeline to update. (format: password)
  --template-major-version: string # The major version of the service template that was used to create the service that the pipeline is associated with.
  --template-minor-version: string # The minor version of the service template that was used to create the service that the pipeline is associated with.
]: any -> record<pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateServicePipeline")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentType": $deployment_type, "serviceName": $service_name, "spec": $spec, "templateMajorVersion": $template_major_version, "templateMinorVersion": $template_minor_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Update the service sync blocker by resolving it.
#
# POST /
# operationId: UpdateServiceSyncBlocker
export def "update-service-sync-blocker" [
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
  --x-amz-target: string@x-amz-target-completer-79 # required
  id: string # The ID of the service sync blocker.
  resolved_reason: string # The reason the service sync blocker was resolved.
]: any -> record<serviceInstanceName: string, serviceName: string, serviceSyncBlocker: record<contexts: list<record>, createdAt: string, createdReason: string, id: string, resolvedAt: string, resolvedReason: string, status: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateServiceSyncBlocker")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"id": $id, "resolvedReason": $resolved_reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Update the Proton Ops config file.
#
# POST /
# operationId: UpdateServiceSyncConfig
export def "update-service-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-80 # required
  branch: string # The name of the code repository branch where the Proton Ops file is found.
  file_path: string # The path to the Proton Ops file.
  repository_name: string # The name of the repository where the Proton Ops file is found.
  repository_provider: string@repository-provider-completer # The name of the repository provider where the Proton Ops file is found.
  service_name: string # The name of the service the Proton Ops file is for.
]: any -> record<serviceSyncConfig: record<branch: string, filePath: string, repositoryName: string, repositoryProvider: string, serviceName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateServiceSyncConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"branch": $branch, "filePath": $file_path, "repositoryName": $repository_name, "repositoryProvider": $repository_provider, "serviceName": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Update a service template.
#
# POST /
# operationId: UpdateServiceTemplate
export def "update-service-template" [
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
  --x-amz-target: string@x-amz-target-completer-81 # required
  --description: string # A description of the service template update. (format: password)
  --display-name: string # The name of the service template to update that's displayed in the developer interface. (format: password)
  name: string # The name of the service template to update.
]: any -> record<serviceTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateServiceTemplate")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"description": $description, "displayName": $display_name, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Update a major or minor version of a service template.
#
# POST /
# operationId: UpdateServiceTemplateVersion
# --compatibleEnvironmentTemplates item shape: {majorVersion: string, templateName: string}
export def "update-service-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-82 # required
  --compatible-environment-templates: list # An array of environment template objects that are compatible with this service template version. A service instance based on this service template version can run in environments based on compatible templates. — item shape: {majorVersion: string, templateName: string}
  --description: string # A description of a service template version to update. (format: password)
  major_version: string # To update a major version of a service template, include major Version.
  minor_version: string # To update a minor version of a service template, include minorVersion.
  --status: string@status-completer-1 # The status of the service template minor version to update.
  --supported-component-sources: list<string> # An array of supported component sources. Components with supported sources can be attached to service instances based on this service template version. A change to supportedComponentSources doesn't impact existing component attachments to instances based on this template version. A change only affects later associations. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
  template_name: string # The name of the service template.
]: any -> record<serviceTemplateVersion: record<arn: string, compatibleEnvironmentTemplates: list<record>, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, supportedComponentSources: list<string>, templateName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateServiceTemplateVersion")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"compatibleEnvironmentTemplates": $compatible_environment_templates, "description": $description, "majorVersion": $major_version, "minorVersion": $minor_version, "status": $status, "supportedComponentSources": $supported_component_sources, "templateName": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Update template sync configuration parameters, except for the templateName and templateType. Repository details (branch, name, and provider) should be of a linked repository. A linked repository is a repository that has been registered with Proton. For more information, see CreateRepository.
#
# POST /
# operationId: UpdateTemplateSyncConfig
export def "update-template-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-83 # required
  branch: string # The repository branch for your template.
  repository_name: string # The repository name (for example, myrepos/myrepo).
  repository_provider: string@repository-provider-completer # The repository provider.
  --subdirectory: string # A subdirectory path to your template bundle version. When included, limits the template bundle search to this repository directory.
  template_name: string # The synced template name.
  template_type: string@template-type-completer # The synced template type.
]: any -> record<templateSyncConfig: record<branch: string, repositoryName: string, repositoryProvider: string, subdirectory: string, templateName: string, templateType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AwsProton20200720.UpdateTemplateSyncConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"branch": $branch, "repositoryName": $repository_name, "repositoryProvider": $repository_provider, "subdirectory": $subdirectory, "templateName": $template_name, "templateType": $template_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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
