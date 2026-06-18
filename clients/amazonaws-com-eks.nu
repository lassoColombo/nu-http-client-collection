# Auto-generated client for Amazon Elastic Kubernetes Service v2017-11-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/eks/2017-11-01/openapi.json
# Auth: --token flag or $env.AMAZON_ELASTIC_KUBERNETES_SERVICE_TOKEN

const BASE_URL = "http://eks.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_ELASTIC_KUBERNETES_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://eks.us-east-1.amazonaws.com" "http://eks.us-east-2.amazonaws.com" "http://eks.us-west-1.amazonaws.com" "http://eks.us-west-2.amazonaws.com" "http://eks.us-gov-west-1.amazonaws.com" "http://eks.us-gov-east-1.amazonaws.com" "http://eks.ca-central-1.amazonaws.com" "http://eks.eu-north-1.amazonaws.com" "http://eks.eu-west-1.amazonaws.com" "http://eks.eu-west-2.amazonaws.com" "http://eks.eu-west-3.amazonaws.com" "http://eks.eu-central-1.amazonaws.com" "http://eks.eu-south-1.amazonaws.com" "http://eks.af-south-1.amazonaws.com" "http://eks.ap-northeast-1.amazonaws.com" "http://eks.ap-northeast-2.amazonaws.com" "http://eks.ap-northeast-3.amazonaws.com" "http://eks.ap-southeast-1.amazonaws.com" "http://eks.ap-southeast-2.amazonaws.com" "http://eks.ap-east-1.amazonaws.com" "http://eks.ap-south-1.amazonaws.com" "http://eks.sa-east-1.amazonaws.com" "http://eks.me-south-1.amazonaws.com" "https://eks.us-east-1.amazonaws.com" "https://eks.us-east-2.amazonaws.com" "https://eks.us-west-1.amazonaws.com" "https://eks.us-west-2.amazonaws.com" "https://eks.us-gov-west-1.amazonaws.com" "https://eks.us-gov-east-1.amazonaws.com" "https://eks.ca-central-1.amazonaws.com" "https://eks.eu-north-1.amazonaws.com" "https://eks.eu-west-1.amazonaws.com" "https://eks.eu-west-2.amazonaws.com" "https://eks.eu-west-3.amazonaws.com" "https://eks.eu-central-1.amazonaws.com" "https://eks.eu-south-1.amazonaws.com" "https://eks.af-south-1.amazonaws.com" "https://eks.ap-northeast-1.amazonaws.com" "https://eks.ap-northeast-2.amazonaws.com" "https://eks.ap-northeast-3.amazonaws.com" "https://eks.ap-southeast-1.amazonaws.com" "https://eks.ap-southeast-2.amazonaws.com" "https://eks.ap-east-1.amazonaws.com" "https://eks.ap-south-1.amazonaws.com" "https://eks.sa-east-1.amazonaws.com" "https://eks.me-south-1.amazonaws.com" "http://eks.cn-north-1.amazonaws.com.cn" "http://eks.cn-northwest-1.amazonaws.com.cn" "https://eks.cn-north-1.amazonaws.com.cn" "https://eks.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resolve-conflicts-completer [] { ["NONE" "OVERWRITE" "PRESERVE"] }
def ami-type-completer [] { ["AL2_ARM_64" "AL2_x86_64" "AL2_x86_64_GPU" "BOTTLEROCKET_ARM_64" "BOTTLEROCKET_ARM_64_NVIDIA" "BOTTLEROCKET_x86_64" "BOTTLEROCKET_x86_64_NVIDIA" "CUSTOM" "WINDOWS_CORE_2019_x86_64" "WINDOWS_CORE_2022_x86_64" "WINDOWS_FULL_2019_x86_64" "WINDOWS_FULL_2022_x86_64"] }
def capacity-type-completer [] { ["ON_DEMAND" "SPOT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "clusters-encryption-config-associate create" } } | get name | first)
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

# Associate encryption configuration to an existing cluster. You can use this API to enable encryption on existing clusters which do not have encryption already enabled. This allows you to implement a defense-in-depth security strategy without migrating applications to new Amazon EKS clusters.
#
# POST /clusters/{name}/encryption-config/associate
# operationId: AssociateEncryptionConfig
# --encryptionConfig item shape: {resources?: any, provider?: any}
export def "clusters-encryption-config-associate create" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  encryption_config: list # The configuration you are using for encryption. — item shape: {resources?: any, provider?: any}
  --client-request-token: string # The client request token you are using with the encryption configuration.
]: any -> record<update: record<id: record, status: record, type: record, params: record, createdAt: record, errors: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/encryption-config/associate"))
  let req_body = {"encryptionConfig": $encryption_config, "clientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Associate an identity provider configuration to a cluster. If you want to authenticate identities using an identity provider, you can create an identity provider configuration and associate it to your cluster. After configuring authentication to your cluster you can create Kubernetes roles and clusterroles to assign permissions to the roles, and then bind the roles to the identities using Kubernetes rolebindings and clusterrolebindings. For more information see Using RBAC Authorization (https://kubernetes.io/docs/reference/access-authn-authz/rbac/) in the Kubernetes documentation.
#
# POST /clusters/{name}/identity-provider-configs/associate
# operationId: AssociateIdentityProviderConfig
# --oidc shape: {identityProviderConfigName?: any, issuerUrl?: any, clientId?: any, usernameClaim?: any, usernamePrefix?: any, groupsClaim?: any, groupsPrefix?: any, requiredClaims?: any}
export def "clusters-identity-provider-configs-associate create" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  oidc: record # An object representing an OpenID Connect (OIDC) configuration. Before associating an OIDC identity provider to your cluster, review the considerations in Authenticating users for your cluster from an OpenID Connect identity provider (https://docs.aws.amazon.com/eks/latest/userguide/authenticate-oidc-identity-provider.html) in the Amazon EKS User Guide. — shape: {identityProviderConfigName?: any, issuerUrl?: any, clientId?: any, usernameClaim?: any, usernamePrefix?: any, groupsClaim?: any, groupsPrefix?: any, requiredClaims?: any}
  --tags: record # The metadata to apply to the configuration to assist with categorization and organization. Each tag consists of a key and an optional value. You define both.
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> record<update: record<id: record, status: record, type: record, params: record, createdAt: record, errors: record>, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/identity-provider-configs/associate"))
  let req_body = {"oidc": $oidc, "tags": $tags, "clientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates an Amazon EKS add-on. Amazon EKS add-ons help to automate the provisioning and lifecycle management of common operational software for Amazon EKS clusters. For more information, see Amazon EKS add-ons (https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html) in the Amazon EKS User Guide.
#
# POST /clusters/{name}/addons
# operationId: CreateAddon
export def "clusters-addons create" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  addon_name: string # The name of the add-on. The name must match one of the names that DescribeAddonVersions (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonVersions.html) returns.
  --addon-version: string # The version of the add-on. The version must match one of the versions returned by DescribeAddonVersions (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonVersions.html).
  --service-account-role-arn: string # The Amazon Resource Name (ARN) of an existing IAM role to bind to the add-on's service account. The role must be assigned the IAM permissions required by the add-on. If you don't specify an existing IAM role, then the add-on uses the permissions assigned to the node IAM role. For more information, see Amazon EKS node IAM role (https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html) in the Amazon EKS User Guide. To specify an existing IAM role, you must have an IAM OpenID Connect (OIDC) provider created for your cluster. For more information, see Enabling IAM roles for service accounts on your cluster (https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html) in the Amazon EKS User Guide.
  --resolve-conflicts: string@resolve-conflicts-completer # How to resolve field value conflicts for an Amazon EKS add-on. Conflicts are handled based on the value you choose: None – If the self-managed version of the add-on is installed on your cluster, Amazon EKS doesn't change the value. Creation of the add-on might fail. Overwrite – If the self-managed version of the add-on is installed on your cluster and the Amazon EKS default value is different than the existing value, Amazon EKS changes the value to the Amazon EKS default value. Preserve – Not supported. You can set this value when updating an add-on though. For more information, see UpdateAddon (https://docs.aws.amazon.com/eks/latest/APIReference/API_UpdateAddon.html). If you don't currently have the self-managed version of the add-on installed on your cluster, the Amazon EKS add-on is installed. Amazon EKS sets all values to default values, regardless of the option that you specify.
  --client-request-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --tags: record # The metadata to apply to the cluster to assist with categorization and organization. Each tag consists of a key and an optional value. You define both.
  --configuration-values: string # The set of configuration values for the add-on that's created. The values that you provide are validated against the schema in DescribeAddonConfiguration (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonConfiguration.html).
]: any -> record<addon: record<addonName: record, clusterName: record, status: record, addonVersion: record, health: record<issues: record>, addonArn: record, createdAt: record, modifiedAt: record, serviceAccountRoleArn: record, tags: record, publisher: record, owner: record, marketplaceInformation: record<productId: record, productUrl: record>, configurationValues: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/addons"))
  let req_body = {"addonName": $addon_name, "addonVersion": $addon_version, "serviceAccountRoleArn": $service_account_role_arn, "resolveConflicts": $resolve_conflicts, "clientRequestToken": $client_request_token, "tags": $tags, "configurationValues": $configuration_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the available add-ons.
#
# GET /clusters/{name}/addons
# operationId: ListAddons
export def "clusters-addons list" [
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
  --max-results: int # The maximum number of add-on results returned by ListAddonsRequest in paginated output. When you use this parameter, ListAddonsRequest returns only maxResults results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListAddonsRequest request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListAddonsRequest returns up to 100 results and a nextToken value, if applicable.
  --next-token: string # The nextToken value returned from a previous paginated ListAddonsRequest where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<addons: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/addons") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates an Amazon EKS control plane. The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as etcd and the API server. The control plane runs in an account managed by Amazon Web Services, and the Kubernetes API is exposed by the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single tenant and unique. It runs on its own set of Amazon EC2 instances. The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the nodes (for example, to support kubectl exec, logs, and proxy data flows). Amazon EKS nodes run in your Amazon Web Services account and connect to your cluster's control plane over the Kubernetes API server endpoint and a certificate file that is created for your cluster. In most cases, it takes several minutes to create a cluster. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch nodes into your cluster. For more information, see Managing Cluster Authentication (https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html) and Launching Amazon EKS nodes (https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html) in the Amazon EKS User Guide.
#
# POST /clusters
# operationId: CreateCluster
# --resourcesVpcConfig shape: {subnetIds?: any, securityGroupIds?: any, endpointPublicAccess?: any, endpointPrivateAccess?: any, publicAccessCidrs?: any}
# --kubernetesNetworkConfig shape: {serviceIpv4Cidr?: any, ipFamily?: any}
# --logging shape: {clusterLogging?: any}
# --encryptionConfig item shape: {resources?: any, provider?: any}
# --outpostConfig shape: {outpostArns?: any, controlPlaneInstanceType?: any, controlPlanePlacement?: any}
export def "clusters create" [
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
  name: string # The unique name to give to your cluster.
  --version: string # The desired Kubernetes version for your cluster. If you don't specify a value here, the default version available in Amazon EKS is used. The default version might not be the latest version available.
  role_arn: string # The Amazon Resource Name (ARN) of the IAM role that provides permissions for the Kubernetes control plane to make calls to Amazon Web Services API operations on your behalf. For more information, see Amazon EKS Service IAM Role (https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html) in the Amazon EKS User Guide .
  resources_vpc_config: record # An object representing the VPC configuration to use for an Amazon EKS cluster. — shape: {subnetIds?: any, securityGroupIds?: any, endpointPublicAccess?: any, endpointPrivateAccess?: any, publicAccessCidrs?: any}
  --kubernetes-network-config: record # The Kubernetes network configuration for the cluster. — shape: {serviceIpv4Cidr?: any, ipFamily?: any}
  --logging: record # An object representing the logging configuration for resources in your cluster. — shape: {clusterLogging?: any}
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --tags: record # The metadata to apply to the cluster to assist with categorization and organization. Each tag consists of a key and an optional value. You define both.
  --encryption-config: list # The encryption configuration for the cluster. — item shape: {resources?: any, provider?: any}
  --outpost-config: record # The configuration of your local Amazon EKS cluster on an Amazon Web Services Outpost. Before creating a cluster on an Outpost, review Creating a local cluster on an Outpost (https://docs.aws.amazon.com/eks/latest/userguide/eks-outposts-local-cluster-create.html) in the Amazon EKS User Guide. This API isn't available for Amazon EKS clusters on the Amazon Web Services cloud. — shape: {outpostArns?: any, controlPlaneInstanceType?: any, controlPlanePlacement?: any}
]: any -> record<cluster: record<name: record, arn: record, createdAt: record, version: record, endpoint: record, roleArn: record, resourcesVpcConfig: record<subnetIds: record, securityGroupIds: record, clusterSecurityGroupId: record, vpcId: record, endpointPublicAccess: record, endpointPrivateAccess: record, publicAccessCidrs: record>, kubernetesNetworkConfig: record<serviceIpv4Cidr: record, serviceIpv6Cidr: record, ipFamily: record>, logging: record<clusterLogging: record>, identity: record<oidc: record>, status: record, certificateAuthority: record<data: record>, clientRequestToken: record, platformVersion: record, tags: record, encryptionConfig: record, connectorConfig: record<activationId: record, activationCode: record, activationExpiry: record, provider: record, roleArn: record>, id: record, health: record<issues: record>, outpostConfig: record<outpostArns: record, controlPlaneInstanceType: record, controlPlanePlacement: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clusters")
  let req_body = {"name": $name, "version": $version, "roleArn": $role_arn, "resourcesVpcConfig": $resources_vpc_config, "kubernetesNetworkConfig": $kubernetes_network_config, "logging": $logging, "clientRequestToken": $client_request_token, "tags": $tags, "encryptionConfig": $encryption_config, "outpostConfig": $outpost_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the Amazon EKS clusters in your Amazon Web Services account in the specified Region.
#
# GET /clusters
# operationId: ListClusters
export def "clusters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of cluster results returned by ListClusters in paginated output. When you use this parameter, ListClusters returns only maxResults results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListClusters request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListClusters returns up to 100 results and a nextToken value if applicable.
  --next-token: string # The nextToken value returned from a previous paginated ListClusters request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.
  --include: list # Indicates whether external clusters are included in the returned list. Use 'all' to return connected clusters, or blank to return only Amazon EKS clusters. 'all' must be in lowercase otherwise an error occurs.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<clusters: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/clusters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates an Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to run pods on Fargate. The Fargate profile allows an administrator to declare which pods run on Fargate and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is run on Fargate. When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes Role Based Access Control (https://kubernetes.io/docs/admin/authorization/rbac/) (RBAC) for authorization so that the kubelet that is running on the Fargate infrastructure can register with your Amazon EKS cluster so that it can appear in your cluster as a node. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see Pod Execution Role (https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html) in the Amazon EKS User Guide. Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating. If any Fargate profiles in a cluster are in the DELETING status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster. For more information, see Fargate Profile (https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html) in the Amazon EKS User Guide.
#
# POST /clusters/{name}/fargate-profiles
# operationId: CreateFargateProfile
# --selectors item shape: {namespace?: any, labels?: any}
export def "clusters-fargate-profiles create" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  fargate_profile_name: string # The name of the Fargate profile.
  pod_execution_role_arn: string # The Amazon Resource Name (ARN) of the pod execution role to use for pods that match the selectors in the Fargate profile. The pod execution role allows Fargate infrastructure to register with your cluster as a node, and it provides read access to Amazon ECR image repositories. For more information, see Pod Execution Role (https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html) in the Amazon EKS User Guide.
  --subnets: list<string> # The IDs of subnets to launch your pods into. At this time, pods running on Fargate are not assigned public IP addresses, so only private subnets (with no direct route to an Internet Gateway) are accepted for this parameter.
  --selectors: list # The selectors to match for pods to use this Fargate profile. Each selector must have an associated namespace. Optionally, you can also specify labels for a namespace. You may specify up to five selectors in a Fargate profile. — item shape: {namespace?: any, labels?: any}
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --tags: record # The metadata to apply to the Fargate profile to assist with categorization and organization. Each tag consists of a key and an optional value. You define both. Fargate profile tags do not propagate to any other resources associated with the Fargate profile, such as the pods that are scheduled with it.
]: any -> record<fargateProfile: record<fargateProfileName: record, fargateProfileArn: record, clusterName: record, createdAt: record, podExecutionRoleArn: record, subnets: record, selectors: record, status: record, tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/fargate-profiles"))
  let req_body = {"fargateProfileName": $fargate_profile_name, "podExecutionRoleArn": $pod_execution_role_arn, "subnets": $subnets, "selectors": $selectors, "clientRequestToken": $client_request_token, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the Fargate profiles associated with the specified cluster in your Amazon Web Services account in the specified Region.
#
# GET /clusters/{name}/fargate-profiles
# operationId: ListFargateProfiles
export def "clusters-fargate-profiles list" [
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
  --max-results: int # The maximum number of Fargate profile results returned by ListFargateProfiles in paginated output. When you use this parameter, ListFargateProfiles returns only maxResults results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListFargateProfiles request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListFargateProfiles returns up to 100 results and a nextToken value if applicable.
  --next-token: string # The nextToken value returned from a previous paginated ListFargateProfiles request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<fargateProfileNames: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/fargate-profiles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a managed node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster, unless you deploy a custom AMI using a launch template. For more information about using launch templates, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html). An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by Amazon Web Services for an Amazon EKS cluster. For more information, see Managed node groups (https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) in the Amazon EKS User Guide. Windows AMI types are only supported for commercial Regions that support Windows Amazon EKS.
#
# POST /clusters/{name}/node-groups
# operationId: CreateNodegroup
# --scalingConfig shape: {minSize?: any, maxSize?: any, desiredSize?: any}
# --remoteAccess shape: {ec2SshKey?: any, sourceSecurityGroups?: any}
# --taints item shape: {key?: any, value?: any, effect?: any}
# --launchTemplate shape: {name?: any, version?: any, id?: any}
# --updateConfig shape: {maxUnavailable?: any, maxUnavailablePercentage?: any}
export def "clusters-node-groups create-nodegroup" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  nodegroup_name: string # The unique name to give your node group.
  --scaling-config: record # An object representing the scaling configuration details for the Auto Scaling group that is associated with your node group. When creating a node group, you must specify all or none of the properties. When updating a node group, you can specify any or none of the properties. — shape: {minSize?: any, maxSize?: any, desiredSize?: any}
  --disk-size: int # The root device disk size (in GiB) for your node group instances. The default disk size is 20 GiB for Linux and Bottlerocket. The default disk size is 50 GiB for Windows. If you specify launchTemplate, then don't specify diskSize, or the node group deployment will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  subnets: list<string> # The subnets to use for the Auto Scaling group that is created for your node group. If you specify launchTemplate, then don't specify SubnetId (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateNetworkInterface.html) in your launch template, or the node group deployment will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --instance-types: list<string> # Specify the instance types for a node group. If you specify a GPU instance type, make sure to also specify an applicable GPU AMI type with the amiType parameter. If you specify launchTemplate, then you can specify zero or one instance type in your launch template or you can specify 0-20 instance types for instanceTypes. If however, you specify an instance type in your launch template and specify any instanceTypes, the node group deployment will fail. If you don't specify an instance type in a launch template or for instanceTypes, then t3.medium is used, by default. If you specify Spot for capacityType, then we recommend specifying multiple values for instanceTypes. For more information, see Managed node group capacity types (https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html#managed-node-group-capacity-types) and Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --ami-type: string@ami-type-completer # The AMI type for your node group. If you specify launchTemplate, and your launch template uses a custom AMI, then don't specify amiType, or the node group deployment will fail. If your launch template uses a Windows custom AMI, then add eks:kube-proxy-windows to your Windows nodes rolearn in the aws-auth ConfigMap. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --remote-access: record # An object representing the remote access configuration for the managed node group. — shape: {ec2SshKey?: any, sourceSecurityGroups?: any}
  node_role: string # The Amazon Resource Name (ARN) of the IAM role to associate with your node group. The Amazon EKS worker node kubelet daemon makes calls to Amazon Web Services APIs on your behalf. Nodes receive permissions for these API calls through an IAM instance profile and associated policies. Before you can launch nodes and register them into a cluster, you must create an IAM role for those nodes to use when they are launched. For more information, see Amazon EKS node IAM role (https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html) in the Amazon EKS User Guide . If you specify launchTemplate, then don't specify IamInstanceProfile (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_IamInstanceProfile.html) in your launch template, or the node group deployment will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --labels: record # The Kubernetes labels to be applied to the nodes in the node group when they are created.
  --taints: list # The Kubernetes taints to be applied to the nodes in the node group. For more information, see Node taints on managed node groups (https://docs.aws.amazon.com/eks/latest/userguide/node-taints-managed-node-groups.html). — item shape: {key?: any, value?: any, effect?: any}
  --tags: record # The metadata to apply to the node group to assist with categorization and organization. Each tag consists of a key and an optional value. You define both. Node group tags do not propagate to any other resources associated with the node group, such as the Amazon EC2 instances or subnets.
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --launch-template: record # An object representing a node group launch template specification. The launch template can't include SubnetId (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateNetworkInterface.html), IamInstanceProfile (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_IamInstanceProfile.html), RequestSpotInstances (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_RequestSpotInstances.html), HibernationOptions (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_HibernationOptionsRequest.html), or TerminateInstances (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_TerminateInstances.html), or the node group deployment or update will fail. For more information about launch templates, see CreateLaunchTemplate (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateLaunchTemplate.html) in the Amazon EC2 API Reference. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide. You must specify either the launch template ID or the launch template name in the request, but not both. — shape: {name?: any, version?: any, id?: any}
  --update-config: record # The node group update configuration. — shape: {maxUnavailable?: any, maxUnavailablePercentage?: any}
  --capacity-type: string@capacity-type-completer # The capacity type for your node group.
  --version: string # The Kubernetes version to use for your managed nodes. By default, the Kubernetes version of the cluster is used, and this is the only accepted specified value. If you specify launchTemplate, and your launch template uses a custom AMI, then don't specify version, or the node group deployment will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --release-version: string # The AMI version of the Amazon EKS optimized AMI to use with your node group. By default, the latest available AMI version for the node group's current Kubernetes version is used. For information about Linux versions, see Amazon EKS optimized Amazon Linux AMI versions (https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html) in the Amazon EKS User Guide. Amazon EKS managed node groups support the November 2022 and later releases of the Windows AMIs. For information about Windows versions, see Amazon EKS optimized Windows AMI versions (https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-versions-windows.html) in the Amazon EKS User Guide. If you specify launchTemplate, and your launch template uses a custom AMI, then don't specify releaseVersion, or the node group deployment will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
]: any -> record<nodegroup: record<nodegroupName: record, nodegroupArn: record, clusterName: record, version: record, releaseVersion: record, createdAt: record, modifiedAt: record, status: record, capacityType: record, scalingConfig: record<minSize: record, maxSize: record, desiredSize: record>, instanceTypes: record, subnets: record, remoteAccess: record<ec2SshKey: record, sourceSecurityGroups: record>, amiType: record, nodeRole: record, labels: record, taints: record, resources: record<autoScalingGroups: record, remoteAccessSecurityGroup: record>, diskSize: record, health: record<issues: record>, updateConfig: record<maxUnavailable: record, maxUnavailablePercentage: record>, launchTemplate: record<name: record, version: record, id: record>, tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/node-groups"))
  let req_body = {"nodegroupName": $nodegroup_name, "scalingConfig": $scaling_config, "diskSize": $disk_size, "subnets": $subnets, "instanceTypes": $instance_types, "amiType": $ami_type, "remoteAccess": $remote_access, "nodeRole": $node_role, "labels": $labels, "taints": $taints, "tags": $tags, "clientRequestToken": $client_request_token, "launchTemplate": $launch_template, "updateConfig": $update_config, "capacityType": $capacity_type, "version": $version, "releaseVersion": $release_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the Amazon EKS managed node groups associated with the specified cluster in your Amazon Web Services account in the specified Region. Self-managed node groups are not listed.
#
# GET /clusters/{name}/node-groups
# operationId: ListNodegroups
export def "clusters-node-groups list-nodegroups" [
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
  --max-results: int # The maximum number of node group results returned by ListNodegroups in paginated output. When you use this parameter, ListNodegroups returns only maxResults results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListNodegroups request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListNodegroups returns up to 100 results and a nextToken value if applicable.
  --next-token: string # The nextToken value returned from a previous paginated ListNodegroups request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<nodegroups: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/node-groups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete an Amazon EKS add-on. When you remove the add-on, it will also be deleted from the cluster. You can always manually start an add-on on the cluster using the Kubernetes API.
#
# DELETE /clusters/{name}/addons/{addonName}
# operationId: DeleteAddon
export def "clusters-addons delete" [
  name: string
  addon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --preserve: oneof<nothing, bool> # Specifying this option preserves the add-on software on your cluster but Amazon EKS stops managing any settings for the add-on. If an IAM account is associated with the add-on, it isn't removed.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<addon: record<addonName: record, clusterName: record, status: record, addonVersion: record, health: record<issues: record>, addonArn: record, createdAt: record, modifiedAt: record, serviceAccountRoleArn: record, tags: record, publisher: record, owner: record, marketplaceInformation: record<productId: record, productUrl: record>, configurationValues: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "preserve" $preserve "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name), addon_name: (encode-path-segment $addon_name)} | format pattern "/clusters/{name}/addons/{addon_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes an Amazon EKS add-on.
#
# GET /clusters/{name}/addons/{addonName}
# operationId: DescribeAddon
export def "clusters-addons get" [
  name: string
  addon_name: string
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
]: nothing -> record<addon: record<addonName: record, clusterName: record, status: record, addonVersion: record, health: record<issues: record>, addonArn: record, createdAt: record, modifiedAt: record, serviceAccountRoleArn: record, tags: record, publisher: record, owner: record, marketplaceInformation: record<productId: record, productUrl: record>, configurationValues: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name), addon_name: (encode-path-segment $addon_name)} | format pattern "/clusters/{name}/addons/{addon_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes the Amazon EKS cluster control plane. If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see Deleting a Cluster (https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html) in the Amazon EKS User Guide. If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see DeleteNodegroup and DeleteFargateProfile.
#
# DELETE /clusters/{name}
# operationId: DeleteCluster
export def "clusters delete" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<cluster: record<name: record, arn: record, createdAt: record, version: record, endpoint: record, roleArn: record, resourcesVpcConfig: record<subnetIds: record, securityGroupIds: record, clusterSecurityGroupId: record, vpcId: record, endpointPublicAccess: record, endpointPrivateAccess: record, publicAccessCidrs: record>, kubernetesNetworkConfig: record<serviceIpv4Cidr: record, serviceIpv6Cidr: record, ipFamily: record>, logging: record<clusterLogging: record>, identity: record<oidc: record>, status: record, certificateAuthority: record<data: record>, clientRequestToken: record, platformVersion: record, tags: record, encryptionConfig: record, connectorConfig: record<activationId: record, activationCode: record, activationExpiry: record, provider: record, roleArn: record>, id: record, health: record<issues: record>, outpostConfig: record<outpostArns: record, controlPlaneInstanceType: record, controlPlanePlacement: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns descriptive information about an Amazon EKS cluster. The API server endpoint and certificate authority data returned by this operation are required for kubelet and kubectl to communicate with your Kubernetes API server. For more information, see Create a kubeconfig for Amazon EKS (https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html). The API server endpoint and certificate authority data aren't available until the cluster reaches the ACTIVE state.
#
# GET /clusters/{name}
# operationId: DescribeCluster
export def "clusters get" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<cluster: record<name: record, arn: record, createdAt: record, version: record, endpoint: record, roleArn: record, resourcesVpcConfig: record<subnetIds: record, securityGroupIds: record, clusterSecurityGroupId: record, vpcId: record, endpointPublicAccess: record, endpointPrivateAccess: record, publicAccessCidrs: record>, kubernetesNetworkConfig: record<serviceIpv4Cidr: record, serviceIpv6Cidr: record, ipFamily: record>, logging: record<clusterLogging: record>, identity: record<oidc: record>, status: record, certificateAuthority: record<data: record>, clientRequestToken: record, platformVersion: record, tags: record, encryptionConfig: record, connectorConfig: record<activationId: record, activationCode: record, activationExpiry: record, provider: record, roleArn: record>, id: record, health: record<issues: record>, outpostConfig: record<outpostArns: record, controlPlaneInstanceType: record, controlPlanePlacement: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes an Fargate profile. When you delete a Fargate profile, any pods running on Fargate that were created with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate and they may remain in a pending state. Only one Fargate profile in a cluster can be in the DELETING status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.
#
# DELETE /clusters/{name}/fargate-profiles/{fargateProfileName}
# operationId: DeleteFargateProfile
export def "clusters-fargate-profiles delete" [
  name: string
  fargate_profile_name: string
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
]: nothing -> record<fargateProfile: record<fargateProfileName: record, fargateProfileArn: record, clusterName: record, createdAt: record, podExecutionRoleArn: record, subnets: record, selectors: record, status: record, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name), fargate_profile_name: (encode-path-segment $fargate_profile_name)} | format pattern "/clusters/{name}/fargate-profiles/{fargate_profile_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns descriptive information about an Fargate profile.
#
# GET /clusters/{name}/fargate-profiles/{fargateProfileName}
# operationId: DescribeFargateProfile
export def "clusters-fargate-profiles get" [
  name: string
  fargate_profile_name: string
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
]: nothing -> record<fargateProfile: record<fargateProfileName: record, fargateProfileArn: record, clusterName: record, createdAt: record, podExecutionRoleArn: record, subnets: record, selectors: record, status: record, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name), fargate_profile_name: (encode-path-segment $fargate_profile_name)} | format pattern "/clusters/{name}/fargate-profiles/{fargate_profile_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes an Amazon EKS node group for a cluster.
#
# DELETE /clusters/{name}/node-groups/{nodegroupName}
# operationId: DeleteNodegroup
export def "clusters-node-groups delete-nodegroup" [
  name: string
  nodegroup_name: string
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
]: nothing -> record<nodegroup: record<nodegroupName: record, nodegroupArn: record, clusterName: record, version: record, releaseVersion: record, createdAt: record, modifiedAt: record, status: record, capacityType: record, scalingConfig: record<minSize: record, maxSize: record, desiredSize: record>, instanceTypes: record, subnets: record, remoteAccess: record<ec2SshKey: record, sourceSecurityGroups: record>, amiType: record, nodeRole: record, labels: record, taints: record, resources: record<autoScalingGroups: record, remoteAccessSecurityGroup: record>, diskSize: record, health: record<issues: record>, updateConfig: record<maxUnavailable: record, maxUnavailablePercentage: record>, launchTemplate: record<name: record, version: record, id: record>, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name), nodegroup_name: (encode-path-segment $nodegroup_name)} | format pattern "/clusters/{name}/node-groups/{nodegroup_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns descriptive information about an Amazon EKS node group.
#
# GET /clusters/{name}/node-groups/{nodegroupName}
# operationId: DescribeNodegroup
export def "clusters-node-groups get-nodegroup" [
  name: string
  nodegroup_name: string
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
]: nothing -> record<nodegroup: record<nodegroupName: record, nodegroupArn: record, clusterName: record, version: record, releaseVersion: record, createdAt: record, modifiedAt: record, status: record, capacityType: record, scalingConfig: record<minSize: record, maxSize: record, desiredSize: record>, instanceTypes: record, subnets: record, remoteAccess: record<ec2SshKey: record, sourceSecurityGroups: record>, amiType: record, nodeRole: record, labels: record, taints: record, resources: record<autoScalingGroups: record, remoteAccessSecurityGroup: record>, diskSize: record, health: record<issues: record>, updateConfig: record<maxUnavailable: record, maxUnavailablePercentage: record>, launchTemplate: record<name: record, version: record, id: record>, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name), nodegroup_name: (encode-path-segment $nodegroup_name)} | format pattern "/clusters/{name}/node-groups/{nodegroup_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deregisters a connected cluster to remove it from the Amazon EKS control plane.
#
# DELETE /cluster-registrations/{name}
# operationId: DeregisterCluster
export def "cluster-registrations delete-deregister" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<cluster: record<name: record, arn: record, createdAt: record, version: record, endpoint: record, roleArn: record, resourcesVpcConfig: record<subnetIds: record, securityGroupIds: record, clusterSecurityGroupId: record, vpcId: record, endpointPublicAccess: record, endpointPrivateAccess: record, publicAccessCidrs: record>, kubernetesNetworkConfig: record<serviceIpv4Cidr: record, serviceIpv6Cidr: record, ipFamily: record>, logging: record<clusterLogging: record>, identity: record<oidc: record>, status: record, certificateAuthority: record<data: record>, clientRequestToken: record, platformVersion: record, tags: record, encryptionConfig: record, connectorConfig: record<activationId: record, activationCode: record, activationExpiry: record, provider: record, roleArn: record>, id: record, health: record<issues: record>, outpostConfig: record<outpostArns: record, controlPlaneInstanceType: record, controlPlanePlacement: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/cluster-registrations/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns configuration options.
#
# GET /addons/configuration-schemas#addonName&addonVersion
# operationId: DescribeAddonConfiguration
export def "addons-configuration-schemasaddon-nameaddon-version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --addon-name: string # The name of the add-on. The name must match one of the names that DescribeAddonVersions (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonVersions.html) returns.
  --addon-version: string # The version of the add-on. The version must match one of the versions returned by DescribeAddonVersions (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonVersions.html).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<addonName: record, addonVersion: record, configurationSchema: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "addonName" $addon_name "scalar") (serialize-qp "addonVersion" $addon_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/addons/configuration-schemas#addonName&addonVersion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes the versions for an add-on. Information such as the Kubernetes versions that you can use the add-on with, the owner, publisher, and the type of the add-on are returned.
#
# GET /addons/supported-versions
# operationId: DescribeAddonVersions
export def "addons-supported-versions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kubernetes-version: string # The Kubernetes versions that you can use the add-on with.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The nextToken value returned from a previous paginated DescribeAddonVersionsRequest where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.
  --addon-name: string # The name of the add-on. The name must match one of the names returned by ListAddons (https://docs.aws.amazon.com/eks/latest/APIReference/API_ListAddons.html).
  --types: list # The type of the add-on. For valid types, don't specify a value for this property.
  --publishers: list # The publisher of the add-on. For valid publishers, don't specify a value for this property.
  --owners: list # The owner of the add-on. For valid owners, don't specify a value for this property.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<addons: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kubernetesVersion" $kubernetes_version "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "addonName" $addon_name "scalar") (serialize-qp "types" $types "multi") (serialize-qp "publishers" $publishers "multi") (serialize-qp "owners" $owners "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/addons/supported-versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns descriptive information about an identity provider configuration.
#
# POST /clusters/{name}/identity-provider-configs/describe
# operationId: DescribeIdentityProviderConfig
# --identityProviderConfig shape: {type?: any, name?: any}
export def "clusters-identity-provider-configs-describe get" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  identity_provider_config: record # An object representing an identity provider configuration. — shape: {type?: any, name?: any}
]: any -> record<identityProviderConfig: record<oidc: record<identityProviderConfigName: record, identityProviderConfigArn: record, clusterName: record, issuerUrl: record, clientId: record, usernameClaim: record, usernamePrefix: record, groupsClaim: record, groupsPrefix: record, requiredClaims: record, tags: record, status: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/identity-provider-configs/describe"))
  let req_body = {"identityProviderConfig": $identity_provider_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group or Amazon EKS add-on. When the status of the update is Succeeded, the update is complete. If an update fails, the status is Failed, and an error detail explains the reason for the failure.
#
# GET /clusters/{name}/updates/{updateId}
# operationId: DescribeUpdate
export def "clusters-updates get" [
  name: string
  update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --nodegroup-name: string # The name of the Amazon EKS node group associated with the update. This parameter is required if the update is a node group update.
  --addon-name: string # The name of the add-on. The name must match one of the names returned by ListAddons (https://docs.aws.amazon.com/eks/latest/APIReference/API_ListAddons.html). This parameter is required if the update is an add-on update.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<update: record<id: record, status: record, type: record, params: record, createdAt: record, errors: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nodegroupName" $nodegroup_name "scalar") (serialize-qp "addonName" $addon_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name), update_id: (encode-path-segment $update_id)} | format pattern "/clusters/{name}/updates/{update_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Disassociates an identity provider configuration from a cluster. If you disassociate an identity provider from your cluster, users included in the provider can no longer access the cluster. However, you can still access the cluster with Amazon Web Services IAM users.
#
# POST /clusters/{name}/identity-provider-configs/disassociate
# operationId: DisassociateIdentityProviderConfig
# --identityProviderConfig shape: {type?: any, name?: any}
export def "clusters-identity-provider-configs-disassociate create" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  identity_provider_config: record # An object representing an identity provider configuration. — shape: {type?: any, name?: any}
  --client-request-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> record<update: record<id: record, status: record, type: record, params: record, createdAt: record, errors: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/identity-provider-configs/disassociate"))
  let req_body = {"identityProviderConfig": $identity_provider_config, "clientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# A list of identity provider configurations.
#
# GET /clusters/{name}/identity-provider-configs
# operationId: ListIdentityProviderConfigs
export def "clusters-identity-provider-configs list" [
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
  --max-results: int # The maximum number of identity provider configurations returned by ListIdentityProviderConfigs in paginated output. When you use this parameter, ListIdentityProviderConfigs returns only maxResults results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListIdentityProviderConfigs request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListIdentityProviderConfigs returns up to 100 results and a nextToken value, if applicable.
  --next-token: string # The nextToken value returned from a previous paginated IdentityProviderConfigsRequest where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<identityProviderConfigs: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/identity-provider-configs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List the tags for an Amazon EKS resource.
#
# GET /tags/{resourceArn}
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
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and nodes associated with the cluster.
#
# POST /tags/{resourceArn}
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
  tags: record # The tags to add to the resource. A tag is an array of key-value pairs.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the updates associated with an Amazon EKS cluster or managed node group in your Amazon Web Services account, in the specified Region.
#
# GET /clusters/{name}/updates
# operationId: ListUpdates
export def "clusters-updates list" [
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
  --nodegroup-name: string # The name of the Amazon EKS managed node group to list updates for.
  --addon-name: string # The names of the installed add-ons that have available updates.
  --next-token: string # The nextToken value returned from a previous paginated ListUpdates request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
  --max-results: int # The maximum number of update results returned by ListUpdates in paginated output. When you use this parameter, ListUpdates returns only maxResults results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListUpdates request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListUpdates returns up to 100 results and a nextToken value if applicable.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<updateIds: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nodegroupName" $nodegroup_name "scalar") (serialize-qp "addonName" $addon_name "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/updates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the DescribeUpdate API operation. Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to UPDATING (this status transition is eventually consistent). When the update is complete (either Failed or Successful), the cluster status moves to Active. If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.
#
# POST /clusters/{name}/updates
# operationId: UpdateClusterVersion
export def "clusters-updates version" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  version: string # The desired Kubernetes version following a successful update.
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> record<update: record<id: record, status: record, type: record, params: record, createdAt: record, errors: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/updates"))
  let req_body = {"version": $version, "clientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Connects a Kubernetes cluster to the Amazon EKS control plane. Any Kubernetes cluster can be connected to the Amazon EKS control plane to view current information about the cluster and its nodes. Cluster connection requires two steps. First, send a RegisterClusterRequest to add it to the Amazon EKS control plane. Second, a Manifest (https://amazon-eks.s3.us-west-2.amazonaws.com/eks-connector/manifests/eks-connector/latest/eks-connector.yaml) containing the activationID and activationCode must be applied to the Kubernetes cluster through it's native provider to provide visibility. After the Manifest is updated and applied, then the connected cluster is visible to the Amazon EKS control plane. If the Manifest is not applied within three days, then the connected cluster will no longer be visible and must be deregistered. See DeregisterCluster.
#
# POST /cluster-registrations
# operationId: RegisterCluster
# --connectorConfig shape: {roleArn?: any, provider?: any}
export def "cluster-registrations create" [
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
  name: string # Define a unique name for this cluster for your Region.
  connector_config: record # The configuration sent to a cluster for configuration. — shape: {roleArn?: any, provider?: any}
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --tags: record # The metadata that you apply to the cluster to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Cluster tags do not propagate to any other resources associated with the cluster.
]: any -> record<cluster: record<name: record, arn: record, createdAt: record, version: record, endpoint: record, roleArn: record, resourcesVpcConfig: record<subnetIds: record, securityGroupIds: record, clusterSecurityGroupId: record, vpcId: record, endpointPublicAccess: record, endpointPrivateAccess: record, publicAccessCidrs: record>, kubernetesNetworkConfig: record<serviceIpv4Cidr: record, serviceIpv6Cidr: record, ipFamily: record>, logging: record<clusterLogging: record>, identity: record<oidc: record>, status: record, certificateAuthority: record<data: record>, clientRequestToken: record, platformVersion: record, tags: record, encryptionConfig: record, connectorConfig: record<activationId: record, activationCode: record, activationExpiry: record, provider: record, roleArn: record>, id: record, health: record<issues: record>, outpostConfig: record<outpostArns: record, controlPlaneInstanceType: record, controlPlanePlacement: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cluster-registrations")
  let req_body = {"name": $name, "connectorConfig": $connector_config, "clientRequestToken": $client_request_token, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes specified tags from a resource.
#
# DELETE /tags/{resourceArn}#tagKeys
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
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}#tagKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an Amazon EKS add-on.
#
# POST /clusters/{name}/addons/{addonName}/update
# operationId: UpdateAddon
export def "clusters-addons-update update" [
  name: string
  addon_name: string
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
  --addon-version: string # The version of the add-on. The version must match one of the versions returned by DescribeAddonVersions (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonVersions.html).
  --service-account-role-arn: string # The Amazon Resource Name (ARN) of an existing IAM role to bind to the add-on's service account. The role must be assigned the IAM permissions required by the add-on. If you don't specify an existing IAM role, then the add-on uses the permissions assigned to the node IAM role. For more information, see Amazon EKS node IAM role (https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html) in the Amazon EKS User Guide. To specify an existing IAM role, you must have an IAM OpenID Connect (OIDC) provider created for your cluster. For more information, see Enabling IAM roles for service accounts on your cluster (https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html) in the Amazon EKS User Guide.
  --resolve-conflicts: string@resolve-conflicts-completer # How to resolve field value conflicts for an Amazon EKS add-on if you've changed a value from the Amazon EKS default value. Conflicts are handled based on the option you choose: None – Amazon EKS doesn't change the value. The update might fail. Overwrite – Amazon EKS overwrites the changed value back to the Amazon EKS default value. Preserve – Amazon EKS preserves the value. If you choose this option, we recommend that you test any field and value changes on a non-production cluster before updating the add-on on your production cluster.
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --configuration-values: string # The set of configuration values for the add-on that's created. The values that you provide are validated against the schema in DescribeAddonConfiguration (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonConfiguration.html).
]: any -> record<update: record<id: record, status: record, type: record, params: record, createdAt: record, errors: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name), addon_name: (encode-path-segment $addon_name)} | format pattern "/clusters/{name}/addons/{addon_name}/update"))
  let req_body = {"addonVersion": $addon_version, "serviceAccountRoleArn": $service_account_role_arn, "resolveConflicts": $resolve_conflicts, "clientRequestToken": $client_request_token, "configurationValues": $configuration_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the DescribeUpdate API operation. You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see Amazon EKS Cluster Control Plane Logs (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html) in the Amazon EKS User Guide . CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see CloudWatch Pricing (http://aws.amazon.com/cloudwatch/pricing/). You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see Amazon EKS cluster endpoint access control (https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html) in the Amazon EKS User Guide . You can't update the subnets or security group IDs for an existing cluster. Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to UPDATING (this status transition is eventually consistent). When the update is complete (either Failed or Successful), the cluster status moves to Active.
#
# POST /clusters/{name}/update-config
# operationId: UpdateClusterConfig
# --resourcesVpcConfig shape: {subnetIds?: any, securityGroupIds?: any, endpointPublicAccess?: any, endpointPrivateAccess?: any, publicAccessCidrs?: any}
# --logging shape: {clusterLogging?: any}
export def "clusters-update-config update" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --resources-vpc-config: record # An object representing the VPC configuration to use for an Amazon EKS cluster. — shape: {subnetIds?: any, securityGroupIds?: any, endpointPublicAccess?: any, endpointPrivateAccess?: any, publicAccessCidrs?: any}
  --logging: record # An object representing the logging configuration for resources in your cluster. — shape: {clusterLogging?: any}
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> record<update: record<id: record, status: record, type: record, params: record, createdAt: record, errors: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clusters/{name}/update-config"))
  let req_body = {"resourcesVpcConfig": $resources_vpc_config, "logging": $logging, "clientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the DescribeUpdate API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
#
# POST /clusters/{name}/node-groups/{nodegroupName}/update-config
# operationId: UpdateNodegroupConfig
# --labels shape: {addOrUpdateLabels?: any, removeLabels?: any}
# --taints shape: {addOrUpdateTaints?: any, removeTaints?: any}
# --scalingConfig shape: {minSize?: any, maxSize?: any, desiredSize?: any}
# --updateConfig shape: {maxUnavailable?: any, maxUnavailablePercentage?: any}
export def "clusters-node-groups-update-config update-nodegroup" [
  name: string
  nodegroup_name: string
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
  --labels: record # An object representing a Kubernetes label change for a managed node group. — shape: {addOrUpdateLabels?: any, removeLabels?: any}
  --taints: record # An object representing the details of an update to a taints payload. For more information, see Node taints on managed node groups (https://docs.aws.amazon.com/eks/latest/userguide/node-taints-managed-node-groups.html). — shape: {addOrUpdateTaints?: any, removeTaints?: any}
  --scaling-config: record # An object representing the scaling configuration details for the Auto Scaling group that is associated with your node group. When creating a node group, you must specify all or none of the properties. When updating a node group, you can specify any or none of the properties. — shape: {minSize?: any, maxSize?: any, desiredSize?: any}
  --update-config: record # The node group update configuration. — shape: {maxUnavailable?: any, maxUnavailablePercentage?: any}
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> record<update: record<id: record, status: record, type: record, params: record, createdAt: record, errors: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name), nodegroup_name: (encode-path-segment $nodegroup_name)} | format pattern "/clusters/{name}/node-groups/{nodegroup_name}/update-config"))
  let req_body = {"labels": $labels, "taints": $taints, "scalingConfig": $scaling_config, "updateConfig": $update_config, "clientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates the Kubernetes version or AMI version of an Amazon EKS managed node group. You can update a node group using a launch template only if the node group was originally deployed with a launch template. If you need to update a custom AMI in a node group that was deployed with a launch template, then update your custom AMI, specify the new ID in a new version of the launch template, and then update the node group to the new version of the launch template. If you update without a launch template, then you can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For information about Linux versions, see Amazon EKS optimized Amazon Linux AMI versions (https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html) in the Amazon EKS User Guide. For information about Windows versions, see Amazon EKS optimized Windows AMI versions (https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-versions-windows.html) in the Amazon EKS User Guide. You cannot roll back a node group to an earlier Kubernetes version or AMI version. When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can force the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.
#
# POST /clusters/{name}/node-groups/{nodegroupName}/update-version
# operationId: UpdateNodegroupVersion
# --launchTemplate shape: {name?: any, version?: any, id?: any}
export def "clusters-node-groups-update-version update-nodegroup" [
  name: string
  nodegroup_name: string
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
  --version: string # The Kubernetes version to update to. If no version is specified, then the Kubernetes version of the node group does not change. You can specify the Kubernetes version of the cluster to update the node group to the latest AMI version of the cluster's Kubernetes version. If you specify launchTemplate, and your launch template uses a custom AMI, then don't specify version, or the node group update will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --release-version: string # The AMI version of the Amazon EKS optimized AMI to use for the update. By default, the latest available AMI version for the node group's Kubernetes version is used. For information about Linux versions, see Amazon EKS optimized Amazon Linux AMI versions (https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html) in the Amazon EKS User Guide. Amazon EKS managed node groups support the November 2022 and later releases of the Windows AMIs. For information about Windows versions, see Amazon EKS optimized Windows AMI versions (https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-versions-windows.html) in the Amazon EKS User Guide. If you specify launchTemplate, and your launch template uses a custom AMI, then don't specify releaseVersion, or the node group update will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --launch-template: record # An object representing a node group launch template specification. The launch template can't include SubnetId (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateNetworkInterface.html), IamInstanceProfile (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_IamInstanceProfile.html), RequestSpotInstances (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_RequestSpotInstances.html), HibernationOptions (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_HibernationOptionsRequest.html), or TerminateInstances (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_TerminateInstances.html), or the node group deployment or update will fail. For more information about launch templates, see CreateLaunchTemplate (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateLaunchTemplate.html) in the Amazon EC2 API Reference. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide. You must specify either the launch template ID or the launch template name in the request, but not both. — shape: {name?: any, version?: any, id?: any}
  --force: oneof<nothing, bool> # Force the update if the existing node group's pods are unable to be drained due to a pod disruption budget issue. If an update fails because pods could not be drained, you can force the update after it fails to terminate the old node whether or not any pods are running on the node.
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> record<update: record<id: record, status: record, type: record, params: record, createdAt: record, errors: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name), nodegroup_name: (encode-path-segment $nodegroup_name)} | format pattern "/clusters/{name}/node-groups/{nodegroup_name}/update-version"))
  let req_body = {"version": $version, "releaseVersion": $release_version, "launchTemplate": $launch_template, "force": $force, "clientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
