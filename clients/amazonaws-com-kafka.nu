# Auto-generated client for Managed Streaming for Kafka v2018-11-14
# Source: https://api.apis.guru/v2/specs/amazonaws.com/kafka/2018-11-14/openapi.json
# Auth: --token flag or $env.MANAGED_STREAMING_FOR_KAFKA_TOKEN

const BASE_URL = "http://kafka.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MANAGED_STREAMING_FOR_KAFKA_TOKEN | default "" }
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

def base-url-completer [] { ["http://kafka.us-east-1.amazonaws.com" "http://kafka.us-east-2.amazonaws.com" "http://kafka.us-west-1.amazonaws.com" "http://kafka.us-west-2.amazonaws.com" "http://kafka.us-gov-west-1.amazonaws.com" "http://kafka.us-gov-east-1.amazonaws.com" "http://kafka.ca-central-1.amazonaws.com" "http://kafka.eu-north-1.amazonaws.com" "http://kafka.eu-west-1.amazonaws.com" "http://kafka.eu-west-2.amazonaws.com" "http://kafka.eu-west-3.amazonaws.com" "http://kafka.eu-central-1.amazonaws.com" "http://kafka.eu-south-1.amazonaws.com" "http://kafka.af-south-1.amazonaws.com" "http://kafka.ap-northeast-1.amazonaws.com" "http://kafka.ap-northeast-2.amazonaws.com" "http://kafka.ap-northeast-3.amazonaws.com" "http://kafka.ap-southeast-1.amazonaws.com" "http://kafka.ap-southeast-2.amazonaws.com" "http://kafka.ap-east-1.amazonaws.com" "http://kafka.ap-south-1.amazonaws.com" "http://kafka.sa-east-1.amazonaws.com" "http://kafka.me-south-1.amazonaws.com" "https://kafka.us-east-1.amazonaws.com" "https://kafka.us-east-2.amazonaws.com" "https://kafka.us-west-1.amazonaws.com" "https://kafka.us-west-2.amazonaws.com" "https://kafka.us-gov-west-1.amazonaws.com" "https://kafka.us-gov-east-1.amazonaws.com" "https://kafka.ca-central-1.amazonaws.com" "https://kafka.eu-north-1.amazonaws.com" "https://kafka.eu-west-1.amazonaws.com" "https://kafka.eu-west-2.amazonaws.com" "https://kafka.eu-west-3.amazonaws.com" "https://kafka.eu-central-1.amazonaws.com" "https://kafka.eu-south-1.amazonaws.com" "https://kafka.af-south-1.amazonaws.com" "https://kafka.ap-northeast-1.amazonaws.com" "https://kafka.ap-northeast-2.amazonaws.com" "https://kafka.ap-northeast-3.amazonaws.com" "https://kafka.ap-southeast-1.amazonaws.com" "https://kafka.ap-southeast-2.amazonaws.com" "https://kafka.ap-east-1.amazonaws.com" "https://kafka.ap-south-1.amazonaws.com" "https://kafka.sa-east-1.amazonaws.com" "https://kafka.me-south-1.amazonaws.com" "http://kafka.cn-north-1.amazonaws.com.cn" "http://kafka.cn-northwest-1.amazonaws.com.cn" "https://kafka.cn-north-1.amazonaws.com.cn" "https://kafka.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def enhanced-monitoring-completer [] { ["DEFAULT" "PER_BROKER" "PER_TOPIC_PER_BROKER" "PER_TOPIC_PER_PARTITION"] }
def storage-mode-completer [] { ["LOCAL" "TIERED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "clusters-scram-secrets create-batch-associate" } } | get name | first)
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

# Associates one or more Scram Secrets with an Amazon MSK cluster.
#
# POST /v1/clusters/{clusterArn}/scram-secrets
# operationId: BatchAssociateScramSecret
export def "clusters-scram-secrets create-batch-associate" [
  cluster_arn: string
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
  secret_arn_list: list<string> # List of AWS Secrets Manager secret ARNs.
]: any -> record<ClusterArn: record, UnprocessedScramSecrets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/scram-secrets"))
  let req_body = {"secretArnList": $secret_arn_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disassociates one or more Scram Secrets from an Amazon MSK cluster.
#
# PATCH /v1/clusters/{clusterArn}/scram-secrets
# operationId: BatchDisassociateScramSecret
export def "clusters-scram-secrets update-batch-disassociate" [
  cluster_arn: string
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
  secret_arn_list: list<string> # List of AWS Secrets Manager secret ARNs.
]: any -> record<ClusterArn: record, UnprocessedScramSecrets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/scram-secrets"))
  let req_body = {"secretArnList": $secret_arn_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of the Scram Secrets associated with an Amazon MSK cluster.
#
# GET /v1/clusters/{clusterArn}/scram-secrets
# operationId: ListScramSecrets
export def "clusters-scram-secrets list" [
  cluster_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maxResults of the query.
  --next-token: string # The nextToken of the query.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, SecretArnList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/scram-secrets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates a new MSK cluster.
#
# POST /v1/clusters
# operationId: CreateCluster
# --brokerNodeGroupInfo shape: {BrokerAZDistribution?: any, ClientSubnets?: any, InstanceType?: any, SecurityGroups?: any, StorageInfo?: any, ConnectivityInfo?: any}
# --clientAuthentication shape: {Sasl?: any, Tls?: any, Unauthenticated?: any}
# --configurationInfo shape: {Arn?: any, Revision?: any}
# --encryptionInfo shape: {EncryptionAtRest?: any, EncryptionInTransit?: any}
# --openMonitoring shape: {Prometheus?: any}
# --loggingInfo shape: {BrokerLogs?: any}
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
  broker_node_group_info: record # Describes the setup to be used for Apache Kafka broker nodes in the cluster. — shape: {BrokerAZDistribution?: any, ClientSubnets?: any, InstanceType?: any, SecurityGroups?: any, StorageInfo?: any, ConnectivityInfo?: any}
  --client-authentication: record # Includes all client authentication information. — shape: {Sasl?: any, Tls?: any, Unauthenticated?: any}
  cluster_name: string # The name of the cluster.
  --configuration-info: record # Specifies the configuration to use for the brokers. — shape: {Arn?: any, Revision?: any}
  --encryption-info: record # Includes encryption-related information, such as the AWS KMS key used for encrypting data at rest and whether you want MSK to encrypt your data in transit. — shape: {EncryptionAtRest?: any, EncryptionInTransit?: any}
  --enhanced-monitoring: string@enhanced-monitoring-completer # Specifies which metrics are gathered for the MSK cluster. This property has the following possible values: DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER, and PER_TOPIC_PER_PARTITION. For a list of the metrics associated with each of these levels of monitoring, see Monitoring (https://docs.aws.amazon.com/msk/latest/developerguide/monitoring.html).
  --open-monitoring: record # JMX and Node monitoring for the MSK cluster. — shape: {Prometheus?: any}
  kafka_version: string # The version of Apache Kafka.
  --logging-info: record # shape: {BrokerLogs?: any}
  number_of_broker_nodes: int # The number of broker nodes in the cluster.
  --tags: record # Create tags when creating the cluster.
  --storage-mode: string@storage-mode-completer # Controls storage mode for various supported storage tiers.
]: any -> record<ClusterArn: record, ClusterName: record, State: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/clusters")
  let req_body = {"brokerNodeGroupInfo": $broker_node_group_info, "clientAuthentication": $client_authentication, "clusterName": $cluster_name, "configurationInfo": $configuration_info, "encryptionInfo": $encryption_info, "enhancedMonitoring": $enhanced_monitoring, "openMonitoring": $open_monitoring, "kafkaVersion": $kafka_version, "loggingInfo": $logging_info, "numberOfBrokerNodes": $number_of_broker_nodes, "tags": $tags, "storageMode": $storage_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of all the MSK clusters in the current Region.
#
# GET /v1/clusters
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
  --cluster-name-filter: string # Specify a prefix of the name of the clusters that you want to list. The service lists all the clusters whose names start with this prefix.
  --max-results: int # The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.
  --next-token: string # The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. To get the next batch, provide this token in your next request.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ClusterInfoList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clusterNameFilter" $cluster_name_filter "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/clusters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"clusterNameFilter": $cluster_name_filter, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates a new MSK cluster.
#
# POST /api/v2/clusters
# operationId: CreateClusterV2
# --provisioned shape: {BrokerNodeGroupInfo?: any, ClientAuthentication?: any, ConfigurationInfo?: any, EncryptionInfo?: any, EnhancedMonitoring?: any, OpenMonitoring?: any, KafkaVersion?: any, LoggingInfo?: any, NumberOfBrokerNodes?: any, StorageMode?: any}
# --serverless shape: {VpcConfigs?: any, ClientAuthentication?: any}
export def "clusters create-1" [
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
  cluster_name: string # The name of the cluster.
  --tags: record # A map of tags that you want the cluster to have.
  --provisioned: record # Provisioned cluster request. — shape: {BrokerNodeGroupInfo?: any, ClientAuthentication?: any, ConfigurationInfo?: any, EncryptionInfo?: any, EnhancedMonitoring?: any, OpenMonitoring?: any, KafkaVersion?: any, LoggingInfo?: any, NumberOfBrokerNodes?: any, StorageMode?: any}
  --serverless: record # Serverless cluster request. — shape: {VpcConfigs?: any, ClientAuthentication?: any}
]: any -> record<ClusterArn: record, ClusterName: record, State: record, ClusterType: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/clusters")
  let req_body = {"clusterName": $cluster_name, "tags": $tags, "provisioned": $provisioned, "serverless": $serverless} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of all the MSK clusters in the current Region.
#
# GET /api/v2/clusters
# operationId: ListClustersV2
export def "clusters list-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-name-filter: string # Specify a prefix of the names of the clusters that you want to list. The service lists all the clusters whose names start with this prefix.
  --cluster-type-filter: string # Specify either PROVISIONED or SERVERLESS.
  --max-results: int # The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.
  --next-token: string # The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. To get the next batch, provide this token in your next request.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ClusterInfoList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clusterNameFilter" $cluster_name_filter "scalar") (serialize-qp "clusterTypeFilter" $cluster_type_filter "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/clusters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"clusterNameFilter": $cluster_name_filter, "clusterTypeFilter": $cluster_type_filter, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates a new MSK configuration.
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
  --description: string # The description of the configuration.
  --kafka-versions: list<string> # The versions of Apache Kafka with which you can use this MSK configuration.
  name: string # The name of the configuration.
  server_properties: string # Contents of the server.properties file. When using the API, you must ensure that the contents of the file are base64 encoded. When using the AWS Management Console, the SDK, or the AWS CLI, the contents of server.properties can be in plaintext.
]: any -> record<Arn: record, CreationTime: record, LatestRevision: record<CreationTime: record, Description: record, Revision: record>, Name: record, State: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/configurations")
  let req_body = {"description": $description, "kafkaVersions": $kafka_versions, "name": $name, "serverProperties": $server_properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of all the MSK configurations in this Region.
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
  --max-results: int # The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.
  --next-token: string # The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. To get the next batch, provide this token in your next request.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Configurations: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/configurations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Deletes the MSK cluster specified by the Amazon Resource Name (ARN) in the request.
#
# DELETE /v1/clusters/{clusterArn}
# operationId: DeleteCluster
export def "clusters delete" [
  cluster_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-version: string # The current version of the MSK cluster.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ClusterArn: record, State: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let qp = [(serialize-qp "currentVersion" $current_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"currentVersion": $current_version} | compact), body: null}
}

# Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.
#
# GET /v1/clusters/{clusterArn}
# operationId: DescribeCluster
export def "clusters get-by-cluster-arn" [
  cluster_arn: string
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
]: nothing -> record<ClusterInfo: record<ActiveOperationArn: record, BrokerNodeGroupInfo: record<BrokerAZDistribution: record, ClientSubnets: record, InstanceType: record, SecurityGroups: record, StorageInfo: record, ConnectivityInfo: record>, ClientAuthentication: record<Sasl: record, Tls: record, Unauthenticated: record>, ClusterArn: record, ClusterName: record, CreationTime: record, CurrentBrokerSoftwareInfo: record<ConfigurationArn: record, ConfigurationRevision: record, KafkaVersion: record>, CurrentVersion: record, EncryptionInfo: record<EncryptionAtRest: record, EncryptionInTransit: record>, EnhancedMonitoring: record, OpenMonitoring: record<Prometheus: record>, LoggingInfo: record<BrokerLogs: record>, NumberOfBrokerNodes: record, State: record, StateInfo: record<Code: record, Message: record>, Tags: record, ZookeeperConnectString: record, ZookeeperConnectStringTls: record, StorageMode: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes an MSK Configuration.
#
# DELETE /v1/configurations/{arn}
# operationId: DeleteConfiguration
export def "configurations delete" [
  arn: string
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
]: nothing -> record<Arn: record, State: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($arn | is-empty) { error make --unspanned { msg: "path parameter 'arn' must be non-empty" } }
  let full_url = (build-url $base ({arn: (encode-path-segment $arn)} | format pattern "/v1/configurations/{arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a description of this MSK configuration.
#
# GET /v1/configurations/{arn}
# operationId: DescribeConfiguration
export def "configurations get" [
  arn: string
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
]: nothing -> record<Arn: record, CreationTime: record, Description: record, KafkaVersions: record, LatestRevision: record<CreationTime: record, Description: record, Revision: record>, Name: record, State: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($arn | is-empty) { error make --unspanned { msg: "path parameter 'arn' must be non-empty" } }
  let full_url = (build-url $base ({arn: (encode-path-segment $arn)} | format pattern "/v1/configurations/{arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an MSK configuration.
#
# PUT /v1/configurations/{arn}
# operationId: UpdateConfiguration
export def "configurations update" [
  arn: string
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
  --description: string # The description of the configuration revision.
  server_properties: string # Contents of the server.properties file. When using the API, you must ensure that the contents of the file are base64 encoded. When using the AWS Management Console, the SDK, or the AWS CLI, the contents of server.properties can be in plaintext.
]: any -> record<Arn: record, LatestRevision: record<CreationTime: record, Description: record, Revision: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($arn | is-empty) { error make --unspanned { msg: "path parameter 'arn' must be non-empty" } }
  let full_url = (build-url $base ({arn: (encode-path-segment $arn)} | format pattern "/v1/configurations/{arn}"))
  let req_body = {"description": $description, "serverProperties": $server_properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.
#
# GET /api/v2/clusters/{clusterArn}
# operationId: DescribeClusterV2
export def "clusters get-by-cluster-arn-1" [
  cluster_arn: string
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
]: nothing -> record<ClusterInfo: record<ActiveOperationArn: record, ClusterType: record, ClusterArn: record, ClusterName: record, CreationTime: record, CurrentVersion: record, State: record, StateInfo: record<Code: record, Message: record>, Tags: record, Provisioned: record<BrokerNodeGroupInfo: record, CurrentBrokerSoftwareInfo: record, ClientAuthentication: record, EncryptionInfo: record, EnhancedMonitoring: record, OpenMonitoring: record, LoggingInfo: record, NumberOfBrokerNodes: record, ZookeeperConnectString: record, ZookeeperConnectStringTls: record, StorageMode: record>, Serverless: record<VpcConfigs: record, ClientAuthentication: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/api/v2/clusters/{cluster_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a description of the cluster operation specified by the ARN.
#
# GET /v1/operations/{clusterOperationArn}
# operationId: DescribeClusterOperation
export def "operations get" [
  cluster_operation_arn: string
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
]: nothing -> record<ClusterOperationInfo: record<ClientRequestId: record, ClusterArn: record, CreationTime: record, EndTime: record, ErrorInfo: record<ErrorCode: record, ErrorString: record>, OperationArn: record, OperationState: record, OperationSteps: record, OperationType: record, SourceClusterInfo: record<BrokerEBSVolumeInfo: record, ConfigurationInfo: record, NumberOfBrokerNodes: record, EnhancedMonitoring: record, OpenMonitoring: record, KafkaVersion: record, LoggingInfo: record, InstanceType: record, ClientAuthentication: record, EncryptionInfo: record, ConnectivityInfo: record, StorageMode: record>, TargetClusterInfo: record<BrokerEBSVolumeInfo: record, ConfigurationInfo: record, NumberOfBrokerNodes: record, EnhancedMonitoring: record, OpenMonitoring: record, KafkaVersion: record, LoggingInfo: record, InstanceType: record, ClientAuthentication: record, EncryptionInfo: record, ConnectivityInfo: record, StorageMode: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_operation_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterOperationArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_operation_arn: (encode-path-segment $cluster_operation_arn)} | format pattern "/v1/operations/{cluster_operation_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a description of this revision of the configuration.
#
# GET /v1/configurations/{arn}/revisions/{revision}
# operationId: DescribeConfigurationRevision
export def "configurations-revisions get" [
  arn: string
  revision: int
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
]: nothing -> record<Arn: record, CreationTime: record, Description: record, Revision: record, ServerProperties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($arn | is-empty) { error make --unspanned { msg: "path parameter 'arn' must be non-empty" } }
  if ($revision | is-empty) { error make --unspanned { msg: "path parameter 'revision' must be non-empty" } }
  let full_url = (build-url $base ({arn: (encode-path-segment $arn), revision: (encode-path-segment $revision)} | format pattern "/v1/configurations/{arn}/revisions/{revision}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# A list of brokers that a client application can use to bootstrap.
#
# GET /v1/clusters/{clusterArn}/bootstrap-brokers
# operationId: GetBootstrapBrokers
export def "clusters-bootstrap-brokers get" [
  cluster_arn: string
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
]: nothing -> record<BootstrapBrokerString: record, BootstrapBrokerStringTls: record, BootstrapBrokerStringSaslScram: record, BootstrapBrokerStringSaslIam: record, BootstrapBrokerStringPublicTls: record, BootstrapBrokerStringPublicSaslScram: record, BootstrapBrokerStringPublicSaslIam: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/bootstrap-brokers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the Apache Kafka versions to which you can update the MSK cluster.
#
# GET /v1/compatible-kafka-versions
# operationId: GetCompatibleKafkaVersions
export def "compatible-kafka-versions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-arn: string # The Amazon Resource Name (ARN) of the cluster check.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CompatibleKafkaVersions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clusterArn" $cluster_arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/compatible-kafka-versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"clusterArn": $cluster_arn} | compact), body: null}
}

# Returns a list of all the operations that have been performed on the specified MSK cluster.
#
# GET /v1/clusters/{clusterArn}/operations
# operationId: ListClusterOperations
export def "clusters-operations list" [
  cluster_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.
  --next-token: string # The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. To get the next batch, provide this token in your next request.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ClusterOperationInfoList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/operations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Returns a list of all the MSK configurations in this Region.
#
# GET /v1/configurations/{arn}/revisions
# operationId: ListConfigurationRevisions
export def "configurations-revisions list" [
  arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.
  --next-token: string # The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. To get the next batch, provide this token in your next request.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, Revisions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($arn | is-empty) { error make --unspanned { msg: "path parameter 'arn' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({arn: (encode-path-segment $arn)} | format pattern "/v1/configurations/{arn}/revisions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Returns a list of Apache Kafka versions.
#
# GET /v1/kafka-versions
# operationId: ListKafkaVersions
export def "kafka-versions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.
  --next-token: string # The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. To get the next batch, provide this token in your next request.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<KafkaVersions: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/kafka-versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Returns a list of the broker nodes in the cluster.
#
# GET /v1/clusters/{clusterArn}/nodes
# operationId: ListNodes
export def "clusters-nodes list" [
  cluster_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.
  --next-token: string # The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. To get the next batch, provide this token in your next request.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, NodeInfoList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/nodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Returns a list of the tags associated with the specified resource.
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
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds tags to the specified MSK resource.
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
  tags: record # The key-value pair for the resource tag.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reboots brokers.
#
# PUT /v1/clusters/{clusterArn}/reboot-broker
# operationId: RebootBroker
export def "clusters-reboot-broker update" [
  cluster_arn: string
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
  broker_ids: list<string> # The list of broker IDs to be rebooted. The reboot-broker operation supports rebooting one broker at a time.
]: any -> record<ClusterArn: record, ClusterOperationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/reboot-broker"))
  let req_body = {"brokerIds": $broker_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes the tags associated with the keys that are provided in the query.
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
  --tag-keys: list # Tag keys must be unique for a given cluster. In addition, the following restrictions apply: Each tag key must be unique. If you add a tag with a key that's already in use, your new tag overwrites the existing key-value pair. You can't start a tag key with aws: because this prefix is reserved for use by AWS. AWS creates tags that begin with this prefix on your behalf, but you can't edit or delete them. Tag keys must be between 1 and 128 Unicode characters in length. Tag keys must consist of the following characters: Unicode letters, digits, white space, and the following special characters: _ . / = + - @.
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
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/v1/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}

# Updates the number of broker nodes in the cluster.
#
# PUT /v1/clusters/{clusterArn}/nodes/count
# operationId: UpdateBrokerCount
export def "clusters-nodes-count update-broker" [
  cluster_arn: string
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
  current_version: string # The version of cluster to update from. A successful operation will then generate a new version.
  target_number_of_broker_nodes: int # The number of broker nodes that you want the cluster to have after this operation completes successfully.
]: any -> record<ClusterArn: record, ClusterOperationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/nodes/count"))
  let req_body = {"currentVersion": $current_version, "targetNumberOfBrokerNodes": $target_number_of_broker_nodes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates EC2 instance type.
#
# PUT /v1/clusters/{clusterArn}/nodes/type
# operationId: UpdateBrokerType
export def "clusters-nodes-type update-broker" [
  cluster_arn: string
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
  current_version: string # The cluster version that you want to change. After this operation completes successfully, the cluster will have a new version.
  target_instance_type: string # The Amazon MSK broker type that you want all of the brokers in this cluster to be.
]: any -> record<ClusterArn: record, ClusterOperationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/nodes/type"))
  let req_body = {"currentVersion": $current_version, "targetInstanceType": $target_instance_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the EBS storage associated with MSK brokers.
#
# PUT /v1/clusters/{clusterArn}/nodes/storage
# operationId: UpdateBrokerStorage
# --targetBrokerEBSVolumeInfo item shape: {KafkaBrokerNodeId: any, ProvisionedThroughput?: any, VolumeSizeGB?: any}
export def "clusters-nodes-storage update-broker" [
  cluster_arn: string
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
  current_version: string # The version of cluster to update from. A successful operation will then generate a new version.
  target_broker_ebs_volume_info: list # Describes the target volume size and the ID of the broker to apply the update to. — item shape: {KafkaBrokerNodeId: any, ProvisionedThroughput?: any, VolumeSizeGB?: any}
]: any -> record<ClusterArn: record, ClusterOperationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/nodes/storage"))
  let req_body = {"currentVersion": $current_version, "targetBrokerEBSVolumeInfo": $target_broker_ebs_volume_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the cluster's connectivity configuration.
#
# PUT /v1/clusters/{clusterArn}/connectivity
# operationId: UpdateConnectivity
# --connectivityInfo shape: {PublicAccess?: any}
export def "clusters-connectivity update" [
  cluster_arn: string
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
  connectivity_info: record # Information about the broker access configuration. — shape: {PublicAccess?: any}
  current_version: string # The version of the MSK cluster to update. Cluster versions aren't simple numbers. You can describe an MSK cluster to find its version. When this update operation is successful, it generates a new cluster version.
]: any -> record<ClusterArn: record, ClusterOperationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/connectivity"))
  let req_body = {"connectivityInfo": $connectivity_info, "currentVersion": $current_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the cluster with the configuration that is specified in the request body.
#
# PUT /v1/clusters/{clusterArn}/configuration
# operationId: UpdateClusterConfiguration
# --configurationInfo shape: {Arn?: any, Revision?: any}
export def "clusters-configuration update" [
  cluster_arn: string
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
  configuration_info: record # Specifies the configuration to use for the brokers. — shape: {Arn?: any, Revision?: any}
  current_version: string # The version of the cluster that needs to be updated.
]: any -> record<ClusterArn: record, ClusterOperationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/configuration"))
  let req_body = {"configurationInfo": $configuration_info, "currentVersion": $current_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the Apache Kafka version for the cluster.
#
# PUT /v1/clusters/{clusterArn}/version
# operationId: UpdateClusterKafkaVersion
# --configurationInfo shape: {Arn?: any, Revision?: any}
export def "clusters-version update-kafka" [
  cluster_arn: string
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
  --configuration-info: record # Specifies the configuration to use for the brokers. — shape: {Arn?: any, Revision?: any}
  current_version: string # Current cluster version.
  target_kafka_version: string # Target Kafka version.
]: any -> record<ClusterArn: record, ClusterOperationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/version"))
  let req_body = {"configurationInfo": $configuration_info, "currentVersion": $current_version, "targetKafkaVersion": $target_kafka_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the monitoring settings for the cluster. You can use this operation to specify which Apache Kafka metrics you want Amazon MSK to send to Amazon CloudWatch. You can also specify settings for open monitoring with Prometheus.
#
# PUT /v1/clusters/{clusterArn}/monitoring
# operationId: UpdateMonitoring
# --openMonitoring shape: {Prometheus?: any}
# --loggingInfo shape: {BrokerLogs?: any}
export def "clusters-monitoring update" [
  cluster_arn: string
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
  current_version: string # The version of the MSK cluster to update. Cluster versions aren't simple numbers. You can describe an MSK cluster to find its version. When this update operation is successful, it generates a new cluster version.
  --enhanced-monitoring: string@enhanced-monitoring-completer # Specifies which metrics are gathered for the MSK cluster. This property has the following possible values: DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER, and PER_TOPIC_PER_PARTITION. For a list of the metrics associated with each of these levels of monitoring, see Monitoring (https://docs.aws.amazon.com/msk/latest/developerguide/monitoring.html).
  --open-monitoring: record # JMX and Node monitoring for the MSK cluster. — shape: {Prometheus?: any}
  --logging-info: record # shape: {BrokerLogs?: any}
]: any -> record<ClusterArn: record, ClusterOperationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/monitoring"))
  let req_body = {"currentVersion": $current_version, "enhancedMonitoring": $enhanced_monitoring, "openMonitoring": $open_monitoring, "loggingInfo": $logging_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the security settings for the cluster. You can use this operation to specify encryption and authentication on existing clusters.
#
# PATCH /v1/clusters/{clusterArn}/security
# operationId: UpdateSecurity
# --clientAuthentication shape: {Sasl?: any, Tls?: any, Unauthenticated?: any}
# --encryptionInfo shape: {EncryptionAtRest?: any, EncryptionInTransit?: any}
export def "clusters-security update" [
  cluster_arn: string
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
  --client-authentication: record # Includes all client authentication information. — shape: {Sasl?: any, Tls?: any, Unauthenticated?: any}
  current_version: string # The version of the MSK cluster to update. Cluster versions aren't simple numbers. You can describe an MSK cluster to find its version. When this update operation is successful, it generates a new cluster version.
  --encryption-info: record # Includes encryption-related information, such as the AWS KMS key used for encrypting data at rest and whether you want MSK to encrypt your data in transit. — shape: {EncryptionAtRest?: any, EncryptionInTransit?: any}
]: any -> record<ClusterArn: record, ClusterOperationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/security"))
  let req_body = {"clientAuthentication": $client_authentication, "currentVersion": $current_version, "encryptionInfo": $encryption_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates cluster broker volume size (or) sets cluster storage mode to TIERED.
#
# PUT /v1/clusters/{clusterArn}/storage
# operationId: UpdateStorage
# --provisionedThroughput shape: {Enabled?: any, VolumeThroughput?: any}
export def "clusters-storage update" [
  cluster_arn: string
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
  current_version: string # The version of cluster to update from. A successful operation will then generate a new version.
  --provisioned-throughput: record # Contains information about provisioned throughput for EBS storage volumes attached to kafka broker nodes. — shape: {Enabled?: any, VolumeThroughput?: any}
  --storage-mode: string@storage-mode-completer # Controls storage mode for various supported storage tiers.
  --volume-size-gb: int # size of the EBS volume to update.
]: any -> record<ClusterArn: record, ClusterOperationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_arn | is-empty) { error make --unspanned { msg: "path parameter 'clusterArn' must be non-empty" } }
  let full_url = (build-url $base ({cluster_arn: (encode-path-segment $cluster_arn)} | format pattern "/v1/clusters/{cluster_arn}/storage"))
  let req_body = {"currentVersion": $current_version, "provisionedThroughput": $provisioned_throughput, "storageMode": $storage_mode, "volumeSizeGB": $volume_size_gb} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
