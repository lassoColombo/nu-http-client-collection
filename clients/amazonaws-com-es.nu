# Auto-generated client for Amazon Elasticsearch Service v2015-01-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/es/2015-01-01/openapi.json
# Auth: --token flag or $env.AMAZON_ELASTICSEARCH_SERVICE_TOKEN

const BASE_URL = "http://es.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_ELASTICSEARCH_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["http://es.us-east-1.amazonaws.com" "http://es.us-east-2.amazonaws.com" "http://es.us-west-1.amazonaws.com" "http://es.us-west-2.amazonaws.com" "http://es.us-gov-west-1.amazonaws.com" "http://es.us-gov-east-1.amazonaws.com" "http://es.ca-central-1.amazonaws.com" "http://es.eu-north-1.amazonaws.com" "http://es.eu-west-1.amazonaws.com" "http://es.eu-west-2.amazonaws.com" "http://es.eu-west-3.amazonaws.com" "http://es.eu-central-1.amazonaws.com" "http://es.eu-south-1.amazonaws.com" "http://es.af-south-1.amazonaws.com" "http://es.ap-northeast-1.amazonaws.com" "http://es.ap-northeast-2.amazonaws.com" "http://es.ap-northeast-3.amazonaws.com" "http://es.ap-southeast-1.amazonaws.com" "http://es.ap-southeast-2.amazonaws.com" "http://es.ap-east-1.amazonaws.com" "http://es.ap-south-1.amazonaws.com" "http://es.sa-east-1.amazonaws.com" "http://es.me-south-1.amazonaws.com" "https://es.us-east-1.amazonaws.com" "https://es.us-east-2.amazonaws.com" "https://es.us-west-1.amazonaws.com" "https://es.us-west-2.amazonaws.com" "https://es.us-gov-west-1.amazonaws.com" "https://es.us-gov-east-1.amazonaws.com" "https://es.ca-central-1.amazonaws.com" "https://es.eu-north-1.amazonaws.com" "https://es.eu-west-1.amazonaws.com" "https://es.eu-west-2.amazonaws.com" "https://es.eu-west-3.amazonaws.com" "https://es.eu-central-1.amazonaws.com" "https://es.eu-south-1.amazonaws.com" "https://es.af-south-1.amazonaws.com" "https://es.ap-northeast-1.amazonaws.com" "https://es.ap-northeast-2.amazonaws.com" "https://es.ap-northeast-3.amazonaws.com" "https://es.ap-southeast-1.amazonaws.com" "https://es.ap-southeast-2.amazonaws.com" "https://es.ap-east-1.amazonaws.com" "https://es.ap-south-1.amazonaws.com" "https://es.sa-east-1.amazonaws.com" "https://es.me-south-1.amazonaws.com" "http://es.cn-north-1.amazonaws.com.cn" "http://es.cn-northwest-1.amazonaws.com.cn" "https://es.cn-north-1.amazonaws.com.cn" "https://es.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def PackageType-completer [] { ["TXT-DICTIONARY"] }
def engineType-completer [] { ["Elasticsearch" "OpenSearch"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2015-01-01-es-ccs-inbound-connection-accept AcceptInboundCrossClusterSearchConnection" } } | get name | first)
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

# Allows the destination domain owner to accept an inbound cross-cluster search connection request.
#
# PUT /2015-01-01/es/ccs/inboundConnection/{ConnectionId}/accept
# operationId: AcceptInboundCrossClusterSearchConnection
export def "2015-01-01-es-ccs-inbound-connection-accept AcceptInboundCrossClusterSearchConnection" [
  ConnectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: record, ConnectionStatus: record<StatusCode: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/es/ccs/inboundConnection/($ConnectionId)/accept")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
#
# POST /2015-01-01/tags
# operationId: AddTags
# --TagList item shape: {Key: any, Value: any}
export def "2015-01-01-tags AddTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  ARN: string # The Amazon Resource Name (ARN) of the Elasticsearch domain. See <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html" target="_blank">Identifiers for IAM Entities</a> in <i>Using AWS Identity and Access Management</i> for more information.
  TagList: list # A list of <code>Tag</code>  — item shape: {Key: any, Value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/tags")
  let body = {ARN: $ARN, TagList: $TagList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Associates a package with an Amazon ES domain.
#
# POST /2015-01-01/packages/associate/{PackageID}/{DomainName}
# operationId: AssociatePackage
export def "2015-01-01-packages-associate AssociatePackage" [
  PackageID: string
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DomainPackageDetails: record<PackageID: record, PackageName: record, PackageType: record, LastUpdated: record, DomainName: record, DomainPackageStatus: record, PackageVersion: string, ReferencePath: record, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/packages/associate/($PackageID)/($DomainName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provides access to an Amazon OpenSearch Service domain through the use of an interface VPC endpoint.
#
# POST /2015-01-01/es/domain/{DomainName}/authorizeVpcEndpointAccess
# operationId: AuthorizeVpcEndpointAccess
export def "2015-01-01-es-domain-authorize-vpc-endpoint-access AuthorizeVpcEndpointAccess" [
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  Account: string # The account ID to grant access to.
]: any -> record<AuthorizedPrincipal: record<PrincipalType: record, Principal: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/es/domain/($DomainName)/authorizeVpcEndpointAccess")
  let body = {Account: $Account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
#
# POST /2015-01-01/es/serviceSoftwareUpdate/cancel
# operationId: CancelElasticsearchServiceSoftwareUpdate
export def "2015-01-01-es-service-software-update-cancel CancelElasticsearchServiceSoftwareUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  DomainName: string # The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
]: any -> record<ServiceSoftwareOptions: record<CurrentVersion: record, NewVersion: record, UpdateAvailable: record, Cancellable: record, UpdateStatus: record, Description: record, AutomatedUpdateDate: record, OptionalDeployment: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/serviceSoftwareUpdate/cancel")
  let body = {DomainName: $DomainName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
#
# POST /2015-01-01/es/domain
# operationId: CreateElasticsearchDomain
# --ElasticsearchClusterConfig shape: {InstanceType?: any, InstanceCount?: any, DedicatedMasterEnabled?: any, ZoneAwarenessEnabled?: any, ZoneAwarenessConfig?: any, DedicatedMasterType?: any, DedicatedMasterCount?: any, WarmEnabled?: any, WarmType?: any, WarmCount?: any, ColdStorageOptions?: any}
# --EBSOptions shape: {EBSEnabled?: any, VolumeType?: any, VolumeSize?: any, Iops?: any, Throughput?: any}
# --SnapshotOptions shape: {AutomatedSnapshotStartHour?: any}
# --VPCOptions shape: {SubnetIds?: any, SecurityGroupIds?: any}
# --CognitoOptions shape: {Enabled?: any, UserPoolId?: any, IdentityPoolId?: any, RoleArn?: any}
# --EncryptionAtRestOptions shape: {Enabled?: any, KmsKeyId?: any}
# --NodeToNodeEncryptionOptions shape: {Enabled?: any}
# --DomainEndpointOptions shape: {EnforceHTTPS?: any, TLSSecurityPolicy?: any, CustomEndpointEnabled?: any, CustomEndpoint?: any, CustomEndpointCertificateArn?: any}
# --AdvancedSecurityOptions shape: {Enabled?: any, InternalUserDatabaseEnabled?: any, MasterUserOptions?: any, SAMLOptions?: any, AnonymousAuthEnabled?: any}
# --AutoTuneOptions shape: {DesiredState?: any, MaintenanceSchedules?: any}
# --TagList item shape: {Key: any, Value: any}
export def "2015-01-01-es-domain CreateElasticsearchDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  DomainName: string # The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  --ElasticsearchVersion: string # String of format X.Y to specify version for the Elasticsearch domain eg. "1.5" or "2.3". For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
  --ElasticsearchClusterConfig: record # Specifies the configuration for the domain cluster, such as the type and number of instances. — shape: {InstanceType?: any, InstanceCount?: any, DedicatedMasterEnabled?: any, ZoneAwarenessEnabled?: any, ZoneAwarenessConfig?: any, DedicatedMasterType?: any, DedicatedMasterCount?: any, WarmEnabled?: any, WarmType?: any, WarmCount?: any, ColdStorageOptions?: any}
  --EBSOptions: record # Options to enable, disable, and specify the properties of EBS storage volumes. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-ebs" target="_blank"> Configuring EBS-based Storage</a>. — shape: {EBSEnabled?: any, VolumeType?: any, VolumeSize?: any, Iops?: any, Throughput?: any}
  --AccessPolicies: string # Access policy rules for an Elasticsearch domain service endpoints. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-access-policies" target="_blank">Configuring Access Policies</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>. The maximum size of a policy document is 100 KB.
  --SnapshotOptions: record # Specifies the time, in UTC format, when the service takes a daily automated snapshot of the specified Elasticsearch domain. Default value is <code>0</code> hours. — shape: {AutomatedSnapshotStartHour?: any}
  --VPCOptions: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html" target="_blank"> VPC Endpoints for Amazon Elasticsearch Service Domains</a>. — shape: {SubnetIds?: any, SecurityGroupIds?: any}
  --CognitoOptions: record # Options to specify the Cognito user and identity pools for Kibana authentication. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-cognito-auth.html" target="_blank">Amazon Cognito Authentication for Kibana</a>. — shape: {Enabled?: any, UserPoolId?: any, IdentityPoolId?: any, RoleArn?: any}
  --EncryptionAtRestOptions: record # Specifies the Encryption At Rest Options. — shape: {Enabled?: any, KmsKeyId?: any}
  --NodeToNodeEncryptionOptions: record # Specifies the node-to-node encryption options. — shape: {Enabled?: any}
  --AdvancedOptions: record # <p> Exposes select native Elasticsearch configuration values from <code>elasticsearch.yml</code>. Currently, the following advanced options are available:</p> <ul> <li>Option to allow references to indices in an HTTP request body. Must be <code>false</code> when configuring access to individual sub-resources. By default, the value is <code>true</code>. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options" target="_blank">Configuration Advanced Options</a> for more information.</li> <li>Option to specify the percentage of heap space that is allocated to field data. By default, this setting is unbounded.</li> </ul> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options">Configuring Advanced Options</a>.</p>
  --LogPublishingOptions: record # Map of <code>LogType</code> and <code>LogPublishingOption</code>, each containing options to publish a given type of Elasticsearch log.
  --DomainEndpointOptions: record # Options to configure endpoint for the Elasticsearch domain. — shape: {EnforceHTTPS?: any, TLSSecurityPolicy?: any, CustomEndpointEnabled?: any, CustomEndpoint?: any, CustomEndpointCertificateArn?: any}
  --AdvancedSecurityOptions: record # Specifies the advanced security configuration: whether advanced security is enabled, whether the internal database option is enabled, master username and password (if internal database is enabled), and master user ARN (if IAM is enabled). — shape: {Enabled?: any, InternalUserDatabaseEnabled?: any, MasterUserOptions?: any, SAMLOptions?: any, AnonymousAuthEnabled?: any}
  --AutoTuneOptions: record # Specifies the Auto-Tune options: the Auto-Tune desired state for the domain and list of maintenance schedules. — shape: {DesiredState?: any, MaintenanceSchedules?: any}
  --TagList: list # A list of <code>Tag</code>  — item shape: {Key: any, Value: any}
]: any -> record<DomainStatus: record<DomainId: record, DomainName: record, ARN: record, Created: record, Deleted: record, Endpoint: record, Endpoints: record, Processing: record, UpgradeProcessing: record, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: record, InstanceCount: record, DedicatedMasterEnabled: record, ZoneAwarenessEnabled: record, ZoneAwarenessConfig: record, DedicatedMasterType: record, DedicatedMasterCount: record, WarmEnabled: record, WarmType: record, WarmCount: record, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: record, VolumeType: record, VolumeSize: record, Iops: record, Throughput: record>, AccessPolicies: record, SnapshotOptions: record<AutomatedSnapshotStartHour: record>, VPCOptions: record<VPCId: record, SubnetIds: record, AvailabilityZones: record, SecurityGroupIds: record>, CognitoOptions: record<Enabled: record, UserPoolId: record, IdentityPoolId: record, RoleArn: record>, EncryptionAtRestOptions: record<Enabled: record, KmsKeyId: record>, NodeToNodeEncryptionOptions: record<Enabled: record>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: record, NewVersion: record, UpdateAvailable: record, Cancellable: record, UpdateStatus: record, Description: record, AutomatedUpdateDate: record, OptionalDeployment: record>, DomainEndpointOptions: record<EnforceHTTPS: record, TLSSecurityPolicy: record, CustomEndpointEnabled: record, CustomEndpoint: record, CustomEndpointCertificateArn: record>, AdvancedSecurityOptions: record<Enabled: record, InternalUserDatabaseEnabled: record, SAMLOptions: record, AnonymousAuthDisableDate: record, AnonymousAuthEnabled: record>, AutoTuneOptions: record<State: record, ErrorMessage: record>, ChangeProgressDetails: record<ChangeId: record, Message: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/domain")
  let body = {DomainName: $DomainName, ElasticsearchVersion: $ElasticsearchVersion, ElasticsearchClusterConfig: $ElasticsearchClusterConfig, EBSOptions: $EBSOptions, AccessPolicies: $AccessPolicies, SnapshotOptions: $SnapshotOptions, VPCOptions: $VPCOptions, CognitoOptions: $CognitoOptions, EncryptionAtRestOptions: $EncryptionAtRestOptions, NodeToNodeEncryptionOptions: $NodeToNodeEncryptionOptions, AdvancedOptions: $AdvancedOptions, LogPublishingOptions: $LogPublishingOptions, DomainEndpointOptions: $DomainEndpointOptions, AdvancedSecurityOptions: $AdvancedSecurityOptions, AutoTuneOptions: $AutoTuneOptions, TagList: $TagList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new cross-cluster search connection from a source domain to a destination domain.
#
# POST /2015-01-01/es/ccs/outboundConnection
# operationId: CreateOutboundCrossClusterSearchConnection
# --SourceDomainInfo shape: {OwnerId?: string, DomainName?: string, Region?: string}
# --DestinationDomainInfo shape: {OwnerId?: string, DomainName?: string, Region?: string}
export def "2015-01-01-es-ccs-outbound-connection CreateOutboundCrossClusterSearchConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  SourceDomainInfo: record # Specifies the <code><a>DomainInformation</a></code> for the source Elasticsearch domain. — shape: {OwnerId?: string, DomainName?: string, Region?: string}
  DestinationDomainInfo: record # Specifies the <code><a>DomainInformation</a></code> for the destination Elasticsearch domain. — shape: {OwnerId?: string, DomainName?: string, Region?: string}
  ConnectionAlias: string # Specifies the connection alias that will be used by the customer for this connection.
]: any -> record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, ConnectionAlias: record, ConnectionStatus: record<StatusCode: record, Message: record>, CrossClusterSearchConnectionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/ccs/outboundConnection")
  let body = {SourceDomainInfo: $SourceDomainInfo, DestinationDomainInfo: $DestinationDomainInfo, ConnectionAlias: $ConnectionAlias} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a package for use with Amazon ES domains.
#
# POST /2015-01-01/packages
# operationId: CreatePackage
# --PackageSource shape: {S3BucketName?: any, S3Key?: any}
export def "2015-01-01-packages CreatePackage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  PackageName: string # Unique identifier for the package.
  PackageType: string@PackageType-completer # Type of package. Currently supports only TXT-DICTIONARY.
  --PackageDescription: string # Description of the package.
  PackageSource: record # The S3 location for importing the package specified as <code>S3BucketName</code> and <code>S3Key</code> — shape: {S3BucketName?: any, S3Key?: any}
]: any -> record<PackageDetails: record<PackageID: record, PackageName: record, PackageType: record, PackageDescription: record, PackageStatus: record, CreatedAt: record, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/packages")
  let body = {PackageName: $PackageName, PackageType: $PackageType, PackageDescription: $PackageDescription, PackageSource: $PackageSource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an Amazon OpenSearch Service-managed VPC endpoint.
#
# POST /2015-01-01/es/vpcEndpoints
# operationId: CreateVpcEndpoint
# --VpcOptions shape: {SubnetIds?: any, SecurityGroupIds?: any}
export def "2015-01-01-es-vpc-endpoints CreateVpcEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  DomainArn: string # The Amazon Resource Name (ARN) of the domain to grant access to.
  VpcOptions: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html" target="_blank"> VPC Endpoints for Amazon Elasticsearch Service Domains</a>. — shape: {SubnetIds?: any, SecurityGroupIds?: any}
  --ClientToken: string # Unique, case-sensitive identifier to ensure idempotency of the request.
]: any -> record<VpcEndpoint: record<VpcEndpointId: record, VpcEndpointOwner: record, DomainArn: record, VpcOptions: record<VPCId: record, SubnetIds: record, AvailabilityZones: record, SecurityGroupIds: record>, Status: record, Endpoint: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/vpcEndpoints")
  let body = {DomainArn: $DomainArn, VpcOptions: $VpcOptions, ClientToken: $ClientToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves all Amazon OpenSearch Service-managed VPC endpoints in the current account and Region.
#
# GET /2015-01-01/es/vpcEndpoints
# operationId: ListVpcEndpoints
export def "2015-01-01-es-vpc-endpoints ListVpcEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nextToken: string # Identifier to allow retrieval of paginated results.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<VpcEndpointSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/vpcEndpoints" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
#
# DELETE /2015-01-01/es/domain/{DomainName}
# operationId: DeleteElasticsearchDomain
export def "2015-01-01-es-domain DeleteElasticsearchDomain" [
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DomainStatus: record<DomainId: record, DomainName: record, ARN: record, Created: record, Deleted: record, Endpoint: record, Endpoints: record, Processing: record, UpgradeProcessing: record, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: record, InstanceCount: record, DedicatedMasterEnabled: record, ZoneAwarenessEnabled: record, ZoneAwarenessConfig: record, DedicatedMasterType: record, DedicatedMasterCount: record, WarmEnabled: record, WarmType: record, WarmCount: record, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: record, VolumeType: record, VolumeSize: record, Iops: record, Throughput: record>, AccessPolicies: record, SnapshotOptions: record<AutomatedSnapshotStartHour: record>, VPCOptions: record<VPCId: record, SubnetIds: record, AvailabilityZones: record, SecurityGroupIds: record>, CognitoOptions: record<Enabled: record, UserPoolId: record, IdentityPoolId: record, RoleArn: record>, EncryptionAtRestOptions: record<Enabled: record, KmsKeyId: record>, NodeToNodeEncryptionOptions: record<Enabled: record>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: record, NewVersion: record, UpdateAvailable: record, Cancellable: record, UpdateStatus: record, Description: record, AutomatedUpdateDate: record, OptionalDeployment: record>, DomainEndpointOptions: record<EnforceHTTPS: record, TLSSecurityPolicy: record, CustomEndpointEnabled: record, CustomEndpoint: record, CustomEndpointCertificateArn: record>, AdvancedSecurityOptions: record<Enabled: record, InternalUserDatabaseEnabled: record, SAMLOptions: record, AnonymousAuthDisableDate: record, AnonymousAuthEnabled: record>, AutoTuneOptions: record<State: record, ErrorMessage: record>, ChangeProgressDetails: record<ChangeId: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/es/domain/($DomainName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
#
# GET /2015-01-01/es/domain/{DomainName}
# operationId: DescribeElasticsearchDomain
export def "2015-01-01-es-domain DescribeElasticsearchDomain" [
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DomainStatus: record<DomainId: record, DomainName: record, ARN: record, Created: record, Deleted: record, Endpoint: record, Endpoints: record, Processing: record, UpgradeProcessing: record, ElasticsearchVersion: string, ElasticsearchClusterConfig: record<InstanceType: record, InstanceCount: record, DedicatedMasterEnabled: record, ZoneAwarenessEnabled: record, ZoneAwarenessConfig: record, DedicatedMasterType: record, DedicatedMasterCount: record, WarmEnabled: record, WarmType: record, WarmCount: record, ColdStorageOptions: record>, EBSOptions: record<EBSEnabled: record, VolumeType: record, VolumeSize: record, Iops: record, Throughput: record>, AccessPolicies: record, SnapshotOptions: record<AutomatedSnapshotStartHour: record>, VPCOptions: record<VPCId: record, SubnetIds: record, AvailabilityZones: record, SecurityGroupIds: record>, CognitoOptions: record<Enabled: record, UserPoolId: record, IdentityPoolId: record, RoleArn: record>, EncryptionAtRestOptions: record<Enabled: record, KmsKeyId: record>, NodeToNodeEncryptionOptions: record<Enabled: record>, AdvancedOptions: record, LogPublishingOptions: record, ServiceSoftwareOptions: record<CurrentVersion: record, NewVersion: record, UpdateAvailable: record, Cancellable: record, UpdateStatus: record, Description: record, AutomatedUpdateDate: record, OptionalDeployment: record>, DomainEndpointOptions: record<EnforceHTTPS: record, TLSSecurityPolicy: record, CustomEndpointEnabled: record, CustomEndpoint: record, CustomEndpointCertificateArn: record>, AdvancedSecurityOptions: record<Enabled: record, InternalUserDatabaseEnabled: record, SAMLOptions: record, AnonymousAuthDisableDate: record, AnonymousAuthEnabled: record>, AutoTuneOptions: record<State: record, ErrorMessage: record>, ChangeProgressDetails: record<ChangeId: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/es/domain/($DomainName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
#
# DELETE /2015-01-01/es/role
# operationId: DeleteElasticsearchServiceRole
export def "2015-01-01-es-role DeleteElasticsearchServiceRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/role")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows the destination domain owner to delete an existing inbound cross-cluster search connection.
#
# DELETE /2015-01-01/es/ccs/inboundConnection/{ConnectionId}
# operationId: DeleteInboundCrossClusterSearchConnection
export def "2015-01-01-es-ccs-inbound-connection DeleteInboundCrossClusterSearchConnection" [
  ConnectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: record, ConnectionStatus: record<StatusCode: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/es/ccs/inboundConnection/($ConnectionId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows the source domain owner to delete an existing outbound cross-cluster search connection.
#
# DELETE /2015-01-01/es/ccs/outboundConnection/{ConnectionId}
# operationId: DeleteOutboundCrossClusterSearchConnection
export def "2015-01-01-es-ccs-outbound-connection DeleteOutboundCrossClusterSearchConnection" [
  ConnectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: record, ConnectionAlias: record, ConnectionStatus: record<StatusCode: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/es/ccs/outboundConnection/($ConnectionId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the package.
#
# DELETE /2015-01-01/packages/{PackageID}
# operationId: DeletePackage
export def "2015-01-01-packages DeletePackage" [
  PackageID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<PackageDetails: record<PackageID: record, PackageName: record, PackageType: record, PackageDescription: record, PackageStatus: record, CreatedAt: record, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/packages/($PackageID)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an Amazon OpenSearch Service-managed interface VPC endpoint.
#
# DELETE /2015-01-01/es/vpcEndpoints/{VpcEndpointId}
# operationId: DeleteVpcEndpoint
export def "2015-01-01-es-vpc-endpoints DeleteVpcEndpoint" [
  VpcEndpointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<VpcEndpointSummary: record<VpcEndpointId: record, VpcEndpointOwner: record, DomainArn: record, Status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/es/vpcEndpoints/($VpcEndpointId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provides scheduled Auto-Tune action details for the Elasticsearch domain, such as Auto-Tune action type, description, severity, and scheduled date.
#
# GET /2015-01-01/es/domain/{DomainName}/autoTunes
# operationId: DescribeDomainAutoTunes
export def "2015-01-01-es-domain-auto-tunes DescribeDomainAutoTunes" [
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --MaxResults: int #  Set this value to limit the number of results returned. 
  --NextToken: string #  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
]: any -> record<AutoTunes: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-01-01/es/domain/($DomainName)/autoTunes" $qp)
  let body = {MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about the current blue/green deployment happening on a domain, including a change ID, status, and progress stages.
#
# GET /2015-01-01/es/domain/{DomainName}/progress
# operationId: DescribeDomainChangeProgress
export def "2015-01-01-es-domain-progress DescribeDomainChangeProgress" [
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --changeid: string # The specific change ID for which you want to get progress information. This is an optional parameter. If omitted, the service returns information about the most recent configuration change. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<ChangeProgressStatus: record<ChangeId: record, StartTime: record, Status: record, PendingProperties: record, CompletedProperties: record, TotalNumberOfStages: record, ChangeProgressStages: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "changeid" $changeid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-01-01/es/domain/($DomainName)/progress" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
#
# GET /2015-01-01/es/domain/{DomainName}/config
# operationId: DescribeElasticsearchDomainConfig
export def "2015-01-01-es-domain-config DescribeElasticsearchDomainConfig" [
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DomainConfig: record<ElasticsearchVersion: record<Options: record, Status: record>, ElasticsearchClusterConfig: record<Options: record, Status: record>, EBSOptions: record<Options: record, Status: record>, AccessPolicies: record<Options: record, Status: record>, SnapshotOptions: record<Options: record, Status: record>, VPCOptions: record<Options: record, Status: record>, CognitoOptions: record<Options: record, Status: record>, EncryptionAtRestOptions: record<Options: record, Status: record>, NodeToNodeEncryptionOptions: record<Options: record, Status: record>, AdvancedOptions: record<Options: record, Status: record>, LogPublishingOptions: record<Options: record, Status: record>, DomainEndpointOptions: record<Options: record, Status: record>, AdvancedSecurityOptions: record<Options: record, Status: record>, AutoTuneOptions: record<Options: record, Status: record>, ChangeProgressDetails: record<ChangeId: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/es/domain/($DomainName)/config")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
#
# POST /2015-01-01/es/domain/{DomainName}/config
# operationId: UpdateElasticsearchDomainConfig
# --ElasticsearchClusterConfig shape: {InstanceType?: any, InstanceCount?: any, DedicatedMasterEnabled?: any, ZoneAwarenessEnabled?: any, ZoneAwarenessConfig?: any, DedicatedMasterType?: any, DedicatedMasterCount?: any, WarmEnabled?: any, WarmType?: any, WarmCount?: any, ColdStorageOptions?: any}
# --EBSOptions shape: {EBSEnabled?: any, VolumeType?: any, VolumeSize?: any, Iops?: any, Throughput?: any}
# --SnapshotOptions shape: {AutomatedSnapshotStartHour?: any}
# --VPCOptions shape: {SubnetIds?: any, SecurityGroupIds?: any}
# --CognitoOptions shape: {Enabled?: any, UserPoolId?: any, IdentityPoolId?: any, RoleArn?: any}
# --DomainEndpointOptions shape: {EnforceHTTPS?: any, TLSSecurityPolicy?: any, CustomEndpointEnabled?: any, CustomEndpoint?: any, CustomEndpointCertificateArn?: any}
# --AdvancedSecurityOptions shape: {Enabled?: any, InternalUserDatabaseEnabled?: any, MasterUserOptions?: any, SAMLOptions?: any, AnonymousAuthEnabled?: any}
# --NodeToNodeEncryptionOptions shape: {Enabled?: any}
# --EncryptionAtRestOptions shape: {Enabled?: any, KmsKeyId?: any}
# --AutoTuneOptions shape: {DesiredState?: any, RollbackOnDisable?: any, MaintenanceSchedules?: any}
export def "2015-01-01-es-domain-config UpdateElasticsearchDomainConfig" [
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --ElasticsearchClusterConfig: record # Specifies the configuration for the domain cluster, such as the type and number of instances. — shape: {InstanceType?: any, InstanceCount?: any, DedicatedMasterEnabled?: any, ZoneAwarenessEnabled?: any, ZoneAwarenessConfig?: any, DedicatedMasterType?: any, DedicatedMasterCount?: any, WarmEnabled?: any, WarmType?: any, WarmCount?: any, ColdStorageOptions?: any}
  --EBSOptions: record # Options to enable, disable, and specify the properties of EBS storage volumes. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-ebs" target="_blank"> Configuring EBS-based Storage</a>. — shape: {EBSEnabled?: any, VolumeType?: any, VolumeSize?: any, Iops?: any, Throughput?: any}
  --SnapshotOptions: record # Specifies the time, in UTC format, when the service takes a daily automated snapshot of the specified Elasticsearch domain. Default value is <code>0</code> hours. — shape: {AutomatedSnapshotStartHour?: any}
  --VPCOptions: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html" target="_blank"> VPC Endpoints for Amazon Elasticsearch Service Domains</a>. — shape: {SubnetIds?: any, SecurityGroupIds?: any}
  --CognitoOptions: record # Options to specify the Cognito user and identity pools for Kibana authentication. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-cognito-auth.html" target="_blank">Amazon Cognito Authentication for Kibana</a>. — shape: {Enabled?: any, UserPoolId?: any, IdentityPoolId?: any, RoleArn?: any}
  --AdvancedOptions: record # <p> Exposes select native Elasticsearch configuration values from <code>elasticsearch.yml</code>. Currently, the following advanced options are available:</p> <ul> <li>Option to allow references to indices in an HTTP request body. Must be <code>false</code> when configuring access to individual sub-resources. By default, the value is <code>true</code>. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options" target="_blank">Configuration Advanced Options</a> for more information.</li> <li>Option to specify the percentage of heap space that is allocated to field data. By default, this setting is unbounded.</li> </ul> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-advanced-options">Configuring Advanced Options</a>.</p>
  --AccessPolicies: string # Access policy rules for an Elasticsearch domain service endpoints. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomain-configure-access-policies" target="_blank">Configuring Access Policies</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>. The maximum size of a policy document is 100 KB.
  --LogPublishingOptions: record # Map of <code>LogType</code> and <code>LogPublishingOption</code>, each containing options to publish a given type of Elasticsearch log.
  --DomainEndpointOptions: record # Options to configure endpoint for the Elasticsearch domain. — shape: {EnforceHTTPS?: any, TLSSecurityPolicy?: any, CustomEndpointEnabled?: any, CustomEndpoint?: any, CustomEndpointCertificateArn?: any}
  --AdvancedSecurityOptions: record # Specifies the advanced security configuration: whether advanced security is enabled, whether the internal database option is enabled, master username and password (if internal database is enabled), and master user ARN (if IAM is enabled). — shape: {Enabled?: any, InternalUserDatabaseEnabled?: any, MasterUserOptions?: any, SAMLOptions?: any, AnonymousAuthEnabled?: any}
  --NodeToNodeEncryptionOptions: record # Specifies the node-to-node encryption options. — shape: {Enabled?: any}
  --EncryptionAtRestOptions: record # Specifies the Encryption At Rest Options. — shape: {Enabled?: any, KmsKeyId?: any}
  --AutoTuneOptions: record # Specifies the Auto-Tune options: the Auto-Tune desired state for the domain, rollback state when disabling Auto-Tune options and list of maintenance schedules. — shape: {DesiredState?: any, RollbackOnDisable?: any, MaintenanceSchedules?: any}
  --DryRun: oneof<nothing, bool> #  This flag, when set to True, specifies whether the <code>UpdateElasticsearchDomain</code> request should return the results of validation checks without actually applying the change. This flag, when set to True, specifies the deployment mechanism through which the update shall be applied on the domain. This will not actually perform the Update. 
]: any -> record<DomainConfig: record<ElasticsearchVersion: record<Options: record, Status: record>, ElasticsearchClusterConfig: record<Options: record, Status: record>, EBSOptions: record<Options: record, Status: record>, AccessPolicies: record<Options: record, Status: record>, SnapshotOptions: record<Options: record, Status: record>, VPCOptions: record<Options: record, Status: record>, CognitoOptions: record<Options: record, Status: record>, EncryptionAtRestOptions: record<Options: record, Status: record>, NodeToNodeEncryptionOptions: record<Options: record, Status: record>, AdvancedOptions: record<Options: record, Status: record>, LogPublishingOptions: record<Options: record, Status: record>, DomainEndpointOptions: record<Options: record, Status: record>, AdvancedSecurityOptions: record<Options: record, Status: record>, AutoTuneOptions: record<Options: record, Status: record>, ChangeProgressDetails: record<ChangeId: record, Message: record>>, DryRunResults: record<DeploymentType: record, Message: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/es/domain/($DomainName)/config")
  let body = {ElasticsearchClusterConfig: $ElasticsearchClusterConfig, EBSOptions: $EBSOptions, SnapshotOptions: $SnapshotOptions, VPCOptions: $VPCOptions, CognitoOptions: $CognitoOptions, AdvancedOptions: $AdvancedOptions, AccessPolicies: $AccessPolicies, LogPublishingOptions: $LogPublishingOptions, DomainEndpointOptions: $DomainEndpointOptions, AdvancedSecurityOptions: $AdvancedSecurityOptions, NodeToNodeEncryptionOptions: $NodeToNodeEncryptionOptions, EncryptionAtRestOptions: $EncryptionAtRestOptions, AutoTuneOptions: $AutoTuneOptions, DryRun: $DryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
#
# POST /2015-01-01/es/domain-info
# operationId: DescribeElasticsearchDomains
export def "2015-01-01-es-domain-info DescribeElasticsearchDomains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  DomainNames: list # A list of Elasticsearch domain names.
]: any -> record<DomainStatusList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/domain-info")
  let body = {DomainNames: $DomainNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
#
# GET /2015-01-01/es/instanceTypeLimits/{ElasticsearchVersion}/{InstanceType}
# operationId: DescribeElasticsearchInstanceTypeLimits
export def "2015-01-01-es-instance-type-limits DescribeElasticsearchInstanceTypeLimits" [
  InstanceType: string
  ElasticsearchVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domainName: string #  DomainName represents the name of the Domain that we are trying to modify. This should be present only if we are querying for Elasticsearch <code> <a>Limits</a> </code> for existing domain. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<LimitsByRole: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domainName" $domainName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-01-01/es/instanceTypeLimits/($ElasticsearchVersion)/($InstanceType)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the inbound cross-cluster search connections for a destination domain.
#
# POST /2015-01-01/es/ccs/inboundConnection/search
# operationId: DescribeInboundCrossClusterSearchConnections
# --Filters item shape: {Name?: any, Values?: any}
export def "2015-01-01-es-ccs-inbound-connection-search DescribeInboundCrossClusterSearchConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --Filters: list #  A list of filters used to match properties for inbound cross-cluster search connection. Available <code><a>Filter</a></code> names for this operation are: <ul> <li>cross-cluster-search-connection-id</li> <li>source-domain-info.domain-name</li> <li>source-domain-info.owner-id</li> <li>source-domain-info.region</li> <li>destination-domain-info.domain-name</li> </ul>  — item shape: {Name?: any, Values?: any}
  --MaxResults: int #  Set this value to limit the number of results returned. 
  --NextToken: string #  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
]: any -> record<CrossClusterSearchConnections: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/ccs/inboundConnection/search" $qp)
  let body = {Filters: $Filters, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all the outbound cross-cluster search connections for a source domain.
#
# POST /2015-01-01/es/ccs/outboundConnection/search
# operationId: DescribeOutboundCrossClusterSearchConnections
# --Filters item shape: {Name?: any, Values?: any}
export def "2015-01-01-es-ccs-outbound-connection-search DescribeOutboundCrossClusterSearchConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --Filters: list #  A list of filters used to match properties for outbound cross-cluster search connection. Available <code><a>Filter</a></code> names for this operation are: <ul> <li>cross-cluster-search-connection-id</li> <li>destination-domain-info.domain-name</li> <li>destination-domain-info.owner-id</li> <li>destination-domain-info.region</li> <li>source-domain-info.domain-name</li> </ul>  — item shape: {Name?: any, Values?: any}
  --MaxResults: int #  Set this value to limit the number of results returned. 
  --NextToken: string #  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
]: any -> record<CrossClusterSearchConnections: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/ccs/outboundConnection/search" $qp)
  let body = {Filters: $Filters, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes all packages available to Amazon ES. Includes options for filtering, limiting the number of results, and pagination.
#
# POST /2015-01-01/packages/describe
# operationId: DescribePackages
# --Filters item shape: {Name?: any, Value?: any}
export def "2015-01-01-packages-describe DescribePackages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --Filters: list # A list of <code>DescribePackagesFilter</code> to filter the packages included in a <code>DescribePackages</code> response. — item shape: {Name?: any, Value?: any}
  --MaxResults: int #  Set this value to limit the number of results returned. 
  --NextToken: string #  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
]: any -> record<PackageDetailsList: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/packages/describe" $qp)
  let body = {Filters: $Filters, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists available reserved Elasticsearch instance offerings.
#
# GET /2015-01-01/es/reservedInstanceOfferings
# operationId: DescribeReservedElasticsearchInstanceOfferings
export def "2015-01-01-es-reserved-instance-offerings DescribeReservedElasticsearchInstanceOfferings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offeringId: string # The offering identifier filter value. Use this parameter to show only the available offering that matches the specified reservation identifier.
  --maxResults: int # Set this value to limit the number of results returned. If not specified, defaults to 100.
  --nextToken: string # NextToken should be sent in case if earlier API call produced result containing NextToken. It is used for pagination.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, ReservedElasticsearchInstanceOfferings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offeringId" $offeringId "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/reservedInstanceOfferings" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about reserved Elasticsearch instances for this account.
#
# GET /2015-01-01/es/reservedInstances
# operationId: DescribeReservedElasticsearchInstances
export def "2015-01-01-es-reserved-instances DescribeReservedElasticsearchInstances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reservationId: string # The reserved instance identifier filter value. Use this parameter to show only the reservation that matches the specified reserved Elasticsearch instance ID.
  --maxResults: int # Set this value to limit the number of results returned. If not specified, defaults to 100.
  --nextToken: string # NextToken should be sent in case if earlier API call produced result containing NextToken. It is used for pagination.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, ReservedElasticsearchInstances: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reservationId" $reservationId "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/reservedInstances" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes one or more Amazon OpenSearch Service-managed VPC endpoints.
#
# POST /2015-01-01/es/vpcEndpoints/describe
# operationId: DescribeVpcEndpoints
export def "2015-01-01-es-vpc-endpoints-describe DescribeVpcEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  VpcEndpointIds: list # The unique identifiers of the endpoints to get information about.
]: any -> record<VpcEndpoints: record, VpcEndpointErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/vpcEndpoints/describe")
  let body = {VpcEndpointIds: $VpcEndpointIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Dissociates a package from the Amazon ES domain.
#
# POST /2015-01-01/packages/dissociate/{PackageID}/{DomainName}
# operationId: DissociatePackage
export def "2015-01-01-packages-dissociate DissociatePackage" [
  PackageID: string
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DomainPackageDetails: record<PackageID: record, PackageName: record, PackageType: record, LastUpdated: record, DomainName: record, DomainPackageStatus: record, PackageVersion: string, ReferencePath: record, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/packages/dissociate/($PackageID)/($DomainName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
#
# GET /2015-01-01/es/compatibleVersions
# operationId: GetCompatibleElasticsearchVersions
export def "2015-01-01-es-compatible-versions GetCompatibleElasticsearchVersions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domainName: string
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<CompatibleElasticsearchVersions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domainName" $domainName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/compatibleVersions" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of versions of the package, along with their creation time and commit message.
#
# GET /2015-01-01/packages/{PackageID}/history
# operationId: GetPackageVersionHistory
export def "2015-01-01-packages-history GetPackageVersionHistory" [
  PackageID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: int # Limits results to a maximum number of versions.
  --nextToken: string # Used for pagination. Only necessary if a previous API call includes a non-null NextToken value. If provided, returns results for the next page.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<PackageID: string, PackageVersionHistoryList: record, NextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-01-01/packages/($PackageID)/history" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the complete history of the last 10 upgrades that were performed on the domain.
#
# GET /2015-01-01/es/upgradeDomain/{DomainName}/history
# operationId: GetUpgradeHistory
export def "2015-01-01-es-upgrade-domain-history GetUpgradeHistory" [
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: int
  --nextToken: string
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<UpgradeHistories: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-01-01/es/upgradeDomain/($DomainName)/history" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
#
# GET /2015-01-01/es/upgradeDomain/{DomainName}/status
# operationId: GetUpgradeStatus
export def "2015-01-01-es-upgrade-domain-status GetUpgradeStatus" [
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<UpgradeStep: record, StepStatus: record, UpgradeName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/es/upgradeDomain/($DomainName)/status")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the name of all Elasticsearch domains owned by the current user's account. 
#
# GET /2015-01-01/domain
# operationId: ListDomainNames
export def "2015-01-01-domain ListDomainNames" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --engineType: string@engineType-completer #  Optional parameter to filter the output by domain engine type. Acceptable values are 'Elasticsearch' and 'OpenSearch'. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DomainNames: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "engineType" $engineType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/domain" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all Amazon ES domains associated with the package.
#
# GET /2015-01-01/packages/{PackageID}/domains
# operationId: ListDomainsForPackage
export def "2015-01-01-packages-domains ListDomainsForPackage" [
  PackageID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: int # Limits results to a maximum number of domains.
  --nextToken: string # Used for pagination. Only necessary if a previous API call includes a non-null NextToken value. If provided, returns results for the next page.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DomainPackageDetailsList: record, NextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-01-01/packages/($PackageID)/domains" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Elasticsearch instance types that are supported for given ElasticsearchVersion
#
# GET /2015-01-01/es/instanceTypes/{ElasticsearchVersion}
# operationId: ListElasticsearchInstanceTypes
export def "2015-01-01-es-instance-types ListElasticsearchInstanceTypes" [
  ElasticsearchVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domainName: string # DomainName represents the name of the Domain that we are trying to modify. This should be present only if we are querying for list of available Elasticsearch instance types when modifying existing domain. 
  --maxResults: int #  Set this value to limit the number of results returned. Value provided must be greater than 30 else it wont be honored. 
  --nextToken: string # NextToken should be sent in case if earlier API call produced result containing NextToken. It is used for pagination. 
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<ElasticsearchInstanceTypes: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domainName" $domainName "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-01-01/es/instanceTypes/($ElasticsearchVersion)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all supported Elasticsearch versions
#
# GET /2015-01-01/es/versions
# operationId: ListElasticsearchVersions
export def "2015-01-01-es-versions ListElasticsearchVersions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: int #  Set this value to limit the number of results returned. Value provided must be greater than 10 else it wont be honored. 
  --nextToken: string
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<ElasticsearchVersions: list<string>, NextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/es/versions" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all packages associated with the Amazon ES domain.
#
# GET /2015-01-01/domain/{DomainName}/packages
# operationId: ListPackagesForDomain
export def "2015-01-01-domain-packages ListPackagesForDomain" [
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: int # Limits results to a maximum number of packages.
  --nextToken: string # Used for pagination. Only necessary if a previous API call includes a non-null NextToken value. If provided, returns results for the next page.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DomainPackageDetailsList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-01-01/domain/($DomainName)/packages" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all tags for the given Elasticsearch domain.
#
# GET /2015-01-01/tags/#arn
# operationId: ListTags
export def "2015-01-01-tags-arn ListTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --arn: string #  Specify the <code>ARN</code> for the Elasticsearch domain to which the tags are attached that you want to view.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<TagList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "arn" $arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-01-01/tags/#arn" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves information about each principal that is allowed to access a given Amazon OpenSearch Service domain through the use of an interface VPC endpoint.
#
# GET /2015-01-01/es/domain/{DomainName}/listVpcEndpointAccess
# operationId: ListVpcEndpointAccess
export def "2015-01-01-es-domain-list-vpc-endpoint-access ListVpcEndpointAccess" [
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nextToken: string # Provides an identifier to allow retrieval of paginated results.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<AuthorizedPrincipalList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-01-01/es/domain/($DomainName)/listVpcEndpointAccess" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all Amazon OpenSearch Service-managed VPC endpoints associated with a particular domain.
#
# GET /2015-01-01/es/domain/{DomainName}/vpcEndpoints
# operationId: ListVpcEndpointsForDomain
export def "2015-01-01-es-domain-vpc-endpoints ListVpcEndpointsForDomain" [
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nextToken: string # Provides an identifier to allow retrieval of paginated results.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<VpcEndpointSummaryList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2015-01-01/es/domain/($DomainName)/vpcEndpoints" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows you to purchase reserved Elasticsearch instances.
#
# POST /2015-01-01/es/purchaseReservedInstanceOffering
# operationId: PurchaseReservedElasticsearchInstanceOffering
export def "2015-01-01-es-purchase-reserved-instance-offering PurchaseReservedElasticsearchInstanceOffering" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  ReservedElasticsearchInstanceOfferingId: string # The ID of the reserved Elasticsearch instance offering to purchase.
  ReservationName: string # A customer-specified identifier to track this reservation.
  --InstanceCount: int # Specifies the number of EC2 instances in the Elasticsearch domain.
]: any -> record<ReservedElasticsearchInstanceId: record, ReservationName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/purchaseReservedInstanceOffering")
  let body = {ReservedElasticsearchInstanceOfferingId: $ReservedElasticsearchInstanceOfferingId, ReservationName: $ReservationName, InstanceCount: $InstanceCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Allows the destination domain owner to reject an inbound cross-cluster search connection request.
#
# PUT /2015-01-01/es/ccs/inboundConnection/{ConnectionId}/reject
# operationId: RejectInboundCrossClusterSearchConnection
export def "2015-01-01-es-ccs-inbound-connection-reject RejectInboundCrossClusterSearchConnection" [
  ConnectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<CrossClusterSearchConnection: record<SourceDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, DestinationDomainInfo: record<OwnerId: string, DomainName: string, Region: string>, CrossClusterSearchConnectionId: record, ConnectionStatus: record<StatusCode: record, Message: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/es/ccs/inboundConnection/($ConnectionId)/reject")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes the specified set of tags from the specified Elasticsearch domain.
#
# POST /2015-01-01/tags-removal
# operationId: RemoveTags
export def "2015-01-01-tags-removal RemoveTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  ARN: string # The Amazon Resource Name (ARN) of the Elasticsearch domain. See <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html" target="_blank">Identifiers for IAM Entities</a> in <i>Using AWS Identity and Access Management</i> for more information.
  TagKeys: list # Specifies the <code>TagKey</code> list which you want to remove from the Elasticsearch domain.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/tags-removal")
  let body = {ARN: $ARN, TagKeys: $TagKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revokes access to an Amazon OpenSearch Service domain that was provided through an interface VPC endpoint.
#
# POST /2015-01-01/es/domain/{DomainName}/revokeVpcEndpointAccess
# operationId: RevokeVpcEndpointAccess
export def "2015-01-01-es-domain-revoke-vpc-endpoint-access RevokeVpcEndpointAccess" [
  DomainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  Account: string # The account ID to revoke access from.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2015-01-01/es/domain/($DomainName)/revokeVpcEndpointAccess")
  let body = {Account: $Account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Schedules a service software update for an Amazon ES domain.
#
# POST /2015-01-01/es/serviceSoftwareUpdate/start
# operationId: StartElasticsearchServiceSoftwareUpdate
export def "2015-01-01-es-service-software-update-start StartElasticsearchServiceSoftwareUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  DomainName: string # The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
]: any -> record<ServiceSoftwareOptions: record<CurrentVersion: record, NewVersion: record, UpdateAvailable: record, Cancellable: record, UpdateStatus: record, Description: record, AutomatedUpdateDate: record, OptionalDeployment: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/serviceSoftwareUpdate/start")
  let body = {DomainName: $DomainName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a package for use with Amazon ES domains.
#
# POST /2015-01-01/packages/update
# operationId: UpdatePackage
# --PackageSource shape: {S3BucketName?: any, S3Key?: any}
export def "2015-01-01-packages-update UpdatePackage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  PackageID: string # Unique identifier for the package.
  PackageSource: record # The S3 location for importing the package specified as <code>S3BucketName</code> and <code>S3Key</code> — shape: {S3BucketName?: any, S3Key?: any}
  --PackageDescription: string # New description of the package.
  --CommitMessage: string # An info message for the new version which will be shown as part of <code>GetPackageVersionHistoryResponse</code>.
]: any -> record<PackageDetails: record<PackageID: record, PackageName: record, PackageType: record, PackageDescription: record, PackageStatus: record, CreatedAt: record, LastUpdatedAt: string, AvailablePackageVersion: string, ErrorDetails: record<ErrorType: string, ErrorMessage: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/packages/update")
  let body = {PackageID: $PackageID, PackageSource: $PackageSource, PackageDescription: $PackageDescription, CommitMessage: $CommitMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Modifies an Amazon OpenSearch Service-managed interface VPC endpoint.
#
# POST /2015-01-01/es/vpcEndpoints/update
# operationId: UpdateVpcEndpoint
# --VpcOptions shape: {SubnetIds?: any, SecurityGroupIds?: any}
export def "2015-01-01-es-vpc-endpoints-update UpdateVpcEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  VpcEndpointId: string # Unique identifier of the VPC endpoint to be updated.
  VpcOptions: record # Options to specify the subnets and security groups for VPC endpoint. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html" target="_blank"> VPC Endpoints for Amazon Elasticsearch Service Domains</a>. — shape: {SubnetIds?: any, SecurityGroupIds?: any}
]: any -> record<VpcEndpoint: record<VpcEndpointId: record, VpcEndpointOwner: record, DomainArn: record, VpcOptions: record<VPCId: record, SubnetIds: record, AvailabilityZones: record, SecurityGroupIds: record>, Status: record, Endpoint: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/vpcEndpoints/update")
  let body = {VpcEndpointId: $VpcEndpointId, VpcOptions: $VpcOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
#
# POST /2015-01-01/es/upgradeDomain
# operationId: UpgradeElasticsearchDomain
export def "2015-01-01-es-upgrade-domain UpgradeElasticsearchDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  DomainName: string # The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  TargetVersion: string # The version of Elasticsearch that you intend to upgrade the domain to.
  --PerformCheckOnly: oneof<nothing, bool> #  This flag, when set to True, indicates that an Upgrade Eligibility Check needs to be performed. This will not actually perform the Upgrade. 
]: any -> record<DomainName: string, TargetVersion: record, PerformCheckOnly: record, ChangeProgressDetails: record<ChangeId: record, Message: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-01-01/es/upgradeDomain")
  let body = {DomainName: $DomainName, TargetVersion: $TargetVersion, PerformCheckOnly: $PerformCheckOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
