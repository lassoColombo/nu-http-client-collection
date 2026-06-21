# Auto-generated client for AmazonMQ v2017-11-27
# Source: https://api.apis.guru/v2/specs/amazonaws.com/mq/2017-11-27/openapi.json
# Auth: --token flag or $env.AMAZONMQ_TOKEN

const BASE_URL = "http://mq.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZONMQ_TOKEN | default "" }
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

def base-url-completer [] { ["http://mq.us-east-1.amazonaws.com" "http://mq.us-east-2.amazonaws.com" "http://mq.us-west-1.amazonaws.com" "http://mq.us-west-2.amazonaws.com" "http://mq.us-gov-west-1.amazonaws.com" "http://mq.us-gov-east-1.amazonaws.com" "http://mq.ca-central-1.amazonaws.com" "http://mq.eu-north-1.amazonaws.com" "http://mq.eu-west-1.amazonaws.com" "http://mq.eu-west-2.amazonaws.com" "http://mq.eu-west-3.amazonaws.com" "http://mq.eu-central-1.amazonaws.com" "http://mq.eu-south-1.amazonaws.com" "http://mq.af-south-1.amazonaws.com" "http://mq.ap-northeast-1.amazonaws.com" "http://mq.ap-northeast-2.amazonaws.com" "http://mq.ap-northeast-3.amazonaws.com" "http://mq.ap-southeast-1.amazonaws.com" "http://mq.ap-southeast-2.amazonaws.com" "http://mq.ap-east-1.amazonaws.com" "http://mq.ap-south-1.amazonaws.com" "http://mq.sa-east-1.amazonaws.com" "http://mq.me-south-1.amazonaws.com" "https://mq.us-east-1.amazonaws.com" "https://mq.us-east-2.amazonaws.com" "https://mq.us-west-1.amazonaws.com" "https://mq.us-west-2.amazonaws.com" "https://mq.us-gov-west-1.amazonaws.com" "https://mq.us-gov-east-1.amazonaws.com" "https://mq.ca-central-1.amazonaws.com" "https://mq.eu-north-1.amazonaws.com" "https://mq.eu-west-1.amazonaws.com" "https://mq.eu-west-2.amazonaws.com" "https://mq.eu-west-3.amazonaws.com" "https://mq.eu-central-1.amazonaws.com" "https://mq.eu-south-1.amazonaws.com" "https://mq.af-south-1.amazonaws.com" "https://mq.ap-northeast-1.amazonaws.com" "https://mq.ap-northeast-2.amazonaws.com" "https://mq.ap-northeast-3.amazonaws.com" "https://mq.ap-southeast-1.amazonaws.com" "https://mq.ap-southeast-2.amazonaws.com" "https://mq.ap-east-1.amazonaws.com" "https://mq.ap-south-1.amazonaws.com" "https://mq.sa-east-1.amazonaws.com" "https://mq.me-south-1.amazonaws.com" "http://mq.cn-north-1.amazonaws.com.cn" "http://mq.cn-northwest-1.amazonaws.com.cn" "https://mq.cn-north-1.amazonaws.com.cn" "https://mq.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def authentication-strategy-completer [] { ["LDAP" "SIMPLE"] }
def deployment-mode-completer [] { ["ACTIVE_STANDBY_MULTI_AZ" "CLUSTER_MULTI_AZ" "SINGLE_INSTANCE"] }
def engine-type-completer [] { ["ACTIVEMQ" "RABBITMQ"] }
def storage-type-completer [] { ["EBS" "EFS"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "brokers create" } } | get name | first)
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

# Creates a broker. Note: This API is asynchronous. To create a broker, you must either use the AmazonMQFullAccess IAM policy or include the following EC2 permissions in your IAM policy. ec2:CreateNetworkInterface This permission is required to allow Amazon MQ to create an elastic network interface (ENI) on behalf of your account. ec2:CreateNetworkInterfacePermission This permission is required to attach the ENI to the broker instance. ec2:DeleteNetworkInterface ec2:DeleteNetworkInterfacePermission ec2:DetachNetworkInterface ec2:DescribeInternetGateways ec2:DescribeNetworkInterfaces ec2:DescribeNetworkInterfacePermissions ec2:DescribeRouteTables ec2:DescribeSecurityGroups ec2:DescribeSubnets ec2:DescribeVpcs For more information, see Create an IAM User and Get Your AWS Credentials (https://docs.aws.amazon.com//amazon-mq/latest/developer-guide/amazon-mq-setting-up.html#create-iam-user) and Never Modify or Delete the Amazon MQ Elastic Network Interface (https://docs.aws.amazon.com/amazon-mq/latest/developer-guide/connecting-to-amazon-mq.html#never-modify-delete-elastic-network-interface) in the Amazon MQ Developer Guide.
#
# POST /v1/brokers
# operationId: CreateBroker
# --configuration shape: {Id?: any, Revision?: any}
# --encryptionOptions shape: {KmsKeyId?: any, UseAwsOwnedKey?: any}
# --ldapServerMetadata shape: {Hosts?: any, RoleBase?: any, RoleName?: any, RoleSearchMatching?: any, RoleSearchSubtree?: any, ServiceAccountPassword?: any, ServiceAccountUsername?: any, UserBase?: any, UserRoleName?: any, UserSearchMatching?: any, UserSearchSubtree?: any}
# --logs shape: {Audit?: any, General?: any}
# --maintenanceWindowStartTime shape: {DayOfWeek?: any, TimeOfDay?: any, TimeZone?: any}
# --users item shape: {ConsoleAccess?: any, Groups?: any, Password: any, Username: any}
export def "brokers create" [
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
  --authentication-strategy: string@authentication-strategy-completer # Optional. The authentication strategy used to secure the broker. The default is SIMPLE.
  --auto-minor-version-upgrade: oneof<nothing, bool> # Enables automatic upgrades to new minor versions for brokers, as new versions are released and supported by Amazon MQ. Automatic upgrades occur during the scheduled maintenance window of the broker or after a manual broker reboot. Set to true by default, if no value is specified.
  broker_name: string # Required. The broker's name. This value must be unique in your AWS account, 1-50 characters long, must contain only letters, numbers, dashes, and underscores, and must not contain white spaces, brackets, wildcard characters, or special characters.
  --configuration: record # A list of information about the configuration. Does not apply to RabbitMQ brokers. — shape: {Id?: any, Revision?: any}
  --creator-request-id: string # The unique ID that the requester receives for the created broker. Amazon MQ passes your ID with the API action. Note: We recommend using a Universally Unique Identifier (UUID) for the creatorRequestId. You may omit the creatorRequestId if your application doesn't require idempotency.
  deployment_mode: string@deployment-mode-completer # The broker's deployment mode.
  --encryption-options: record # Does not apply to RabbitMQ brokers. Encryption options for the broker. — shape: {KmsKeyId?: any, UseAwsOwnedKey?: any}
  engine_type: string@engine-type-completer # The type of broker engine. Amazon MQ supports ActiveMQ and RabbitMQ.
  engine_version: string # Required. The broker engine's version. For a list of supported engine versions, see Supported engines (https://docs.aws.amazon.com//amazon-mq/latest/developer-guide/broker-engine.html).
  host_instance_type: string # Required. The broker's instance type.
  --ldap-server-metadata: record # Optional. The metadata of the LDAP server used to authenticate and authorize connections to the broker. Does not apply to RabbitMQ brokers. — shape: {Hosts?: any, RoleBase?: any, RoleName?: any, RoleSearchMatching?: any, RoleSearchSubtree?: any, ServiceAccountPassword?: any, ServiceAccountUsername?: any, UserBase?: any, UserRoleName?: any, UserSearchMatching?: any, UserSearchSubtree?: any}
  --logs: record # The list of information about logs to be enabled for the specified broker. — shape: {Audit?: any, General?: any}
  --maintenance-window-start-time: record # The scheduled time period relative to UTC during which Amazon MQ begins to apply pending updates or patches to the broker. — shape: {DayOfWeek?: any, TimeOfDay?: any, TimeZone?: any}
  --publicly-accessible: oneof<nothing, bool> # Enables connections from applications outside of the VPC that hosts the broker's subnets. Set to false by default, if no value is provided.
  --security-groups: list<string> # The list of rules (1 minimum, 125 maximum) that authorize connections to brokers.
  --storage-type: string@storage-type-completer # The broker's storage type. EFS is not supported for RabbitMQ engine type.
  --subnet-ids: list<string> # The list of groups that define which subnets and IP ranges the broker can use from different Availability Zones. If you specify more than one subnet, the subnets must be in different Availability Zones. Amazon MQ will not be able to create VPC endpoints for your broker with multiple subnets in the same Availability Zone. A SINGLE_INSTANCE deployment requires one subnet (for example, the default subnet). An ACTIVE_STANDBY_MULTI_AZ Amazon MQ for ActiveMQ deployment requires two subnets. A CLUSTER_MULTI_AZ Amazon MQ for RabbitMQ deployment has no subnet requirements when deployed with public accessibility. Deployment without public accessibility requires at least one subnet. If you specify subnets in a shared VPC (https://docs.aws.amazon.com/vpc/latest/userguide/vpc-sharing.html) for a RabbitMQ broker, the associated VPC to which the specified subnets belong must be owned by your AWS account. Amazon MQ will not be able to create VPC endpoints in VPCs that are not owned by your AWS account.
  --tags: record # Create tags when creating the broker.
  users: list # Required. The list of broker users (persons or applications) who can access queues and topics. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long. Amazon MQ for RabbitMQ When you create an Amazon MQ for RabbitMQ broker, one and only one administrative user is accepted and created when a broker is first provisioned. All subsequent broker users are created by making RabbitMQ API calls directly to brokers or via the RabbitMQ web console. — item shape: {ConsoleAccess?: any, Groups?: any, Password: any, Username: any}
]: any -> record<BrokerArn: record, BrokerId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/brokers")
  let req_body = {"authenticationStrategy": $authentication_strategy, "autoMinorVersionUpgrade": $auto_minor_version_upgrade, "brokerName": $broker_name, "configuration": $configuration, "creatorRequestId": $creator_request_id, "deploymentMode": $deployment_mode, "encryptionOptions": $encryption_options, "engineType": $engine_type, "engineVersion": $engine_version, "hostInstanceType": $host_instance_type, "ldapServerMetadata": $ldap_server_metadata, "logs": $logs, "maintenanceWindowStartTime": $maintenance_window_start_time, "publiclyAccessible": $publicly_accessible, "securityGroups": $security_groups, "storageType": $storage_type, "subnetIds": $subnet_ids, "tags": $tags, "users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of all brokers.
#
# GET /v1/brokers
# operationId: ListBrokers
export def "brokers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  --next-token: string # The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<BrokerSummaries: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/brokers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates a new configuration for the specified configuration name. Amazon MQ uses the default configuration (the engine type and version).
#
# POST /v1/configurations
# operationId: CreateConfiguration
export def "configurations create" [
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
  --authentication-strategy: string@authentication-strategy-completer # Optional. The authentication strategy used to secure the broker. The default is SIMPLE.
  engine_type: string@engine-type-completer # The type of broker engine. Amazon MQ supports ActiveMQ and RabbitMQ.
  engine_version: string # Required. The broker engine's version. For a list of supported engine versions, see Supported engines (https://docs.aws.amazon.com//amazon-mq/latest/developer-guide/broker-engine.html).
  name: string # Required. The name of the configuration. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 1-150 characters long.
  --tags: record # Create tags when creating the configuration.
]: any -> record<Arn: record, AuthenticationStrategy: record, Created: record, Id: record, LatestRevision: record<Created: record, Description: record, Revision: record>, Name: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/configurations")
  let req_body = {"authenticationStrategy": $authentication_strategy, "engineType": $engine_type, "engineVersion": $engine_version, "name": $name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of all configurations.
#
# GET /v1/configurations
# operationId: ListConfigurations
export def "configurations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  --next-token: string # The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Configurations: record, MaxResults: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/configurations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Add a tag to a resource.
#
# POST /v1/tags/{resource-arn}
# operationId: CreateTags
export def "tags create" [
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
  --tags: record # The key-value pair for the resource tag.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists tags for a resource.
#
# GET /v1/tags/{resource-arn}
# operationId: ListTags
export def "tags list" [
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
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates an ActiveMQ user.
#
# POST /v1/brokers/{broker-id}/users/{username}
# operationId: CreateUser
export def "brokers-users create" [
  broker_id: string
  username: string
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
  --console-access: oneof<nothing, bool> # Enables access to the ActiveMQ Web Console for the ActiveMQ user.
  --groups: list<string> # The list of groups (20 maximum) to which the ActiveMQ user belongs. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  password: string # Required. The password of the user. This value must be at least 12 characters long, must contain at least 4 unique characters, and must not contain commas, colons, or equal signs (,:=).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($broker_id | is-empty) { error make --unspanned { msg: "path parameter 'broker-id' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({broker_id: (encode-path-segment $broker_id), username: (encode-path-segment $username)} | format pattern "/v1/brokers/{broker_id}/users/{username}"))
  let req_body = {"consoleAccess": $console_access, "groups": $groups, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an ActiveMQ user.
#
# DELETE /v1/brokers/{broker-id}/users/{username}
# operationId: DeleteUser
export def "brokers-users delete" [
  broker_id: string
  username: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($broker_id | is-empty) { error make --unspanned { msg: "path parameter 'broker-id' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({broker_id: (encode-path-segment $broker_id), username: (encode-path-segment $username)} | format pattern "/v1/brokers/{broker_id}/users/{username}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns information about an ActiveMQ user.
#
# GET /v1/brokers/{broker-id}/users/{username}
# operationId: DescribeUser
export def "brokers-users get" [
  broker_id: string
  username: string
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
]: nothing -> record<BrokerId: record, ConsoleAccess: record, Groups: record, Pending: record<ConsoleAccess: record, Groups: record, PendingChange: record>, Username: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($broker_id | is-empty) { error make --unspanned { msg: "path parameter 'broker-id' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({broker_id: (encode-path-segment $broker_id), username: (encode-path-segment $username)} | format pattern "/v1/brokers/{broker_id}/users/{username}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the information for an ActiveMQ user.
#
# PUT /v1/brokers/{broker-id}/users/{username}
# operationId: UpdateUser
export def "brokers-users update" [
  broker_id: string
  username: string
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
  --console-access: oneof<nothing, bool> # Enables access to the the ActiveMQ Web Console for the ActiveMQ user.
  --groups: list<string> # The list of groups (20 maximum) to which the ActiveMQ user belongs. This value can contain only alphanumeric characters, dashes, periods, underscores, and tildes (- . _ ~). This value must be 2-100 characters long.
  --password: string # The password of the user. This value must be at least 12 characters long, must contain at least 4 unique characters, and must not contain commas, colons, or equal signs (,:=).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($broker_id | is-empty) { error make --unspanned { msg: "path parameter 'broker-id' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({broker_id: (encode-path-segment $broker_id), username: (encode-path-segment $username)} | format pattern "/v1/brokers/{broker_id}/users/{username}"))
  let req_body = {"consoleAccess": $console_access, "groups": $groups, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a broker. Note: This API is asynchronous.
#
# DELETE /v1/brokers/{broker-id}
# operationId: DeleteBroker
export def "brokers delete" [
  broker_id: string
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
]: nothing -> record<BrokerId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($broker_id | is-empty) { error make --unspanned { msg: "path parameter 'broker-id' must be non-empty" } }
  let full_url = (build-url $base ({broker_id: (encode-path-segment $broker_id)} | format pattern "/v1/brokers/{broker_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns information about the specified broker.
#
# GET /v1/brokers/{broker-id}
# operationId: DescribeBroker
export def "brokers get" [
  broker_id: string
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
]: nothing -> record<ActionsRequired: record, AuthenticationStrategy: record, AutoMinorVersionUpgrade: record, BrokerArn: record, BrokerId: record, BrokerInstances: record, BrokerName: record, BrokerState: record, Configurations: record<Current: record<Id: record, Revision: record>, History: record, Pending: record<Id: record, Revision: record>>, Created: record, DeploymentMode: record, EncryptionOptions: record<KmsKeyId: record, UseAwsOwnedKey: record>, EngineType: record, EngineVersion: record, HostInstanceType: record, LdapServerMetadata: record<Hosts: record, RoleBase: record, RoleName: record, RoleSearchMatching: record, RoleSearchSubtree: record, ServiceAccountUsername: record, UserBase: record, UserRoleName: record, UserSearchMatching: record, UserSearchSubtree: record>, Logs: record<Audit: record, AuditLogGroup: record, General: record, GeneralLogGroup: record, Pending: record<Audit: record, General: record>>, MaintenanceWindowStartTime: record<DayOfWeek: record, TimeOfDay: record, TimeZone: record>, PendingAuthenticationStrategy: record, PendingEngineVersion: record, PendingHostInstanceType: record, PendingLdapServerMetadata: record<Hosts: record, RoleBase: record, RoleName: record, RoleSearchMatching: record, RoleSearchSubtree: record, ServiceAccountUsername: record, UserBase: record, UserRoleName: record, UserSearchMatching: record, UserSearchSubtree: record>, PendingSecurityGroups: record, PubliclyAccessible: record, SecurityGroups: record, StorageType: record, SubnetIds: record, Tags: record, Users: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($broker_id | is-empty) { error make --unspanned { msg: "path parameter 'broker-id' must be non-empty" } }
  let full_url = (build-url $base ({broker_id: (encode-path-segment $broker_id)} | format pattern "/v1/brokers/{broker_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds a pending configuration change to a broker.
#
# PUT /v1/brokers/{broker-id}
# operationId: UpdateBroker
# --configuration shape: {Id?: any, Revision?: any}
# --ldapServerMetadata shape: {Hosts?: any, RoleBase?: any, RoleName?: any, RoleSearchMatching?: any, RoleSearchSubtree?: any, ServiceAccountPassword?: any, ServiceAccountUsername?: any, UserBase?: any, UserRoleName?: any, UserSearchMatching?: any, UserSearchSubtree?: any}
# --logs shape: {Audit?: any, General?: any}
# --maintenanceWindowStartTime shape: {DayOfWeek?: any, TimeOfDay?: any, TimeZone?: any}
export def "brokers update" [
  broker_id: string
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
  --authentication-strategy: string@authentication-strategy-completer # Optional. The authentication strategy used to secure the broker. The default is SIMPLE.
  --auto-minor-version-upgrade: oneof<nothing, bool> # Enables automatic upgrades to new minor versions for brokers, as new versions are released and supported by Amazon MQ. Automatic upgrades occur during the scheduled maintenance window of the broker or after a manual broker reboot.
  --configuration: record # A list of information about the configuration. Does not apply to RabbitMQ brokers. — shape: {Id?: any, Revision?: any}
  --engine-version: string # The broker engine version. For a list of supported engine versions, see Supported engines (https://docs.aws.amazon.com//amazon-mq/latest/developer-guide/broker-engine.html).
  --host-instance-type: string # The broker's host instance type to upgrade to. For a list of supported instance types, see Broker instance types (https://docs.aws.amazon.com//amazon-mq/latest/developer-guide/broker.html#broker-instance-types).
  --ldap-server-metadata: record # Optional. The metadata of the LDAP server used to authenticate and authorize connections to the broker. Does not apply to RabbitMQ brokers. — shape: {Hosts?: any, RoleBase?: any, RoleName?: any, RoleSearchMatching?: any, RoleSearchSubtree?: any, ServiceAccountPassword?: any, ServiceAccountUsername?: any, UserBase?: any, UserRoleName?: any, UserSearchMatching?: any, UserSearchSubtree?: any}
  --logs: record # The list of information about logs to be enabled for the specified broker. — shape: {Audit?: any, General?: any}
  --maintenance-window-start-time: record # The scheduled time period relative to UTC during which Amazon MQ begins to apply pending updates or patches to the broker. — shape: {DayOfWeek?: any, TimeOfDay?: any, TimeZone?: any}
  --security-groups: list<string> # The list of security groups (1 minimum, 5 maximum) that authorizes connections to brokers.
]: any -> record<AuthenticationStrategy: record, AutoMinorVersionUpgrade: record, BrokerId: record, Configuration: record<Id: record, Revision: record>, EngineVersion: record, HostInstanceType: record, LdapServerMetadata: record<Hosts: record, RoleBase: record, RoleName: record, RoleSearchMatching: record, RoleSearchSubtree: record, ServiceAccountUsername: record, UserBase: record, UserRoleName: record, UserSearchMatching: record, UserSearchSubtree: record>, Logs: record<Audit: record, General: record>, MaintenanceWindowStartTime: record<DayOfWeek: record, TimeOfDay: record, TimeZone: record>, SecurityGroups: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($broker_id | is-empty) { error make --unspanned { msg: "path parameter 'broker-id' must be non-empty" } }
  let full_url = (build-url $base ({broker_id: (encode-path-segment $broker_id)} | format pattern "/v1/brokers/{broker_id}"))
  let req_body = {"authenticationStrategy": $authentication_strategy, "autoMinorVersionUpgrade": $auto_minor_version_upgrade, "configuration": $configuration, "engineVersion": $engine_version, "hostInstanceType": $host_instance_type, "ldapServerMetadata": $ldap_server_metadata, "logs": $logs, "maintenanceWindowStartTime": $maintenance_window_start_time, "securityGroups": $security_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes a tag from a resource.
#
# DELETE /v1/tags/{resource-arn}
# operationId: DeleteTags
export def "tags delete" [
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
  --tag-keys: list # An array of tag keys to delete
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}

# Describe available engine types and versions.
#
# GET /v1/broker-engine-types
# operationId: DescribeBrokerEngineTypes
export def "broker-engine-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --engine-type: string # Filter response by engine type.
  --max-results: int # The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  --next-token: string # The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<BrokerEngineTypes: record, MaxResults: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "engineType" $engine_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/broker-engine-types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"engineType": $engine_type, "maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Describe available broker instance options.
#
# GET /v1/broker-instance-options
# operationId: DescribeBrokerInstanceOptions
export def "broker-instance-options get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --engine-type: string # Filter response by engine type.
  --host-instance-type: string # Filter response by host instance type.
  --max-results: int # The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  --next-token: string # The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  --storage-type: string # Filter response by storage type.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<BrokerInstanceOptions: record, MaxResults: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "engineType" $engine_type "scalar") (serialize-qp "hostInstanceType" $host_instance_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "storageType" $storage_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/broker-instance-options" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"engineType": $engine_type, "hostInstanceType": $host_instance_type, "maxResults": $max_results, "nextToken": $next_token, "storageType": $storage_type} | compact), body: null}
}

# Returns information about the specified configuration.
#
# GET /v1/configurations/{configuration-id}
# operationId: DescribeConfiguration
export def "configurations get" [
  configuration_id: string
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
]: nothing -> record<Arn: record, AuthenticationStrategy: record, Created: record, Description: record, EngineType: record, EngineVersion: record, Id: record, LatestRevision: record<Created: record, Description: record, Revision: record>, Name: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configuration-id' must be non-empty" } }
  let full_url = (build-url $base ({configuration_id: (encode-path-segment $configuration_id)} | format pattern "/v1/configurations/{configuration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the specified configuration.
#
# PUT /v1/configurations/{configuration-id}
# operationId: UpdateConfiguration
export def "configurations update" [
  configuration_id: string
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
  data: string # Required. The base64-encoded XML configuration.
  --description: string # The description of the configuration.
]: any -> record<Arn: record, Created: record, Id: record, LatestRevision: record<Created: record, Description: record, Revision: record>, Name: record, Warnings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configuration-id' must be non-empty" } }
  let full_url = (build-url $base ({configuration_id: (encode-path-segment $configuration_id)} | format pattern "/v1/configurations/{configuration_id}"))
  let req_body = {"data": $data, "description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the specified configuration revision for the specified configuration.
#
# GET /v1/configurations/{configuration-id}/revisions/{configuration-revision}
# operationId: DescribeConfigurationRevision
export def "configurations-revisions get" [
  configuration_id: string
  configuration_revision: string
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
]: nothing -> record<ConfigurationId: record, Created: record, Data: record, Description: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configuration-id' must be non-empty" } }
  if ($configuration_revision | is-empty) { error make --unspanned { msg: "path parameter 'configuration-revision' must be non-empty" } }
  let full_url = (build-url $base ({configuration_id: (encode-path-segment $configuration_id), configuration_revision: (encode-path-segment $configuration_revision)} | format pattern "/v1/configurations/{configuration_id}/revisions/{configuration_revision}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of all revisions for the specified configuration.
#
# GET /v1/configurations/{configuration-id}/revisions
# operationId: ListConfigurationRevisions
export def "configurations-revisions list" [
  configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  --next-token: string # The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ConfigurationId: record, MaxResults: record, NextToken: record, Revisions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configuration-id' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({configuration_id: (encode-path-segment $configuration_id)} | format pattern "/v1/configurations/{configuration_id}/revisions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Returns a list of all ActiveMQ users.
#
# GET /v1/brokers/{broker-id}/users
# operationId: ListUsers
export def "brokers-users list" [
  broker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of brokers that Amazon MQ can return per page (20 by default). This value must be an integer from 5 to 100.
  --next-token: string # The token that specifies the next page of results Amazon MQ should return. To request the first page, leave nextToken empty.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<BrokerId: record, MaxResults: record, NextToken: record, Users: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($broker_id | is-empty) { error make --unspanned { msg: "path parameter 'broker-id' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({broker_id: (encode-path-segment $broker_id)} | format pattern "/v1/brokers/{broker_id}/users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Reboots a broker. Note: This API is asynchronous.
#
# POST /v1/brokers/{broker-id}/reboot
# operationId: RebootBroker
export def "brokers-reboot create" [
  broker_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($broker_id | is-empty) { error make --unspanned { msg: "path parameter 'broker-id' must be non-empty" } }
  let full_url = (build-url $base ({broker_id: (encode-path-segment $broker_id)} | format pattern "/v1/brokers/{broker_id}/reboot"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
