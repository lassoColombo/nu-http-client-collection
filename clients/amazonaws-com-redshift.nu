# Auto-generated client for Amazon Redshift v2012-12-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/redshift/2012-12-01/openapi.json
# Auth: --token flag or $env.AMAZON_REDSHIFT_TOKEN

const BASE_URL = "http://redshift.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_REDSHIFT_TOKEN | default "" }
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

def base-url-completer [] { ["http://redshift.us-east-1.amazonaws.com" "http://redshift.us-east-2.amazonaws.com" "http://redshift.us-west-1.amazonaws.com" "http://redshift.us-west-2.amazonaws.com" "http://redshift.us-gov-west-1.amazonaws.com" "http://redshift.us-gov-east-1.amazonaws.com" "http://redshift.ca-central-1.amazonaws.com" "http://redshift.eu-north-1.amazonaws.com" "http://redshift.eu-west-1.amazonaws.com" "http://redshift.eu-west-2.amazonaws.com" "http://redshift.eu-west-3.amazonaws.com" "http://redshift.eu-central-1.amazonaws.com" "http://redshift.eu-south-1.amazonaws.com" "http://redshift.af-south-1.amazonaws.com" "http://redshift.ap-northeast-1.amazonaws.com" "http://redshift.ap-northeast-2.amazonaws.com" "http://redshift.ap-northeast-3.amazonaws.com" "http://redshift.ap-southeast-1.amazonaws.com" "http://redshift.ap-southeast-2.amazonaws.com" "http://redshift.ap-east-1.amazonaws.com" "http://redshift.ap-south-1.amazonaws.com" "http://redshift.sa-east-1.amazonaws.com" "http://redshift.me-south-1.amazonaws.com" "https://redshift.us-east-1.amazonaws.com" "https://redshift.us-east-2.amazonaws.com" "https://redshift.us-west-1.amazonaws.com" "https://redshift.us-west-2.amazonaws.com" "https://redshift.us-gov-west-1.amazonaws.com" "https://redshift.us-gov-east-1.amazonaws.com" "https://redshift.ca-central-1.amazonaws.com" "https://redshift.eu-north-1.amazonaws.com" "https://redshift.eu-west-1.amazonaws.com" "https://redshift.eu-west-2.amazonaws.com" "https://redshift.eu-west-3.amazonaws.com" "https://redshift.eu-central-1.amazonaws.com" "https://redshift.eu-south-1.amazonaws.com" "https://redshift.af-south-1.amazonaws.com" "https://redshift.ap-northeast-1.amazonaws.com" "https://redshift.ap-northeast-2.amazonaws.com" "https://redshift.ap-northeast-3.amazonaws.com" "https://redshift.ap-southeast-1.amazonaws.com" "https://redshift.ap-southeast-2.amazonaws.com" "https://redshift.ap-east-1.amazonaws.com" "https://redshift.ap-south-1.amazonaws.com" "https://redshift.sa-east-1.amazonaws.com" "https://redshift.me-south-1.amazonaws.com" "http://redshift.cn-north-1.amazonaws.com.cn" "http://redshift.cn-northwest-1.amazonaws.com.cn" "https://redshift.cn-north-1.amazonaws.com.cn" "https://redshift.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["AcceptReservedNodeExchange"] }
def version-completer [] { ["2012-12-01"] }
def action-completer-1 [] { ["AddPartner"] }
def action-completer-2 [] { ["AssociateDataShareConsumer"] }
def action-completer-3 [] { ["AuthorizeClusterSecurityGroupIngress"] }
def action-completer-4 [] { ["AuthorizeDataShare"] }
def action-completer-5 [] { ["AuthorizeEndpointAccess"] }
def action-completer-6 [] { ["AuthorizeSnapshotAccess"] }
def action-completer-7 [] { ["BatchDeleteClusterSnapshots"] }
def action-completer-8 [] { ["BatchModifyClusterSnapshots"] }
def action-completer-9 [] { ["CancelResize"] }
def action-completer-10 [] { ["CopyClusterSnapshot"] }
def action-completer-11 [] { ["CreateAuthenticationProfile"] }
def aqua-configuration-status-completer [] { ["auto" "disabled" "enabled"] }
def action-completer-12 [] { ["CreateCluster"] }
def action-completer-13 [] { ["CreateClusterParameterGroup"] }
def action-completer-14 [] { ["CreateClusterSecurityGroup"] }
def action-completer-15 [] { ["CreateClusterSnapshot"] }
def action-completer-16 [] { ["CreateClusterSubnetGroup"] }
def action-completer-17 [] { ["CreateEndpointAccess"] }
def action-completer-18 [] { ["CreateEventSubscription"] }
def action-completer-19 [] { ["CreateHsmClientCertificate"] }
def action-completer-20 [] { ["CreateHsmConfiguration"] }
def action-completer-21 [] { ["CreateScheduledAction"] }
def action-completer-22 [] { ["CreateSnapshotCopyGrant"] }
def action-completer-23 [] { ["CreateSnapshotSchedule"] }
def action-completer-24 [] { ["CreateTags"] }
def feature-type-completer [] { ["concurrency-scaling" "cross-region-datasharing" "spectrum"] }
def limit-type-completer [] { ["data-scanned" "time"] }
def period-completer [] { ["daily" "monthly" "weekly"] }
def breach-action-completer [] { ["disable" "emit-metric" "log"] }
def action-completer-25 [] { ["CreateUsageLimit"] }
def action-completer-26 [] { ["DeauthorizeDataShare"] }
def action-completer-27 [] { ["DeleteAuthenticationProfile"] }
def action-completer-28 [] { ["DeleteCluster"] }
def action-completer-29 [] { ["DeleteClusterParameterGroup"] }
def action-completer-30 [] { ["DeleteClusterSecurityGroup"] }
def action-completer-31 [] { ["DeleteClusterSnapshot"] }
def action-completer-32 [] { ["DeleteClusterSubnetGroup"] }
def action-completer-33 [] { ["DeleteEndpointAccess"] }
def action-completer-34 [] { ["DeleteEventSubscription"] }
def action-completer-35 [] { ["DeleteHsmClientCertificate"] }
def action-completer-36 [] { ["DeleteHsmConfiguration"] }
def action-completer-37 [] { ["DeletePartner"] }
def action-completer-38 [] { ["DeleteScheduledAction"] }
def action-completer-39 [] { ["DeleteSnapshotCopyGrant"] }
def action-completer-40 [] { ["DeleteSnapshotSchedule"] }
def action-completer-41 [] { ["DeleteTags"] }
def action-completer-42 [] { ["DeleteUsageLimit"] }
def action-completer-43 [] { ["DescribeAccountAttributes"] }
def action-completer-44 [] { ["DescribeAuthenticationProfiles"] }
def action-completer-45 [] { ["DescribeClusterDbRevisions"] }
def action-completer-46 [] { ["DescribeClusterParameterGroups"] }
def action-completer-47 [] { ["DescribeClusterParameters"] }
def action-completer-48 [] { ["DescribeClusterSecurityGroups"] }
def action-completer-49 [] { ["DescribeClusterSnapshots"] }
def action-completer-50 [] { ["DescribeClusterSubnetGroups"] }
def action-completer-51 [] { ["DescribeClusterTracks"] }
def action-completer-52 [] { ["DescribeClusterVersions"] }
def action-completer-53 [] { ["DescribeClusters"] }
def action-completer-54 [] { ["DescribeDataShares"] }
def status-completer [] { ["ACTIVE" "AVAILABLE"] }
def action-completer-55 [] { ["DescribeDataSharesForConsumer"] }
def status-completer-1 [] { ["ACTIVE" "AUTHORIZED" "DEAUTHORIZED" "PENDING_AUTHORIZATION" "REJECTED"] }
def action-completer-56 [] { ["DescribeDataSharesForProducer"] }
def action-completer-57 [] { ["DescribeDefaultClusterParameters"] }
def action-completer-58 [] { ["DescribeEndpointAccess"] }
def action-completer-59 [] { ["DescribeEndpointAuthorization"] }
def action-completer-60 [] { ["DescribeEventCategories"] }
def action-completer-61 [] { ["DescribeEventSubscriptions"] }
def source-type-completer [] { ["cluster" "cluster-parameter-group" "cluster-security-group" "cluster-snapshot" "scheduled-action"] }
def action-completer-62 [] { ["DescribeEvents"] }
def action-completer-63 [] { ["DescribeHsmClientCertificates"] }
def action-completer-64 [] { ["DescribeHsmConfigurations"] }
def action-completer-65 [] { ["DescribeLoggingStatus"] }
def action-type-completer [] { ["recommend-node-config" "resize-cluster" "restore-cluster"] }
def action-completer-66 [] { ["DescribeNodeConfigurationOptions"] }
def action-completer-67 [] { ["DescribeOrderableClusterOptions"] }
def action-completer-68 [] { ["DescribePartners"] }
def action-completer-69 [] { ["DescribeReservedNodeExchangeStatus"] }
def action-completer-70 [] { ["DescribeReservedNodeOfferings"] }
def action-completer-71 [] { ["DescribeReservedNodes"] }
def action-completer-72 [] { ["DescribeResize"] }
def target-action-type-completer [] { ["PauseCluster" "ResizeCluster" "ResumeCluster"] }
def action-completer-73 [] { ["DescribeScheduledActions"] }
def action-completer-74 [] { ["DescribeSnapshotCopyGrants"] }
def action-completer-75 [] { ["DescribeSnapshotSchedules"] }
def action-completer-76 [] { ["DescribeStorage"] }
def action-completer-77 [] { ["DescribeTableRestoreStatus"] }
def action-completer-78 [] { ["DescribeTags"] }
def action-completer-79 [] { ["DescribeUsageLimits"] }
def action-completer-80 [] { ["DisableLogging"] }
def action-completer-81 [] { ["DisableSnapshotCopy"] }
def action-completer-82 [] { ["DisassociateDataShareConsumer"] }
def log-destination-type-completer [] { ["cloudwatch" "s3"] }
def action-completer-83 [] { ["EnableLogging"] }
def action-completer-84 [] { ["EnableSnapshotCopy"] }
def action-completer-85 [] { ["GetClusterCredentials"] }
def action-completer-86 [] { ["GetClusterCredentialsWithIAM"] }
def action-type-completer-1 [] { ["resize-cluster" "restore-cluster"] }
def action-completer-87 [] { ["GetReservedNodeExchangeConfigurationOptions"] }
def action-completer-88 [] { ["GetReservedNodeExchangeOfferings"] }
def action-completer-89 [] { ["ModifyAquaConfiguration"] }
def action-completer-90 [] { ["ModifyAuthenticationProfile"] }
def action-completer-91 [] { ["ModifyCluster"] }
def action-completer-92 [] { ["ModifyClusterDbRevision"] }
def action-completer-93 [] { ["ModifyClusterIamRoles"] }
def action-completer-94 [] { ["ModifyClusterMaintenance"] }
def action-completer-95 [] { ["ModifyClusterParameterGroup"] }
def action-completer-96 [] { ["ModifyClusterSnapshot"] }
def action-completer-97 [] { ["ModifyClusterSnapshotSchedule"] }
def action-completer-98 [] { ["ModifyClusterSubnetGroup"] }
def action-completer-99 [] { ["ModifyEndpointAccess"] }
def action-completer-100 [] { ["ModifyEventSubscription"] }
def action-completer-101 [] { ["ModifyScheduledAction"] }
def action-completer-102 [] { ["ModifySnapshotCopyRetentionPeriod"] }
def action-completer-103 [] { ["ModifySnapshotSchedule"] }
def action-completer-104 [] { ["ModifyUsageLimit"] }
def action-completer-105 [] { ["PauseCluster"] }
def action-completer-106 [] { ["PurchaseReservedNodeOffering"] }
def action-completer-107 [] { ["RebootCluster"] }
def action-completer-108 [] { ["RejectDataShare"] }
def action-completer-109 [] { ["ResetClusterParameterGroup"] }
def action-completer-110 [] { ["ResizeCluster"] }
def action-completer-111 [] { ["RestoreFromClusterSnapshot"] }
def action-completer-112 [] { ["RestoreTableFromClusterSnapshot"] }
def action-completer-113 [] { ["ResumeCluster"] }
def action-completer-114 [] { ["RevokeClusterSecurityGroupIngress"] }
def action-completer-115 [] { ["RevokeEndpointAccess"] }
def action-completer-116 [] { ["RevokeSnapshotAccess"] }
def action-completer-117 [] { ["RotateEncryptionKey"] }
def status-completer-2 [] { ["Active" "ConnectionFailure" "Inactive" "RuntimeFailure"] }
def action-completer-118 [] { ["UpdatePartnerStatus"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api get-accept-reserved-node-exchange" } } | get name | first)
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

# Exchanges a DC1 Reserved Node for a DC2 Reserved Node with no changes to the configuration (term, payment type, or number of nodes) and no additional costs.
#
# GET /
# operationId: GET_AcceptReservedNodeExchange
export def "api get-accept-reserved-node-exchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reserved-node-id: string # A string representing the node identifier of the DC1 Reserved Node to be exchanged.
  --target-reserved-node-offering-id: string # The unique identifier of the DC2 Reserved Node offering to be used for the exchange. You can obtain the value for the parameter by calling GetReservedNodeExchangeOfferings
  --action: string@action-completer
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ExchangedReservedNode: record<ReservedNodeId: record, ReservedNodeOfferingId: record, NodeType: record, StartTime: record, Duration: record, FixedPrice: record, UsagePrice: record, CurrencyCode: record, NodeCount: record, State: record, OfferingType: record, RecurringCharges: record, ReservedNodeOfferingType: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ReservedNodeId" $reserved_node_id "scalar") (serialize-qp "TargetReservedNodeOfferingId" $target_reserved_node_offering_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ReservedNodeId": $reserved_node_id, "TargetReservedNodeOfferingId": $target_reserved_node_offering_id, "Action": $action, "Version": $version} | compact), body: null}
}

# Exchanges a DC1 Reserved Node for a DC2 Reserved Node with no changes to the configuration (term, payment type, or number of nodes) and no additional costs.
#
# POST /
# operationId: POST_AcceptReservedNodeExchange
export def "api create-accept-reserved-node-exchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ExchangedReservedNode: record<ReservedNodeId: record, ReservedNodeOfferingId: record, NodeType: record, StartTime: record, Duration: record, FixedPrice: record, UsagePrice: record, CurrencyCode: record, NodeCount: record, State: record, OfferingType: record, RecurringCharges: record, ReservedNodeOfferingType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Adds a partner integration to a cluster. This operation authorizes a partner to push status updates for the specified database. To complete the integration, you also set up the integration on the partner website.
#
# GET /
# operationId: GET_AddPartner
export def "api get-create-partner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The Amazon Web Services account ID that owns the cluster.
  --cluster-identifier: string # The cluster identifier of the cluster that receives data from the partner.
  --database-name: string # The name of the database that receives data from the partner.
  --partner-name: string # The name of the partner that is authorized to send data.
  --action: string@action-completer-1
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DatabaseName: record, PartnerName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AccountId" $account_id "scalar") (serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "DatabaseName" $database_name "scalar") (serialize-qp "PartnerName" $partner_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AccountId": $account_id, "ClusterIdentifier": $cluster_identifier, "DatabaseName": $database_name, "PartnerName": $partner_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Adds a partner integration to a cluster. This operation authorizes a partner to push status updates for the specified database. To complete the integration, you also set up the integration on the partner website.
#
# POST /
# operationId: POST_AddPartner
export def "api create-partner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DatabaseName: record, PartnerName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# From a datashare consumer account, associates a datashare with the account (AssociateEntireAccount) or the specified namespace (ConsumerArn). If you make this association, the consumer can consume the datashare.
#
# GET /
# operationId: GET_AssociateDataShareConsumer
export def "api get-associate-data-share-consumer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-share-arn: string # The Amazon Resource Name (ARN) of the datashare that the consumer is to use with the account or the namespace.
  --associate-entire-account: oneof<nothing, bool> # A value that specifies whether the datashare is associated with the entire account.
  --consumer-arn: string # The Amazon Resource Name (ARN) of the consumer that is associated with the datashare.
  --consumer-region: string # From a datashare consumer account, associates a datashare with all existing and future namespaces in the specified Amazon Web Services Region.
  --action: string@action-completer-2
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DataShareArn: record, ProducerArn: record, AllowPubliclyAccessibleConsumers: record, DataShareAssociations: record, ManagedBy: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DataShareArn" $data_share_arn "scalar") (serialize-qp "AssociateEntireAccount" $associate_entire_account "scalar") (serialize-qp "ConsumerArn" $consumer_arn "scalar") (serialize-qp "ConsumerRegion" $consumer_region "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"DataShareArn": $data_share_arn, "AssociateEntireAccount": $associate_entire_account, "ConsumerArn": $consumer_arn, "ConsumerRegion": $consumer_region, "Action": $action, "Version": $version} | compact), body: null}
}

# From a datashare consumer account, associates a datashare with the account (AssociateEntireAccount) or the specified namespace (ConsumerArn). If you make this association, the consumer can consume the datashare.
#
# POST /
# operationId: POST_AssociateDataShareConsumer
export def "api create-associate-data-share-consumer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-2
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DataShareArn: record, ProducerArn: record, AllowPubliclyAccessibleConsumers: record, DataShareAssociations: record, ManagedBy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Adds an inbound (ingress) rule to an Amazon Redshift security group. Depending on whether the application accessing your cluster is running on the Internet or an Amazon EC2 instance, you can authorize inbound access to either a Classless Interdomain Routing (CIDR)/Internet Protocol (IP) range or to an Amazon EC2 security group. You can add as many as 20 ingress rules to an Amazon Redshift security group. If you authorize access to an Amazon EC2 security group, specify EC2SecurityGroupName and EC2SecurityGroupOwnerId. The Amazon EC2 security group and Amazon Redshift cluster must be in the same Amazon Web Services Region. If you authorize access to a CIDR/IP address range, specify CIDRIP. For an overview of CIDR blocks, see the Wikipedia article on Classless Inter-Domain Routing (http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing). You must also associate the security group with a cluster so that clients running on these IP addresses or the EC2 instance are authorized to connect to the cluster. For information about managing security groups, go to Working with Security Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-security-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_AuthorizeClusterSecurityGroupIngress
export def "api get-authorize-security-group-ingress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-security-group-name: string # The name of the security group to which the ingress rule is added.
  --cidrip: string # The IP range to be added the Amazon Redshift security group.
  --ec2-security-group-name: string # The EC2 security group to be added the Amazon Redshift security group.
  --ec2-security-group-owner-id: string # The Amazon Web Services account number of the owner of the security group specified by the EC2SecurityGroupName parameter. The Amazon Web Services Access Key ID is not an acceptable value. Example: 111122223333
  --action: string@action-completer-3
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ClusterSecurityGroup: record<ClusterSecurityGroupName: record, Description: record, EC2SecurityGroups: record, IPRanges: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterSecurityGroupName" $cluster_security_group_name "scalar") (serialize-qp "CIDRIP" $cidrip "scalar") (serialize-qp "EC2SecurityGroupName" $ec2_security_group_name "scalar") (serialize-qp "EC2SecurityGroupOwnerId" $ec2_security_group_owner_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterSecurityGroupName": $cluster_security_group_name, "CIDRIP": $cidrip, "EC2SecurityGroupName": $ec2_security_group_name, "EC2SecurityGroupOwnerId": $ec2_security_group_owner_id, "Action": $action, "Version": $version} | compact), body: null}
}

# Adds an inbound (ingress) rule to an Amazon Redshift security group. Depending on whether the application accessing your cluster is running on the Internet or an Amazon EC2 instance, you can authorize inbound access to either a Classless Interdomain Routing (CIDR)/Internet Protocol (IP) range or to an Amazon EC2 security group. You can add as many as 20 ingress rules to an Amazon Redshift security group. If you authorize access to an Amazon EC2 security group, specify EC2SecurityGroupName and EC2SecurityGroupOwnerId. The Amazon EC2 security group and Amazon Redshift cluster must be in the same Amazon Web Services Region. If you authorize access to a CIDR/IP address range, specify CIDRIP. For an overview of CIDR blocks, see the Wikipedia article on Classless Inter-Domain Routing (http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing). You must also associate the security group with a cluster so that clients running on these IP addresses or the EC2 instance are authorized to connect to the cluster. For information about managing security groups, go to Working with Security Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-security-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_AuthorizeClusterSecurityGroupIngress
export def "api create-authorize-security-group-ingress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-3
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ClusterSecurityGroup: record<ClusterSecurityGroupName: record, Description: record, EC2SecurityGroups: record, IPRanges: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# From a data producer account, authorizes the sharing of a datashare with one or more consumer accounts or managing entities. To authorize a datashare for a data consumer, the producer account must have the correct access permissions.
#
# GET /
# operationId: GET_AuthorizeDataShare
export def "api get-authorize-data-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-share-arn: string # The Amazon Resource Name (ARN) of the datashare that producers are to authorize sharing for.
  --consumer-identifier: string # The identifier of the data consumer that is authorized to access the datashare. This identifier is an Amazon Web Services account ID or a keyword, such as ADX.
  --action: string@action-completer-4
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DataShareArn: record, ProducerArn: record, AllowPubliclyAccessibleConsumers: record, DataShareAssociations: record, ManagedBy: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DataShareArn" $data_share_arn "scalar") (serialize-qp "ConsumerIdentifier" $consumer_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"DataShareArn": $data_share_arn, "ConsumerIdentifier": $consumer_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# From a data producer account, authorizes the sharing of a datashare with one or more consumer accounts or managing entities. To authorize a datashare for a data consumer, the producer account must have the correct access permissions.
#
# POST /
# operationId: POST_AuthorizeDataShare
export def "api create-authorize-data-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-4
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DataShareArn: record, ProducerArn: record, AllowPubliclyAccessibleConsumers: record, DataShareAssociations: record, ManagedBy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Grants access to a cluster.
#
# GET /
# operationId: GET_AuthorizeEndpointAccess
export def "api get-authorize-endpoint-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The cluster identifier of the cluster to grant access to.
  --account: string # The Amazon Web Services account ID to grant access to.
  --vpc-ids: list # The virtual private cloud (VPC) identifiers to grant access to.
  --action: string@action-completer-5
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Grantor: record, Grantee: record, ClusterIdentifier: record, AuthorizeTime: record, ClusterStatus: record, Status: record, AllowedAllVPCs: record, AllowedVPCs: record, EndpointCount: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "Account" $account "scalar") (serialize-qp "VpcIds" $vpc_ids "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "Account": $account, "VpcIds": $vpc_ids, "Action": $action, "Version": $version} | compact), body: null}
}

# Grants access to a cluster.
#
# POST /
# operationId: POST_AuthorizeEndpointAccess
export def "api create-authorize-endpoint-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-5
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Grantor: record, Grantee: record, ClusterIdentifier: record, AuthorizeTime: record, ClusterStatus: record, Status: record, AllowedAllVPCs: record, AllowedVPCs: record, EndpointCount: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Authorizes the specified Amazon Web Services account to restore the specified snapshot. For more information about working with snapshots, go to Amazon Redshift Snapshots (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-snapshots.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_AuthorizeSnapshotAccess
export def "api get-authorize-snapshot-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-identifier: string # The identifier of the snapshot the account is authorized to restore.
  --snapshot-arn: string # The Amazon Resource Name (ARN) of the snapshot to authorize access to.
  --snapshot-cluster-identifier: string # The identifier of the cluster the snapshot was created from. This parameter is required if your IAM user or role has a policy containing a snapshot resource element that specifies anything other than * for the cluster name.
  --account-with-restore-access: string # The identifier of the Amazon Web Services account authorized to restore the specified snapshot. To share a snapshot with Amazon Web Services Support, specify amazon-redshift-support.
  --action: string@action-completer-6
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Snapshot: record<SnapshotIdentifier: record, ClusterIdentifier: record, SnapshotCreateTime: record, Status: record, Port: record, AvailabilityZone: record, ClusterCreateTime: record, MasterUsername: record, ClusterVersion: record, EngineFullVersion: record, SnapshotType: record, NodeType: record, NumberOfNodes: record, DBName: record, VpcId: record, Encrypted: record, KmsKeyId: record, EncryptedWithHSM: record, AccountsWithRestoreAccess: record, OwnerAccount: record, TotalBackupSizeInMegaBytes: record, ActualIncrementalBackupSizeInMegaBytes: record, BackupProgressInMegaBytes: record, CurrentBackupRateInMegaBytesPerSecond: record, EstimatedSecondsToCompletion: record, ElapsedTimeInSeconds: record, SourceRegion: record, Tags: record, RestorableNodeTypes: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, ManualSnapshotRetentionPeriod: record, ManualSnapshotRemainingDays: record, SnapshotRetentionStartTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SnapshotIdentifier" $snapshot_identifier "scalar") (serialize-qp "SnapshotArn" $snapshot_arn "scalar") (serialize-qp "SnapshotClusterIdentifier" $snapshot_cluster_identifier "scalar") (serialize-qp "AccountWithRestoreAccess" $account_with_restore_access "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SnapshotIdentifier": $snapshot_identifier, "SnapshotArn": $snapshot_arn, "SnapshotClusterIdentifier": $snapshot_cluster_identifier, "AccountWithRestoreAccess": $account_with_restore_access, "Action": $action, "Version": $version} | compact), body: null}
}

# Authorizes the specified Amazon Web Services account to restore the specified snapshot. For more information about working with snapshots, go to Amazon Redshift Snapshots (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-snapshots.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_AuthorizeSnapshotAccess
export def "api create-authorize-snapshot-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-6
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Snapshot: record<SnapshotIdentifier: record, ClusterIdentifier: record, SnapshotCreateTime: record, Status: record, Port: record, AvailabilityZone: record, ClusterCreateTime: record, MasterUsername: record, ClusterVersion: record, EngineFullVersion: record, SnapshotType: record, NodeType: record, NumberOfNodes: record, DBName: record, VpcId: record, Encrypted: record, KmsKeyId: record, EncryptedWithHSM: record, AccountsWithRestoreAccess: record, OwnerAccount: record, TotalBackupSizeInMegaBytes: record, ActualIncrementalBackupSizeInMegaBytes: record, BackupProgressInMegaBytes: record, CurrentBackupRateInMegaBytesPerSecond: record, EstimatedSecondsToCompletion: record, ElapsedTimeInSeconds: record, SourceRegion: record, Tags: record, RestorableNodeTypes: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, ManualSnapshotRetentionPeriod: record, ManualSnapshotRemainingDays: record, SnapshotRetentionStartTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes a set of cluster snapshots.
#
# GET /
# operationId: GET_BatchDeleteClusterSnapshots
export def "api get-batch-delete-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identifiers: list # A list of identifiers for the snapshots that you want to delete.
  --action: string@action-completer-7
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Resources: record, Errors: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Identifiers" $identifiers "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Identifiers": $identifiers, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes a set of cluster snapshots.
#
# POST /
# operationId: POST_BatchDeleteClusterSnapshots
export def "api create-batch-delete-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-7
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Resources: record, Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies the settings for a set of cluster snapshots.
#
# GET /
# operationId: GET_BatchModifyClusterSnapshots
export def "api get-batch-modify-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-identifier-list: list # A list of snapshot identifiers you want to modify.
  --manual-snapshot-retention-period: int # The number of days that a manual snapshot is retained. If you specify the value -1, the manual snapshot is retained indefinitely. The number must be either -1 or an integer between 1 and 3,653. If you decrease the manual snapshot retention period from its current value, existing manual snapshots that fall outside of the new retention period will return an error. If you want to suppress the errors and delete the snapshots, use the force option.
  --force: oneof<nothing, bool> # A boolean value indicating whether to override an exception if the retention period has passed.
  --action: string@action-completer-8
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Resources: record, Errors: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SnapshotIdentifierList" $snapshot_identifier_list "multi") (serialize-qp "ManualSnapshotRetentionPeriod" $manual_snapshot_retention_period "scalar") (serialize-qp "Force" $force "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SnapshotIdentifierList": $snapshot_identifier_list, "ManualSnapshotRetentionPeriod": $manual_snapshot_retention_period, "Force": $force, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies the settings for a set of cluster snapshots.
#
# POST /
# operationId: POST_BatchModifyClusterSnapshots
export def "api create-batch-modify-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-8
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Resources: record, Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Cancels a resize operation for a cluster.
#
# GET /
# operationId: GET_CancelResize
export def "api get-cancel-resize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The unique identifier for the cluster that you want to cancel a resize operation for.
  --action: string@action-completer-9
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TargetNodeType: record, TargetNumberOfNodes: record, TargetClusterType: record, Status: record, ImportTablesCompleted: record, ImportTablesInProgress: record, ImportTablesNotStarted: record, AvgResizeRateInMegaBytesPerSecond: record, TotalResizeDataInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record, ResizeType: record, Message: record, TargetEncryptionType: record, DataTransferProgressPercent: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Cancels a resize operation for a cluster.
#
# POST /
# operationId: POST_CancelResize
export def "api create-cancel-resize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-9
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<TargetNodeType: record, TargetNumberOfNodes: record, TargetClusterType: record, Status: record, ImportTablesCompleted: record, ImportTablesInProgress: record, ImportTablesNotStarted: record, AvgResizeRateInMegaBytesPerSecond: record, TotalResizeDataInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record, ResizeType: record, Message: record, TargetEncryptionType: record, DataTransferProgressPercent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Copies the specified automated cluster snapshot to a new manual cluster snapshot. The source must be an automated snapshot and it must be in the available state. When you delete a cluster, Amazon Redshift deletes any automated snapshots of the cluster. Also, when the retention period of the snapshot expires, Amazon Redshift automatically deletes it. If you want to keep an automated snapshot for a longer period, you can make a manual copy of the snapshot. Manual snapshots are retained until you delete them. For more information about working with snapshots, go to Amazon Redshift Snapshots (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-snapshots.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_CopyClusterSnapshot
export def "api get-copy-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-snapshot-identifier: string # The identifier for the source snapshot. Constraints: Must be the identifier for a valid automated snapshot whose state is available.
  --source-snapshot-cluster-identifier: string # The identifier of the cluster the source snapshot was created from. This parameter is required if your IAM user or role has a policy containing a snapshot resource element that specifies anything other than * for the cluster name. Constraints: Must be the identifier for a valid cluster.
  --target-snapshot-identifier: string # The identifier given to the new manual snapshot. Constraints: Cannot be null, empty, or blank. Must contain from 1 to 255 alphanumeric characters or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Must be unique for the Amazon Web Services account that is making the request.
  --manual-snapshot-retention-period: int # The number of days that a manual snapshot is retained. If the value is -1, the manual snapshot is retained indefinitely. The value must be either -1 or an integer between 1 and 3,653. The default value is -1.
  --action: string@action-completer-10
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Snapshot: record<SnapshotIdentifier: record, ClusterIdentifier: record, SnapshotCreateTime: record, Status: record, Port: record, AvailabilityZone: record, ClusterCreateTime: record, MasterUsername: record, ClusterVersion: record, EngineFullVersion: record, SnapshotType: record, NodeType: record, NumberOfNodes: record, DBName: record, VpcId: record, Encrypted: record, KmsKeyId: record, EncryptedWithHSM: record, AccountsWithRestoreAccess: record, OwnerAccount: record, TotalBackupSizeInMegaBytes: record, ActualIncrementalBackupSizeInMegaBytes: record, BackupProgressInMegaBytes: record, CurrentBackupRateInMegaBytesPerSecond: record, EstimatedSecondsToCompletion: record, ElapsedTimeInSeconds: record, SourceRegion: record, Tags: record, RestorableNodeTypes: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, ManualSnapshotRetentionPeriod: record, ManualSnapshotRemainingDays: record, SnapshotRetentionStartTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SourceSnapshotIdentifier" $source_snapshot_identifier "scalar") (serialize-qp "SourceSnapshotClusterIdentifier" $source_snapshot_cluster_identifier "scalar") (serialize-qp "TargetSnapshotIdentifier" $target_snapshot_identifier "scalar") (serialize-qp "ManualSnapshotRetentionPeriod" $manual_snapshot_retention_period "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SourceSnapshotIdentifier": $source_snapshot_identifier, "SourceSnapshotClusterIdentifier": $source_snapshot_cluster_identifier, "TargetSnapshotIdentifier": $target_snapshot_identifier, "ManualSnapshotRetentionPeriod": $manual_snapshot_retention_period, "Action": $action, "Version": $version} | compact), body: null}
}

# Copies the specified automated cluster snapshot to a new manual cluster snapshot. The source must be an automated snapshot and it must be in the available state. When you delete a cluster, Amazon Redshift deletes any automated snapshots of the cluster. Also, when the retention period of the snapshot expires, Amazon Redshift automatically deletes it. If you want to keep an automated snapshot for a longer period, you can make a manual copy of the snapshot. Manual snapshots are retained until you delete them. For more information about working with snapshots, go to Amazon Redshift Snapshots (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-snapshots.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_CopyClusterSnapshot
export def "api create-copy-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-10
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Snapshot: record<SnapshotIdentifier: record, ClusterIdentifier: record, SnapshotCreateTime: record, Status: record, Port: record, AvailabilityZone: record, ClusterCreateTime: record, MasterUsername: record, ClusterVersion: record, EngineFullVersion: record, SnapshotType: record, NodeType: record, NumberOfNodes: record, DBName: record, VpcId: record, Encrypted: record, KmsKeyId: record, EncryptedWithHSM: record, AccountsWithRestoreAccess: record, OwnerAccount: record, TotalBackupSizeInMegaBytes: record, ActualIncrementalBackupSizeInMegaBytes: record, BackupProgressInMegaBytes: record, CurrentBackupRateInMegaBytesPerSecond: record, EstimatedSecondsToCompletion: record, ElapsedTimeInSeconds: record, SourceRegion: record, Tags: record, RestorableNodeTypes: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, ManualSnapshotRetentionPeriod: record, ManualSnapshotRemainingDays: record, SnapshotRetentionStartTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates an authentication profile with the specified parameters.
#
# GET /
# operationId: GET_CreateAuthenticationProfile
export def "api get-create-authentication-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authentication-profile-name: string # The name of the authentication profile to be created.
  --authentication-profile-content: string # The content of the authentication profile in JSON format. The maximum length of the JSON string is determined by a quota for your account.
  --action: string@action-completer-11
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AuthenticationProfileName: record, AuthenticationProfileContent: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AuthenticationProfileName" $authentication_profile_name "scalar") (serialize-qp "AuthenticationProfileContent" $authentication_profile_content "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AuthenticationProfileName": $authentication_profile_name, "AuthenticationProfileContent": $authentication_profile_content, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates an authentication profile with the specified parameters.
#
# POST /
# operationId: POST_CreateAuthenticationProfile
export def "api create-authentication-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-11
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<AuthenticationProfileName: record, AuthenticationProfileContent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates a new cluster with the specified parameters. To create a cluster in Virtual Private Cloud (VPC), you must provide a cluster subnet group name. The cluster subnet group identifies the subnets of your VPC that Amazon Redshift uses when creating the cluster. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_CreateCluster
export def "api get-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-name: string # The name of the first database to be created when the cluster is created. To create additional databases after the cluster is created, connect to the cluster with a SQL client and use SQL commands to create a database. For more information, go to Create a Database (https://docs.aws.amazon.com/redshift/latest/dg/t_creating_database.html) in the Amazon Redshift Database Developer Guide. Default: dev Constraints: Must contain 1 to 64 alphanumeric characters. Must contain only lowercase letters. Cannot be a word that is reserved by the service. A list of reserved words can be found in Reserved Words (https://docs.aws.amazon.com/redshift/latest/dg/r_pg_keywords.html) in the Amazon Redshift Database Developer Guide.
  --cluster-identifier: string # A unique identifier for the cluster. You use this identifier to refer to the cluster for any subsequent cluster operations such as deleting or modifying. The identifier also appears in the Amazon Redshift console. Constraints: Must contain from 1 to 63 alphanumeric characters or hyphens. Alphabetic characters must be lowercase. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Must be unique for all clusters within an Amazon Web Services account. Example: myexamplecluster
  --cluster-type: string # The type of the cluster. When cluster type is specified as single-node, the NumberOfNodes parameter is not required. multi-node, the NumberOfNodes parameter is required. Valid Values: multi-node | single-node Default: multi-node
  --node-type: string # The node type to be provisioned for the cluster. For information about node types, go to Working with Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html#how-many-nodes) in the Amazon Redshift Cluster Management Guide. Valid Values: ds2.xlarge | ds2.8xlarge | dc1.large | dc1.8xlarge | dc2.large | dc2.8xlarge | ra3.xlplus | ra3.4xlarge | ra3.16xlarge
  --master-username: string # The user name associated with the admin user for the cluster that is being created. Constraints: Must be 1 - 128 alphanumeric characters or hyphens. The user name can't be PUBLIC. Must contain only lowercase letters, numbers, underscore, plus sign, period (dot), at symbol (@), or hyphen. The first character must be a letter. Must not contain a colon (:) or a slash (/). Cannot be a reserved word. A list of reserved words can be found in Reserved Words (https://docs.aws.amazon.com/redshift/latest/dg/r_pg_keywords.html) in the Amazon Redshift Database Developer Guide.
  --master-user-password: string # The password associated with the admin user for the cluster that is being created. Constraints: Must be between 8 and 64 characters in length. Must contain at least one uppercase letter. Must contain at least one lowercase letter. Must contain one number. Can be any printable ASCII character (ASCII code 33-126) except ' (single quote), " (double quote), \, /, or @.
  --cluster-security-groups: list # A list of security groups to be associated with this cluster. Default: The default cluster security group for Amazon Redshift.
  --vpc-security-group-ids: list # A list of Virtual Private Cloud (VPC) security groups to be associated with the cluster. Default: The default VPC security group is associated with the cluster.
  --cluster-subnet-group-name: string # The name of a cluster subnet group to be associated with this cluster. If this parameter is not provided the resulting cluster will be deployed outside virtual private cloud (VPC).
  --availability-zone: string # The EC2 Availability Zone (AZ) in which you want Amazon Redshift to provision the cluster. For example, if you have several EC2 instances running in a specific Availability Zone, then you might want the cluster to be provisioned in the same zone in order to decrease network latency. Default: A random, system-chosen Availability Zone in the region that is specified by the endpoint. Example: us-east-2d Constraint: The specified Availability Zone must be in the same region as the current endpoint.
  --preferred-maintenance-window: string # The weekly time range (in UTC) during which automated cluster maintenance can occur. Format: ddd:hh24:mi-ddd:hh24:mi Default: A 30-minute window selected at random from an 8-hour block of time per region, occurring on a random day of the week. For more information about the time blocks for each region, see Maintenance Windows (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html#rs-maintenance-windows) in Amazon Redshift Cluster Management Guide. Valid Days: Mon | Tue | Wed | Thu | Fri | Sat | Sun Constraints: Minimum 30-minute window.
  --cluster-parameter-group-name: string # The name of the parameter group to be associated with this cluster. Default: The default Amazon Redshift cluster parameter group. For information about the default parameter group, go to Working with Amazon Redshift Parameter Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-parameter-groups.html) Constraints: Must be 1 to 255 alphanumeric characters or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens.
  --automated-snapshot-retention-period: int # The number of days that automated snapshots are retained. If the value is 0, automated snapshots are disabled. Even if automated snapshots are disabled, you can still create manual snapshots when you want with CreateClusterSnapshot. You can't disable automated snapshots for RA3 node types. Set the automated retention period from 1-35 days. Default: 1 Constraints: Must be a value from 0 to 35.
  --manual-snapshot-retention-period: int # The default number of days to retain a manual snapshot. If the value is -1, the snapshot is retained indefinitely. This setting doesn't change the retention period of existing snapshots. The value must be either -1 or an integer between 1 and 3,653.
  --port: int # The port number on which the cluster accepts incoming connections. The cluster is accessible only via the JDBC and ODBC connection strings. Part of the connection string requires the port on which the cluster will listen for incoming connections. Default: 5439 Valid Values: 1150-65535
  --cluster-version: string # The version of the Amazon Redshift engine software that you want to deploy on the cluster. The version selected runs on all the nodes in the cluster. Constraints: Only version 1.0 is currently available. Example: 1.0
  --allow-version-upgrade: oneof<nothing, bool> # If true, major version upgrades can be applied during the maintenance window to the Amazon Redshift engine that is running on the cluster. When a new major version of the Amazon Redshift engine is released, you can request that the service automatically apply upgrades during the maintenance window to the Amazon Redshift engine that is running on your cluster. Default: true
  --number-of-nodes: int # The number of compute nodes in the cluster. This parameter is required when the ClusterType parameter is specified as multi-node. For information about determining how many nodes you need, go to Working with Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html#how-many-nodes) in the Amazon Redshift Cluster Management Guide. If you don't specify this parameter, you get a single-node cluster. When requesting a multi-node cluster, you must specify the number of nodes that you want in the cluster. Default: 1 Constraints: Value must be at least 1 and no more than 100.
  --publicly-accessible: oneof<nothing, bool> # If true, the cluster can be accessed from a public network.
  --encrypted: oneof<nothing, bool> # If true, the data in the cluster is encrypted at rest. Default: false
  --hsm-client-certificate-identifier: string # Specifies the name of the HSM client certificate the Amazon Redshift cluster uses to retrieve the data encryption keys stored in an HSM.
  --hsm-configuration-identifier: string # Specifies the name of the HSM configuration that contains the information the Amazon Redshift cluster can use to retrieve and store keys in an HSM.
  --elastic-ip: string # The Elastic IP (EIP) address for the cluster. Constraints: The cluster must be provisioned in EC2-VPC and publicly-accessible through an Internet gateway. Don't specify the Elastic IP address for a publicly accessible cluster with availability zone relocation turned on. For more information about provisioning clusters in EC2-VPC, go to Supported Platforms to Launch Your Cluster (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html#cluster-platforms) in the Amazon Redshift Cluster Management Guide.
  --tags: list # A list of tag instances.
  --kms-key-id: string # The Key Management Service (KMS) key ID of the encryption key that you want to use to encrypt data in the cluster.
  --enhanced-vpc-routing: oneof<nothing, bool> # An option that specifies whether to create the cluster with enhanced VPC routing enabled. To create a cluster that uses enhanced VPC routing, the cluster must be in a VPC. For more information, see Enhanced VPC Routing (https://docs.aws.amazon.com/redshift/latest/mgmt/enhanced-vpc-routing.html) in the Amazon Redshift Cluster Management Guide. If this option is true, enhanced VPC routing is enabled. Default: false
  --additional-info: string # Reserved.
  --iam-roles: list # A list of Identity and Access Management (IAM) roles that can be used by the cluster to access other Amazon Web Services services. You must supply the IAM roles in their Amazon Resource Name (ARN) format. The maximum number of IAM roles that you can associate is subject to a quota. For more information, go to Quotas and limits (https://docs.aws.amazon.com/redshift/latest/mgmt/amazon-redshift-limits.html) in the Amazon Redshift Cluster Management Guide.
  --maintenance-track-name: string # An optional parameter for the name of the maintenance track for the cluster. If you don't provide a maintenance track name, the cluster is assigned to the current track.
  --snapshot-schedule-identifier: string # A unique identifier for the snapshot schedule.
  --availability-zone-relocation: oneof<nothing, bool> # The option to enable relocation for an Amazon Redshift cluster between Availability Zones after the cluster is created.
  --aqua-configuration-status: string@aqua-configuration-status-completer # This parameter is retired. It does not set the AQUA configuration status. Amazon Redshift automatically determines whether to use AQUA (Advanced Query Accelerator).
  --default-iam-role-arn: string # The Amazon Resource Name (ARN) for the IAM role that was set as default for the cluster when the cluster was created.
  --load-sample-data: string # A flag that specifies whether to load sample data once the cluster is created.
  --action: string@action-completer-12
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DBName" $db_name "scalar") (serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "ClusterType" $cluster_type "scalar") (serialize-qp "NodeType" $node_type "scalar") (serialize-qp "MasterUsername" $master_username "scalar") (serialize-qp "MasterUserPassword" $master_user_password "scalar") (serialize-qp "ClusterSecurityGroups" $cluster_security_groups "multi") (serialize-qp "VpcSecurityGroupIds" $vpc_security_group_ids "multi") (serialize-qp "ClusterSubnetGroupName" $cluster_subnet_group_name "scalar") (serialize-qp "AvailabilityZone" $availability_zone "scalar") (serialize-qp "PreferredMaintenanceWindow" $preferred_maintenance_window "scalar") (serialize-qp "ClusterParameterGroupName" $cluster_parameter_group_name "scalar") (serialize-qp "AutomatedSnapshotRetentionPeriod" $automated_snapshot_retention_period "scalar") (serialize-qp "ManualSnapshotRetentionPeriod" $manual_snapshot_retention_period "scalar") (serialize-qp "Port" $port "scalar") (serialize-qp "ClusterVersion" $cluster_version "scalar") (serialize-qp "AllowVersionUpgrade" $allow_version_upgrade "scalar") (serialize-qp "NumberOfNodes" $number_of_nodes "scalar") (serialize-qp "PubliclyAccessible" $publicly_accessible "scalar") (serialize-qp "Encrypted" $encrypted "scalar") (serialize-qp "HsmClientCertificateIdentifier" $hsm_client_certificate_identifier "scalar") (serialize-qp "HsmConfigurationIdentifier" $hsm_configuration_identifier "scalar") (serialize-qp "ElasticIp" $elastic_ip "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "KmsKeyId" $kms_key_id "scalar") (serialize-qp "EnhancedVpcRouting" $enhanced_vpc_routing "scalar") (serialize-qp "AdditionalInfo" $additional_info "scalar") (serialize-qp "IamRoles" $iam_roles "multi") (serialize-qp "MaintenanceTrackName" $maintenance_track_name "scalar") (serialize-qp "SnapshotScheduleIdentifier" $snapshot_schedule_identifier "scalar") (serialize-qp "AvailabilityZoneRelocation" $availability_zone_relocation "scalar") (serialize-qp "AquaConfigurationStatus" $aqua_configuration_status "scalar") (serialize-qp "DefaultIamRoleArn" $default_iam_role_arn "scalar") (serialize-qp "LoadSampleData" $load_sample_data "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"DBName": $db_name, "ClusterIdentifier": $cluster_identifier, "ClusterType": $cluster_type, "NodeType": $node_type, "MasterUsername": $master_username, "MasterUserPassword": $master_user_password, "ClusterSecurityGroups": $cluster_security_groups, "VpcSecurityGroupIds": $vpc_security_group_ids, "ClusterSubnetGroupName": $cluster_subnet_group_name, "AvailabilityZone": $availability_zone, "PreferredMaintenanceWindow": $preferred_maintenance_window, "ClusterParameterGroupName": $cluster_parameter_group_name, "AutomatedSnapshotRetentionPeriod": $automated_snapshot_retention_period, "ManualSnapshotRetentionPeriod": $manual_snapshot_retention_period, "Port": $port, "ClusterVersion": $cluster_version, "AllowVersionUpgrade": $allow_version_upgrade, "NumberOfNodes": $number_of_nodes, "PubliclyAccessible": $publicly_accessible, "Encrypted": $encrypted, "HsmClientCertificateIdentifier": $hsm_client_certificate_identifier, "HsmConfigurationIdentifier": $hsm_configuration_identifier, "ElasticIp": $elastic_ip, "Tags": $tags, "KmsKeyId": $kms_key_id, "EnhancedVpcRouting": $enhanced_vpc_routing, "AdditionalInfo": $additional_info, "IamRoles": $iam_roles, "MaintenanceTrackName": $maintenance_track_name, "SnapshotScheduleIdentifier": $snapshot_schedule_identifier, "AvailabilityZoneRelocation": $availability_zone_relocation, "AquaConfigurationStatus": $aqua_configuration_status, "DefaultIamRoleArn": $default_iam_role_arn, "LoadSampleData": $load_sample_data, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates a new cluster with the specified parameters. To create a cluster in Virtual Private Cloud (VPC), you must provide a cluster subnet group name. The cluster subnet group identifies the subnets of your VPC that Amazon Redshift uses when creating the cluster. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_CreateCluster
export def "api create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-12
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates an Amazon Redshift parameter group. Creating parameter groups is independent of creating clusters. You can associate a cluster with a parameter group when you create the cluster. You can also associate an existing cluster with a parameter group after the cluster is created by using ModifyCluster. Parameters in the parameter group define specific behavior that applies to the databases you create on the cluster. For more information about parameters and parameter groups, go to Amazon Redshift Parameter Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-parameter-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_CreateClusterParameterGroup
export def "api get-create-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameter-group-name: string # The name of the cluster parameter group. Constraints: Must be 1 to 255 alphanumeric characters or hyphens First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Must be unique withing your Amazon Web Services account. This value is stored as a lower-case string.
  --parameter-group-family: string # The Amazon Redshift engine version to which the cluster parameter group applies. The cluster engine version determines the set of parameters. To get a list of valid parameter group family names, you can call DescribeClusterParameterGroups. By default, Amazon Redshift returns a list of all the parameter groups that are owned by your Amazon Web Services account, including the default parameter groups for each Amazon Redshift engine version. The parameter group family names associated with the default parameter groups provide you the valid values. For example, a valid family name is "redshift-1.0".
  --description: string # A description of the parameter group.
  --tags: list # A list of tag instances.
  --action: string@action-completer-13
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ClusterParameterGroup: record<ParameterGroupName: record, ParameterGroupFamily: record, Description: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ParameterGroupName" $parameter_group_name "scalar") (serialize-qp "ParameterGroupFamily" $parameter_group_family "scalar") (serialize-qp "Description" $description "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ParameterGroupName": $parameter_group_name, "ParameterGroupFamily": $parameter_group_family, "Description": $description, "Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates an Amazon Redshift parameter group. Creating parameter groups is independent of creating clusters. You can associate a cluster with a parameter group when you create the cluster. You can also associate an existing cluster with a parameter group after the cluster is created by using ModifyCluster. Parameters in the parameter group define specific behavior that applies to the databases you create on the cluster. For more information about parameters and parameter groups, go to Amazon Redshift Parameter Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-parameter-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_CreateClusterParameterGroup
export def "api create-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-13
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ClusterParameterGroup: record<ParameterGroupName: record, ParameterGroupFamily: record, Description: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates a new Amazon Redshift security group. You use security groups to control access to non-VPC clusters. For information about managing security groups, go to Amazon Redshift Cluster Security Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-security-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_CreateClusterSecurityGroup
export def "api get-create-security-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-security-group-name: string # The name for the security group. Amazon Redshift stores the value as a lowercase string. Constraints: Must contain no more than 255 alphanumeric characters or hyphens. Must not be "Default". Must be unique for all security groups that are created by your Amazon Web Services account. Example: examplesecuritygroup
  --description: string # A description for the security group.
  --tags: list # A list of tag instances.
  --action: string@action-completer-14
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ClusterSecurityGroup: record<ClusterSecurityGroupName: record, Description: record, EC2SecurityGroups: record, IPRanges: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterSecurityGroupName" $cluster_security_group_name "scalar") (serialize-qp "Description" $description "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterSecurityGroupName": $cluster_security_group_name, "Description": $description, "Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates a new Amazon Redshift security group. You use security groups to control access to non-VPC clusters. For information about managing security groups, go to Amazon Redshift Cluster Security Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-security-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_CreateClusterSecurityGroup
export def "api create-security-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-14
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ClusterSecurityGroup: record<ClusterSecurityGroupName: record, Description: record, EC2SecurityGroups: record, IPRanges: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates a manual snapshot of the specified cluster. The cluster must be in the available state. For more information about working with snapshots, go to Amazon Redshift Snapshots (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-snapshots.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_CreateClusterSnapshot
export def "api get-create-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-identifier: string # A unique identifier for the snapshot that you are requesting. This identifier must be unique for all snapshots within the Amazon Web Services account. Constraints: Cannot be null, empty, or blank Must contain from 1 to 255 alphanumeric characters or hyphens First character must be a letter Cannot end with a hyphen or contain two consecutive hyphens Example: my-snapshot-id
  --cluster-identifier: string # The cluster identifier for which you want a snapshot.
  --manual-snapshot-retention-period: int # The number of days that a manual snapshot is retained. If the value is -1, the manual snapshot is retained indefinitely. The value must be either -1 or an integer between 1 and 3,653. The default value is -1.
  --tags: list # A list of tag instances.
  --action: string@action-completer-15
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Snapshot: record<SnapshotIdentifier: record, ClusterIdentifier: record, SnapshotCreateTime: record, Status: record, Port: record, AvailabilityZone: record, ClusterCreateTime: record, MasterUsername: record, ClusterVersion: record, EngineFullVersion: record, SnapshotType: record, NodeType: record, NumberOfNodes: record, DBName: record, VpcId: record, Encrypted: record, KmsKeyId: record, EncryptedWithHSM: record, AccountsWithRestoreAccess: record, OwnerAccount: record, TotalBackupSizeInMegaBytes: record, ActualIncrementalBackupSizeInMegaBytes: record, BackupProgressInMegaBytes: record, CurrentBackupRateInMegaBytesPerSecond: record, EstimatedSecondsToCompletion: record, ElapsedTimeInSeconds: record, SourceRegion: record, Tags: record, RestorableNodeTypes: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, ManualSnapshotRetentionPeriod: record, ManualSnapshotRemainingDays: record, SnapshotRetentionStartTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SnapshotIdentifier" $snapshot_identifier "scalar") (serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "ManualSnapshotRetentionPeriod" $manual_snapshot_retention_period "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SnapshotIdentifier": $snapshot_identifier, "ClusterIdentifier": $cluster_identifier, "ManualSnapshotRetentionPeriod": $manual_snapshot_retention_period, "Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates a manual snapshot of the specified cluster. The cluster must be in the available state. For more information about working with snapshots, go to Amazon Redshift Snapshots (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-snapshots.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_CreateClusterSnapshot
export def "api create-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-15
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Snapshot: record<SnapshotIdentifier: record, ClusterIdentifier: record, SnapshotCreateTime: record, Status: record, Port: record, AvailabilityZone: record, ClusterCreateTime: record, MasterUsername: record, ClusterVersion: record, EngineFullVersion: record, SnapshotType: record, NodeType: record, NumberOfNodes: record, DBName: record, VpcId: record, Encrypted: record, KmsKeyId: record, EncryptedWithHSM: record, AccountsWithRestoreAccess: record, OwnerAccount: record, TotalBackupSizeInMegaBytes: record, ActualIncrementalBackupSizeInMegaBytes: record, BackupProgressInMegaBytes: record, CurrentBackupRateInMegaBytesPerSecond: record, EstimatedSecondsToCompletion: record, ElapsedTimeInSeconds: record, SourceRegion: record, Tags: record, RestorableNodeTypes: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, ManualSnapshotRetentionPeriod: record, ManualSnapshotRemainingDays: record, SnapshotRetentionStartTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates a new Amazon Redshift subnet group. You must provide a list of one or more subnets in your existing Amazon Virtual Private Cloud (Amazon VPC) when creating Amazon Redshift subnet group. For information about subnet groups, go to Amazon Redshift Cluster Subnet Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-cluster-subnet-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_CreateClusterSubnetGroup
export def "api get-create-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-subnet-group-name: string # The name for the subnet group. Amazon Redshift stores the value as a lowercase string. Constraints: Must contain no more than 255 alphanumeric characters or hyphens. Must not be "Default". Must be unique for all subnet groups that are created by your Amazon Web Services account. Example: examplesubnetgroup
  --description: string # A description for the subnet group.
  --subnet-ids: list # An array of VPC subnet IDs. A maximum of 20 subnets can be modified in a single request.
  --tags: list # A list of tag instances.
  --action: string@action-completer-16
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ClusterSubnetGroup: record<ClusterSubnetGroupName: record, Description: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterSubnetGroupName" $cluster_subnet_group_name "scalar") (serialize-qp "Description" $description "scalar") (serialize-qp "SubnetIds" $subnet_ids "multi") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterSubnetGroupName": $cluster_subnet_group_name, "Description": $description, "SubnetIds": $subnet_ids, "Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates a new Amazon Redshift subnet group. You must provide a list of one or more subnets in your existing Amazon Virtual Private Cloud (Amazon VPC) when creating Amazon Redshift subnet group. For information about subnet groups, go to Amazon Redshift Cluster Subnet Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-cluster-subnet-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_CreateClusterSubnetGroup
export def "api create-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-16
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ClusterSubnetGroup: record<ClusterSubnetGroupName: record, Description: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates a Redshift-managed VPC endpoint.
#
# GET /
# operationId: GET_CreateEndpointAccess
export def "api get-create-endpoint-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The cluster identifier of the cluster to access.
  --resource-owner: string # The Amazon Web Services account ID of the owner of the cluster. This is only required if the cluster is in another Amazon Web Services account.
  --endpoint-name: string # The Redshift-managed VPC endpoint name. An endpoint name must contain 1-30 characters. Valid characters are A-Z, a-z, 0-9, and hyphen(-). The first character must be a letter. The name can't contain two consecutive hyphens or end with a hyphen.
  --subnet-group-name: string # The subnet group from which Amazon Redshift chooses the subnet to deploy the endpoint.
  --vpc-security-group-ids: list # The security group that defines the ports, protocols, and sources for inbound traffic that you are authorizing into your endpoint.
  --action: string@action-completer-17
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ClusterIdentifier: record, ResourceOwner: record, SubnetGroupName: record, EndpointStatus: record, EndpointName: record, EndpointCreateTime: record, Port: record, Address: record, VpcSecurityGroups: record, VpcEndpoint: record<VpcEndpointId: record, VpcId: record, NetworkInterfaces: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "ResourceOwner" $resource_owner "scalar") (serialize-qp "EndpointName" $endpoint_name "scalar") (serialize-qp "SubnetGroupName" $subnet_group_name "scalar") (serialize-qp "VpcSecurityGroupIds" $vpc_security_group_ids "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "ResourceOwner": $resource_owner, "EndpointName": $endpoint_name, "SubnetGroupName": $subnet_group_name, "VpcSecurityGroupIds": $vpc_security_group_ids, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates a Redshift-managed VPC endpoint.
#
# POST /
# operationId: POST_CreateEndpointAccess
export def "api create-endpoint-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-17
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ClusterIdentifier: record, ResourceOwner: record, SubnetGroupName: record, EndpointStatus: record, EndpointName: record, EndpointCreateTime: record, Port: record, Address: record, VpcSecurityGroups: record, VpcEndpoint: record<VpcEndpointId: record, VpcId: record, NetworkInterfaces: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates an Amazon Redshift event notification subscription. This action requires an ARN (Amazon Resource Name) of an Amazon SNS topic created by either the Amazon Redshift console, the Amazon SNS console, or the Amazon SNS API. To obtain an ARN with Amazon SNS, you must create a topic in Amazon SNS and subscribe to the topic. The ARN is displayed in the SNS console. You can specify the source type, and lists of Amazon Redshift source IDs, event categories, and event severities. Notifications will be sent for all events you want that match those criteria. For example, you can specify source type = cluster, source ID = my-cluster-1 and mycluster2, event categories = Availability, Backup, and severity = ERROR. The subscription will only send notifications for those ERROR events in the Availability and Backup categories for the specified clusters. If you specify both the source type and source IDs, such as source type = cluster and source identifier = my-cluster-1, notifications will be sent for all the cluster events for my-cluster-1. If you specify a source type but do not specify a source identifier, you will receive notice of the events for the objects of that type in your Amazon Web Services account. If you do not specify either the SourceType nor the SourceIdentifier, you will be notified of events generated from all Amazon Redshift sources belonging to your Amazon Web Services account. You must specify a source type if you specify a source ID.
#
# GET /
# operationId: GET_CreateEventSubscription
export def "api get-create-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the event subscription to be created. Constraints: Cannot be null, empty, or blank. Must contain from 1 to 255 alphanumeric characters or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens.
  --sns-topic-arn: string # The Amazon Resource Name (ARN) of the Amazon SNS topic used to transmit the event notifications. The ARN is created by Amazon SNS when you create a topic and subscribe to it.
  --source-type: string # The type of source that will be generating the events. For example, if you want to be notified of events generated by a cluster, you would set this parameter to cluster. If this value is not specified, events are returned for all Amazon Redshift objects in your Amazon Web Services account. You must specify a source type in order to specify source IDs. Valid values: cluster, cluster-parameter-group, cluster-security-group, cluster-snapshot, and scheduled-action.
  --source-ids: list # A list of one or more identifiers of Amazon Redshift source objects. All of the objects must be of the same type as was specified in the source type parameter. The event subscription will return only events generated by the specified objects. If not specified, then events are returned for all objects within the source type specified. Example: my-cluster-1, my-cluster-2 Example: my-snapshot-20131010
  --event-categories: list # Specifies the Amazon Redshift event categories to be published by the event notification subscription. Values: configuration, management, monitoring, security, pending
  --severity: string # Specifies the Amazon Redshift event severity to be published by the event notification subscription. Values: ERROR, INFO
  --enabled: oneof<nothing, bool> # A boolean value; set to true to activate the subscription, and set to false to create the subscription but not activate it.
  --tags: list # A list of tag instances.
  --action: string@action-completer-18
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<EventSubscription: record<CustomerAwsId: record, CustSubscriptionId: record, SnsTopicArn: record, Status: record, SubscriptionCreationTime: record, SourceType: record, SourceIdsList: record, EventCategoriesList: record, Severity: record, Enabled: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SubscriptionName" $subscription_name "scalar") (serialize-qp "SnsTopicArn" $sns_topic_arn "scalar") (serialize-qp "SourceType" $source_type "scalar") (serialize-qp "SourceIds" $source_ids "multi") (serialize-qp "EventCategories" $event_categories "multi") (serialize-qp "Severity" $severity "scalar") (serialize-qp "Enabled" $enabled "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SubscriptionName": $subscription_name, "SnsTopicArn": $sns_topic_arn, "SourceType": $source_type, "SourceIds": $source_ids, "EventCategories": $event_categories, "Severity": $severity, "Enabled": $enabled, "Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates an Amazon Redshift event notification subscription. This action requires an ARN (Amazon Resource Name) of an Amazon SNS topic created by either the Amazon Redshift console, the Amazon SNS console, or the Amazon SNS API. To obtain an ARN with Amazon SNS, you must create a topic in Amazon SNS and subscribe to the topic. The ARN is displayed in the SNS console. You can specify the source type, and lists of Amazon Redshift source IDs, event categories, and event severities. Notifications will be sent for all events you want that match those criteria. For example, you can specify source type = cluster, source ID = my-cluster-1 and mycluster2, event categories = Availability, Backup, and severity = ERROR. The subscription will only send notifications for those ERROR events in the Availability and Backup categories for the specified clusters. If you specify both the source type and source IDs, such as source type = cluster and source identifier = my-cluster-1, notifications will be sent for all the cluster events for my-cluster-1. If you specify a source type but do not specify a source identifier, you will receive notice of the events for the objects of that type in your Amazon Web Services account. If you do not specify either the SourceType nor the SourceIdentifier, you will be notified of events generated from all Amazon Redshift sources belonging to your Amazon Web Services account. You must specify a source type if you specify a source ID.
#
# POST /
# operationId: POST_CreateEventSubscription
export def "api create-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-18
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<EventSubscription: record<CustomerAwsId: record, CustSubscriptionId: record, SnsTopicArn: record, Status: record, SubscriptionCreationTime: record, SourceType: record, SourceIdsList: record, EventCategoriesList: record, Severity: record, Enabled: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates an HSM client certificate that an Amazon Redshift cluster will use to connect to the client's HSM in order to store and retrieve the keys used to encrypt the cluster databases. The command returns a public key, which you must store in the HSM. In addition to creating the HSM certificate, you must create an Amazon Redshift HSM configuration that provides a cluster the information needed to store and use encryption keys in the HSM. For more information, go to Hardware Security Modules (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-db-encryption.html#working-with-HSM) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_CreateHsmClientCertificate
export def "api get-create-hsm-client-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hsm-client-certificate-identifier: string # The identifier to be assigned to the new HSM client certificate that the cluster will use to connect to the HSM to use the database encryption keys.
  --tags: list # A list of tag instances.
  --action: string@action-completer-19
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<HsmClientCertificate: record<HsmClientCertificateIdentifier: record, HsmClientCertificatePublicKey: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "HsmClientCertificateIdentifier" $hsm_client_certificate_identifier "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"HsmClientCertificateIdentifier": $hsm_client_certificate_identifier, "Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates an HSM client certificate that an Amazon Redshift cluster will use to connect to the client's HSM in order to store and retrieve the keys used to encrypt the cluster databases. The command returns a public key, which you must store in the HSM. In addition to creating the HSM certificate, you must create an Amazon Redshift HSM configuration that provides a cluster the information needed to store and use encryption keys in the HSM. For more information, go to Hardware Security Modules (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-db-encryption.html#working-with-HSM) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_CreateHsmClientCertificate
export def "api create-hsm-client-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-19
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<HsmClientCertificate: record<HsmClientCertificateIdentifier: record, HsmClientCertificatePublicKey: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates an HSM configuration that contains the information required by an Amazon Redshift cluster to store and use database encryption keys in a Hardware Security Module (HSM). After creating the HSM configuration, you can specify it as a parameter when creating a cluster. The cluster will then store its encryption keys in the HSM. In addition to creating an HSM configuration, you must also create an HSM client certificate. For more information, go to Hardware Security Modules (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-HSM.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_CreateHsmConfiguration
export def "api get-create-hsm-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hsm-configuration-identifier: string # The identifier to be assigned to the new Amazon Redshift HSM configuration.
  --description: string # A text description of the HSM configuration to be created.
  --hsm-ip-address: string # The IP address that the Amazon Redshift cluster must use to access the HSM.
  --hsm-partition-name: string # The name of the partition in the HSM where the Amazon Redshift clusters will store their database encryption keys.
  --hsm-partition-password: string # The password required to access the HSM partition.
  --hsm-server-public-certificate: string # The HSMs public certificate file. When using Cloud HSM, the file name is server.pem.
  --tags: list # A list of tag instances.
  --action: string@action-completer-20
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<HsmConfiguration: record<HsmConfigurationIdentifier: record, Description: record, HsmIpAddress: record, HsmPartitionName: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "HsmConfigurationIdentifier" $hsm_configuration_identifier "scalar") (serialize-qp "Description" $description "scalar") (serialize-qp "HsmIpAddress" $hsm_ip_address "scalar") (serialize-qp "HsmPartitionName" $hsm_partition_name "scalar") (serialize-qp "HsmPartitionPassword" $hsm_partition_password "scalar") (serialize-qp "HsmServerPublicCertificate" $hsm_server_public_certificate "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"HsmConfigurationIdentifier": $hsm_configuration_identifier, "Description": $description, "HsmIpAddress": $hsm_ip_address, "HsmPartitionName": $hsm_partition_name, "HsmPartitionPassword": $hsm_partition_password, "HsmServerPublicCertificate": $hsm_server_public_certificate, "Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates an HSM configuration that contains the information required by an Amazon Redshift cluster to store and use database encryption keys in a Hardware Security Module (HSM). After creating the HSM configuration, you can specify it as a parameter when creating a cluster. The cluster will then store its encryption keys in the HSM. In addition to creating an HSM configuration, you must also create an HSM client certificate. For more information, go to Hardware Security Modules (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-HSM.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_CreateHsmConfiguration
export def "api create-hsm-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-20
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<HsmConfiguration: record<HsmConfigurationIdentifier: record, Description: record, HsmIpAddress: record, HsmPartitionName: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates a scheduled action. A scheduled action contains a schedule and an Amazon Redshift API action. For example, you can create a schedule of when to run the ResizeCluster API operation.
#
# GET /
# operationId: GET_CreateScheduledAction
export def "api get-create-scheduled-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scheduled-action-name: string # The name of the scheduled action. The name must be unique within an account. For more information about this parameter, see ScheduledAction.
  --target-action: record # A JSON format string of the Amazon Redshift API operation with input parameters. For more information about this parameter, see ScheduledAction.
  --schedule: string # The schedule in at( ) or cron( ) format. For more information about this parameter, see ScheduledAction.
  --iam-role: string # The IAM role to assume to run the target action. For more information about this parameter, see ScheduledAction.
  --scheduled-action-description: string # The description of the scheduled action.
  --start-time: string # The start time in UTC of the scheduled action. Before this time, the scheduled action does not trigger. For more information about this parameter, see ScheduledAction. (format: date-time)
  --end-time: string # The end time in UTC of the scheduled action. After this time, the scheduled action does not trigger. For more information about this parameter, see ScheduledAction. (format: date-time)
  --enable: oneof<nothing, bool> # If true, the schedule is enabled. If false, the scheduled action does not trigger. For more information about state of the scheduled action, see ScheduledAction.
  --action: string@action-completer-21
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ScheduledActionName: record, TargetAction: record<ResizeCluster: record<ClusterIdentifier: record, ClusterType: record, NodeType: record, NumberOfNodes: record, Classic: record, ReservedNodeId: record, TargetReservedNodeOfferingId: record>, PauseCluster: record<ClusterIdentifier: record>, ResumeCluster: record<ClusterIdentifier: record>>, Schedule: record, IamRole: record, ScheduledActionDescription: record, State: record, NextInvocations: record, StartTime: record, EndTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ScheduledActionName" $scheduled_action_name "scalar") (serialize-qp "TargetAction" $target_action "multi") (serialize-qp "Schedule" $schedule "scalar") (serialize-qp "IamRole" $iam_role "scalar") (serialize-qp "ScheduledActionDescription" $scheduled_action_description "scalar") (serialize-qp "StartTime" $start_time "scalar") (serialize-qp "EndTime" $end_time "scalar") (serialize-qp "Enable" $enable "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ScheduledActionName": $scheduled_action_name, "TargetAction": $target_action, "Schedule": $schedule, "IamRole": $iam_role, "ScheduledActionDescription": $scheduled_action_description, "StartTime": $start_time, "EndTime": $end_time, "Enable": $enable, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates a scheduled action. A scheduled action contains a schedule and an Amazon Redshift API action. For example, you can create a schedule of when to run the ResizeCluster API operation.
#
# POST /
# operationId: POST_CreateScheduledAction
export def "api create-scheduled-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-21
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ScheduledActionName: record, TargetAction: record<ResizeCluster: record<ClusterIdentifier: record, ClusterType: record, NodeType: record, NumberOfNodes: record, Classic: record, ReservedNodeId: record, TargetReservedNodeOfferingId: record>, PauseCluster: record<ClusterIdentifier: record>, ResumeCluster: record<ClusterIdentifier: record>>, Schedule: record, IamRole: record, ScheduledActionDescription: record, State: record, NextInvocations: record, StartTime: record, EndTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates a snapshot copy grant that permits Amazon Redshift to use an encrypted symmetric key from Key Management Service (KMS) to encrypt copied snapshots in a destination region. For more information about managing snapshot copy grants, go to Amazon Redshift Database Encryption (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-db-encryption.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_CreateSnapshotCopyGrant
export def "api get-create-snapshot-copy-grant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-copy-grant-name: string # The name of the snapshot copy grant. This name must be unique in the region for the Amazon Web Services account. Constraints: Must contain from 1 to 63 alphanumeric characters or hyphens. Alphabetic characters must be lowercase. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Must be unique for all clusters within an Amazon Web Services account.
  --kms-key-id: string # The unique identifier of the encrypted symmetric key to which to grant Amazon Redshift permission. If no key is specified, the default key is used.
  --tags: list # A list of tag instances.
  --action: string@action-completer-22
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<SnapshotCopyGrant: record<SnapshotCopyGrantName: record, KmsKeyId: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SnapshotCopyGrantName" $snapshot_copy_grant_name "scalar") (serialize-qp "KmsKeyId" $kms_key_id "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SnapshotCopyGrantName": $snapshot_copy_grant_name, "KmsKeyId": $kms_key_id, "Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates a snapshot copy grant that permits Amazon Redshift to use an encrypted symmetric key from Key Management Service (KMS) to encrypt copied snapshots in a destination region. For more information about managing snapshot copy grants, go to Amazon Redshift Database Encryption (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-db-encryption.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_CreateSnapshotCopyGrant
export def "api create-snapshot-copy-grant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-22
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<SnapshotCopyGrant: record<SnapshotCopyGrantName: record, KmsKeyId: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Create a snapshot schedule that can be associated to a cluster and which overrides the default system backup schedule.
#
# GET /
# operationId: GET_CreateSnapshotSchedule
export def "api get-create-snapshot-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schedule-definitions: list # The definition of the snapshot schedule. The definition is made up of schedule expressions, for example "cron(30 12 *)" or "rate(12 hours)".
  --schedule-identifier: string # A unique identifier for a snapshot schedule. Only alphanumeric characters are allowed for the identifier.
  --schedule-description: string # The description of the snapshot schedule.
  --tags: list # An optional set of tags you can use to search for the schedule.
  --qp-dry-run: oneof<nothing, bool>
  --next-invocations: int
  --action: string@action-completer-23
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ScheduleDefinitions: record, ScheduleIdentifier: record, ScheduleDescription: record, Tags: record, NextInvocations: record, AssociatedClusterCount: record, AssociatedClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ScheduleDefinitions" $schedule_definitions "multi") (serialize-qp "ScheduleIdentifier" $schedule_identifier "scalar") (serialize-qp "ScheduleDescription" $schedule_description "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "DryRun" $qp_dry_run "scalar") (serialize-qp "NextInvocations" $next_invocations "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ScheduleDefinitions": $schedule_definitions, "ScheduleIdentifier": $schedule_identifier, "ScheduleDescription": $schedule_description, "Tags": $tags, "DryRun": $qp_dry_run, "NextInvocations": $next_invocations, "Action": $action, "Version": $version} | compact), body: null}
}

# Create a snapshot schedule that can be associated to a cluster and which overrides the default system backup schedule.
#
# POST /
# operationId: POST_CreateSnapshotSchedule
export def "api create-snapshot-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-23
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ScheduleDefinitions: record, ScheduleIdentifier: record, ScheduleDescription: record, Tags: record, NextInvocations: record, AssociatedClusterCount: record, AssociatedClusters: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Adds tags to a cluster. A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, you will receive an error and the attempt will fail. If you specify a key that already exists for the resource, the value for that key will be updated with the new value.
#
# GET /
# operationId: GET_CreateTags
export def "api get-create-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-name: string # The Amazon Resource Name (ARN) to which you want to add the tag or tags. For example, arn:aws:redshift:us-east-2:123456789:cluster:t1.
  --tags: list # One or more name/value pairs to add as tags to the specified resource. Each tag name is passed in with the parameter Key and the corresponding value is passed in with the parameter Value. The Key and Value parameters are separated by a comma (,). Separate multiple tags with a space. For example, --tags "Key"="owner","Value"="admin" "Key"="environment","Value"="test" "Key"="version","Value"="1.0".
  --action: string@action-completer-24
  --version: string@version-completer
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
  let qp = [(serialize-qp "ResourceName" $resource_name "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ResourceName": $resource_name, "Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Adds tags to a cluster. A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, you will receive an error and the attempt will fail. If you specify a key that already exists for the resource, the value for that key will be updated with the new value.
#
# POST /
# operationId: POST_CreateTags
export def "api create-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-24
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates a usage limit for a specified Amazon Redshift feature on a cluster. The usage limit is identified by the returned usage limit identifier.
#
# GET /
# operationId: GET_CreateUsageLimit
export def "api get-create-usage-limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The identifier of the cluster that you want to limit usage.
  --feature-type: string@feature-type-completer # The Amazon Redshift feature that you want to limit.
  --limit-type: string@limit-type-completer # The type of limit. Depending on the feature type, this can be based on a time duration or data size. If FeatureType is spectrum, then LimitType must be data-scanned. If FeatureType is concurrency-scaling, then LimitType must be time. If FeatureType is cross-region-datasharing, then LimitType must be data-scanned.
  --amount: int # The limit amount. If time-based, this amount is in minutes. If data-based, this amount is in terabytes (TB). The value must be a positive number.
  --period: string@period-completer # The time period that the amount applies to. A weekly period begins on Sunday. The default is monthly.
  --breach-action: string@breach-action-completer # The action that Amazon Redshift takes when the limit is reached. The default is log. For more information about this parameter, see UsageLimit.
  --tags: list # A list of tag instances.
  --action: string@action-completer-25
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<UsageLimitId: record, ClusterIdentifier: record, FeatureType: record, LimitType: record, Amount: record, Period: record, BreachAction: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "FeatureType" $feature_type "scalar") (serialize-qp "LimitType" $limit_type "scalar") (serialize-qp "Amount" $amount "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "BreachAction" $breach_action "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "FeatureType": $feature_type, "LimitType": $limit_type, "Amount": $amount, "Period": $period, "BreachAction": $breach_action, "Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates a usage limit for a specified Amazon Redshift feature on a cluster. The usage limit is identified by the returned usage limit identifier.
#
# POST /
# operationId: POST_CreateUsageLimit
export def "api create-usage-limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-25
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<UsageLimitId: record, ClusterIdentifier: record, FeatureType: record, LimitType: record, Amount: record, Period: record, BreachAction: record, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# From a datashare producer account, removes authorization from the specified datashare.
#
# GET /
# operationId: GET_DeauthorizeDataShare
export def "api get-deauthorize-data-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-share-arn: string # The Amazon Resource Name (ARN) of the datashare to remove authorization from.
  --consumer-identifier: string # The identifier of the data consumer that is to have authorization removed from the datashare. This identifier is an Amazon Web Services account ID or a keyword, such as ADX.
  --action: string@action-completer-26
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DataShareArn: record, ProducerArn: record, AllowPubliclyAccessibleConsumers: record, DataShareAssociations: record, ManagedBy: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DataShareArn" $data_share_arn "scalar") (serialize-qp "ConsumerIdentifier" $consumer_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"DataShareArn": $data_share_arn, "ConsumerIdentifier": $consumer_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# From a datashare producer account, removes authorization from the specified datashare.
#
# POST /
# operationId: POST_DeauthorizeDataShare
export def "api create-deauthorize-data-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-26
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DataShareArn: record, ProducerArn: record, AllowPubliclyAccessibleConsumers: record, DataShareAssociations: record, ManagedBy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes an authentication profile.
#
# GET /
# operationId: GET_DeleteAuthenticationProfile
export def "api get-delete-authentication-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authentication-profile-name: string # The name of the authentication profile to delete.
  --action: string@action-completer-27
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AuthenticationProfileName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AuthenticationProfileName" $authentication_profile_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AuthenticationProfileName": $authentication_profile_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes an authentication profile.
#
# POST /
# operationId: POST_DeleteAuthenticationProfile
export def "api create-delete-authentication-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-27
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<AuthenticationProfileName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes a previously provisioned cluster without its final snapshot being created. A successful response from the web service indicates that the request was received correctly. Use DescribeClusters to monitor the status of the deletion. The delete operation cannot be canceled or reverted once submitted. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide. If you want to shut down the cluster and retain it for future use, set SkipFinalClusterSnapshot to false and specify a name for FinalClusterSnapshotIdentifier. You can later restore this snapshot to resume using the cluster. If a final cluster snapshot is requested, the status of the cluster will be "final-snapshot" while the snapshot is being taken, then it's "deleting" once Amazon Redshift begins deleting the cluster. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_DeleteCluster
export def "api get-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The identifier of the cluster to be deleted. Constraints: Must contain lowercase characters. Must contain from 1 to 63 alphanumeric characters or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens.
  --skip-final-cluster-snapshot: oneof<nothing, bool> # Determines whether a final snapshot of the cluster is created before Amazon Redshift deletes the cluster. If true, a final cluster snapshot is not created. If false, a final cluster snapshot is created before the cluster is deleted. The FinalClusterSnapshotIdentifier parameter must be specified if SkipFinalClusterSnapshot is false. Default: false
  --final-cluster-snapshot-identifier: string # The identifier of the final snapshot that is to be created immediately before deleting the cluster. If this parameter is provided, SkipFinalClusterSnapshot must be false. Constraints: Must be 1 to 255 alphanumeric characters. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens.
  --final-cluster-snapshot-retention-period: int # The number of days that a manual snapshot is retained. If the value is -1, the manual snapshot is retained indefinitely. The value must be either -1 or an integer between 1 and 3,653. The default value is -1.
  --action: string@action-completer-28
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "SkipFinalClusterSnapshot" $skip_final_cluster_snapshot "scalar") (serialize-qp "FinalClusterSnapshotIdentifier" $final_cluster_snapshot_identifier "scalar") (serialize-qp "FinalClusterSnapshotRetentionPeriod" $final_cluster_snapshot_retention_period "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "SkipFinalClusterSnapshot": $skip_final_cluster_snapshot, "FinalClusterSnapshotIdentifier": $final_cluster_snapshot_identifier, "FinalClusterSnapshotRetentionPeriod": $final_cluster_snapshot_retention_period, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes a previously provisioned cluster without its final snapshot being created. A successful response from the web service indicates that the request was received correctly. Use DescribeClusters to monitor the status of the deletion. The delete operation cannot be canceled or reverted once submitted. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide. If you want to shut down the cluster and retain it for future use, set SkipFinalClusterSnapshot to false and specify a name for FinalClusterSnapshotIdentifier. You can later restore this snapshot to resume using the cluster. If a final cluster snapshot is requested, the status of the cluster will be "final-snapshot" while the snapshot is being taken, then it's "deleting" once Amazon Redshift begins deleting the cluster. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_DeleteCluster
export def "api create-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-28
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes a specified Amazon Redshift parameter group. You cannot delete a parameter group if it is associated with a cluster.
#
# GET /
# operationId: GET_DeleteClusterParameterGroup
export def "api get-delete-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameter-group-name: string # The name of the parameter group to be deleted. Constraints: Must be the name of an existing cluster parameter group. Cannot delete a default cluster parameter group.
  --action: string@action-completer-29
  --version: string@version-completer
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
  let qp = [(serialize-qp "ParameterGroupName" $parameter_group_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ParameterGroupName": $parameter_group_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes a specified Amazon Redshift parameter group. You cannot delete a parameter group if it is associated with a cluster.
#
# POST /
# operationId: POST_DeleteClusterParameterGroup
export def "api create-delete-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-29
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes an Amazon Redshift security group. You cannot delete a security group that is associated with any clusters. You cannot delete the default security group. For information about managing security groups, go to Amazon Redshift Cluster Security Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-security-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_DeleteClusterSecurityGroup
export def "api get-delete-security-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-security-group-name: string # The name of the cluster security group to be deleted.
  --action: string@action-completer-30
  --version: string@version-completer
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
  let qp = [(serialize-qp "ClusterSecurityGroupName" $cluster_security_group_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterSecurityGroupName": $cluster_security_group_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes an Amazon Redshift security group. You cannot delete a security group that is associated with any clusters. You cannot delete the default security group. For information about managing security groups, go to Amazon Redshift Cluster Security Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-security-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_DeleteClusterSecurityGroup
export def "api create-delete-security-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-30
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes the specified manual snapshot. The snapshot must be in the available state, with no other users authorized to access the snapshot. Unlike automated snapshots, manual snapshots are retained even after you delete your cluster. Amazon Redshift does not delete your manual snapshots. You must delete manual snapshot explicitly to avoid getting charged. If other accounts are authorized to access the snapshot, you must revoke all of the authorizations before you can delete the snapshot.
#
# GET /
# operationId: GET_DeleteClusterSnapshot
export def "api get-delete-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-identifier: string # The unique identifier of the manual snapshot to be deleted. Constraints: Must be the name of an existing snapshot that is in the available, failed, or cancelled state.
  --snapshot-cluster-identifier: string # The unique identifier of the cluster the snapshot was created from. This parameter is required if your IAM user or role has a policy containing a snapshot resource element that specifies anything other than * for the cluster name. Constraints: Must be the name of valid cluster.
  --action: string@action-completer-31
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Snapshot: record<SnapshotIdentifier: record, ClusterIdentifier: record, SnapshotCreateTime: record, Status: record, Port: record, AvailabilityZone: record, ClusterCreateTime: record, MasterUsername: record, ClusterVersion: record, EngineFullVersion: record, SnapshotType: record, NodeType: record, NumberOfNodes: record, DBName: record, VpcId: record, Encrypted: record, KmsKeyId: record, EncryptedWithHSM: record, AccountsWithRestoreAccess: record, OwnerAccount: record, TotalBackupSizeInMegaBytes: record, ActualIncrementalBackupSizeInMegaBytes: record, BackupProgressInMegaBytes: record, CurrentBackupRateInMegaBytesPerSecond: record, EstimatedSecondsToCompletion: record, ElapsedTimeInSeconds: record, SourceRegion: record, Tags: record, RestorableNodeTypes: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, ManualSnapshotRetentionPeriod: record, ManualSnapshotRemainingDays: record, SnapshotRetentionStartTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SnapshotIdentifier" $snapshot_identifier "scalar") (serialize-qp "SnapshotClusterIdentifier" $snapshot_cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SnapshotIdentifier": $snapshot_identifier, "SnapshotClusterIdentifier": $snapshot_cluster_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the specified manual snapshot. The snapshot must be in the available state, with no other users authorized to access the snapshot. Unlike automated snapshots, manual snapshots are retained even after you delete your cluster. Amazon Redshift does not delete your manual snapshots. You must delete manual snapshot explicitly to avoid getting charged. If other accounts are authorized to access the snapshot, you must revoke all of the authorizations before you can delete the snapshot.
#
# POST /
# operationId: POST_DeleteClusterSnapshot
export def "api create-delete-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-31
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Snapshot: record<SnapshotIdentifier: record, ClusterIdentifier: record, SnapshotCreateTime: record, Status: record, Port: record, AvailabilityZone: record, ClusterCreateTime: record, MasterUsername: record, ClusterVersion: record, EngineFullVersion: record, SnapshotType: record, NodeType: record, NumberOfNodes: record, DBName: record, VpcId: record, Encrypted: record, KmsKeyId: record, EncryptedWithHSM: record, AccountsWithRestoreAccess: record, OwnerAccount: record, TotalBackupSizeInMegaBytes: record, ActualIncrementalBackupSizeInMegaBytes: record, BackupProgressInMegaBytes: record, CurrentBackupRateInMegaBytesPerSecond: record, EstimatedSecondsToCompletion: record, ElapsedTimeInSeconds: record, SourceRegion: record, Tags: record, RestorableNodeTypes: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, ManualSnapshotRetentionPeriod: record, ManualSnapshotRemainingDays: record, SnapshotRetentionStartTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes the specified cluster subnet group.
#
# GET /
# operationId: GET_DeleteClusterSubnetGroup
export def "api get-delete-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-subnet-group-name: string # The name of the cluster subnet group name to be deleted.
  --action: string@action-completer-32
  --version: string@version-completer
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
  let qp = [(serialize-qp "ClusterSubnetGroupName" $cluster_subnet_group_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterSubnetGroupName": $cluster_subnet_group_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the specified cluster subnet group.
#
# POST /
# operationId: POST_DeleteClusterSubnetGroup
export def "api create-delete-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-32
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes a Redshift-managed VPC endpoint.
#
# GET /
# operationId: GET_DeleteEndpointAccess
export def "api get-delete-endpoint-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --endpoint-name: string # The Redshift-managed VPC endpoint to delete.
  --action: string@action-completer-33
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ClusterIdentifier: record, ResourceOwner: record, SubnetGroupName: record, EndpointStatus: record, EndpointName: record, EndpointCreateTime: record, Port: record, Address: record, VpcSecurityGroups: record, VpcEndpoint: record<VpcEndpointId: record, VpcId: record, NetworkInterfaces: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EndpointName" $endpoint_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"EndpointName": $endpoint_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes a Redshift-managed VPC endpoint.
#
# POST /
# operationId: POST_DeleteEndpointAccess
export def "api create-delete-endpoint-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-33
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ClusterIdentifier: record, ResourceOwner: record, SubnetGroupName: record, EndpointStatus: record, EndpointName: record, EndpointCreateTime: record, Port: record, Address: record, VpcSecurityGroups: record, VpcEndpoint: record<VpcEndpointId: record, VpcId: record, NetworkInterfaces: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes an Amazon Redshift event notification subscription.
#
# GET /
# operationId: GET_DeleteEventSubscription
export def "api get-delete-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the Amazon Redshift event notification subscription to be deleted.
  --action: string@action-completer-34
  --version: string@version-completer
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
  let qp = [(serialize-qp "SubscriptionName" $subscription_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SubscriptionName": $subscription_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes an Amazon Redshift event notification subscription.
#
# POST /
# operationId: POST_DeleteEventSubscription
export def "api create-delete-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-34
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes the specified HSM client certificate.
#
# GET /
# operationId: GET_DeleteHsmClientCertificate
export def "api get-delete-hsm-client-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hsm-client-certificate-identifier: string # The identifier of the HSM client certificate to be deleted.
  --action: string@action-completer-35
  --version: string@version-completer
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
  let qp = [(serialize-qp "HsmClientCertificateIdentifier" $hsm_client_certificate_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"HsmClientCertificateIdentifier": $hsm_client_certificate_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the specified HSM client certificate.
#
# POST /
# operationId: POST_DeleteHsmClientCertificate
export def "api create-delete-hsm-client-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-35
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes the specified Amazon Redshift HSM configuration.
#
# GET /
# operationId: GET_DeleteHsmConfiguration
export def "api get-delete-hsm-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hsm-configuration-identifier: string # The identifier of the Amazon Redshift HSM configuration to be deleted.
  --action: string@action-completer-36
  --version: string@version-completer
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
  let qp = [(serialize-qp "HsmConfigurationIdentifier" $hsm_configuration_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"HsmConfigurationIdentifier": $hsm_configuration_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the specified Amazon Redshift HSM configuration.
#
# POST /
# operationId: POST_DeleteHsmConfiguration
export def "api create-delete-hsm-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-36
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes a partner integration from a cluster. Data can still flow to the cluster until the integration is deleted at the partner's website.
#
# GET /
# operationId: GET_DeletePartner
export def "api get-delete-partner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The Amazon Web Services account ID that owns the cluster.
  --cluster-identifier: string # The cluster identifier of the cluster that receives data from the partner.
  --database-name: string # The name of the database that receives data from the partner.
  --partner-name: string # The name of the partner that is authorized to send data.
  --action: string@action-completer-37
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DatabaseName: record, PartnerName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AccountId" $account_id "scalar") (serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "DatabaseName" $database_name "scalar") (serialize-qp "PartnerName" $partner_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AccountId": $account_id, "ClusterIdentifier": $cluster_identifier, "DatabaseName": $database_name, "PartnerName": $partner_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes a partner integration from a cluster. Data can still flow to the cluster until the integration is deleted at the partner's website.
#
# POST /
# operationId: POST_DeletePartner
export def "api create-delete-partner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-37
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DatabaseName: record, PartnerName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes a scheduled action.
#
# GET /
# operationId: GET_DeleteScheduledAction
export def "api get-delete-scheduled-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scheduled-action-name: string # The name of the scheduled action to delete.
  --action: string@action-completer-38
  --version: string@version-completer
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
  let qp = [(serialize-qp "ScheduledActionName" $scheduled_action_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ScheduledActionName": $scheduled_action_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes a scheduled action.
#
# POST /
# operationId: POST_DeleteScheduledAction
export def "api create-delete-scheduled-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-38
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes the specified snapshot copy grant.
#
# GET /
# operationId: GET_DeleteSnapshotCopyGrant
export def "api get-delete-snapshot-copy-grant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-copy-grant-name: string # The name of the snapshot copy grant to delete.
  --action: string@action-completer-39
  --version: string@version-completer
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
  let qp = [(serialize-qp "SnapshotCopyGrantName" $snapshot_copy_grant_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SnapshotCopyGrantName": $snapshot_copy_grant_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the specified snapshot copy grant.
#
# POST /
# operationId: POST_DeleteSnapshotCopyGrant
export def "api create-delete-snapshot-copy-grant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-39
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes a snapshot schedule.
#
# GET /
# operationId: GET_DeleteSnapshotSchedule
export def "api get-delete-snapshot-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schedule-identifier: string # A unique identifier of the snapshot schedule to delete.
  --action: string@action-completer-40
  --version: string@version-completer
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
  let qp = [(serialize-qp "ScheduleIdentifier" $schedule_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ScheduleIdentifier": $schedule_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes a snapshot schedule.
#
# POST /
# operationId: POST_DeleteSnapshotSchedule
export def "api create-delete-snapshot-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-40
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes tags from a resource. You must provide the ARN of the resource from which you want to delete the tag or tags.
#
# GET /
# operationId: GET_DeleteTags
export def "api get-delete-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-name: string # The Amazon Resource Name (ARN) from which you want to remove the tag or tags. For example, arn:aws:redshift:us-east-2:123456789:cluster:t1.
  --tag-keys: list # The tag key that you want to delete.
  --action: string@action-completer-41
  --version: string@version-completer
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
  let qp = [(serialize-qp "ResourceName" $resource_name "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ResourceName": $resource_name, "TagKeys": $tag_keys, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes tags from a resource. You must provide the ARN of the resource from which you want to delete the tag or tags.
#
# POST /
# operationId: POST_DeleteTags
export def "api create-delete-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-41
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes a usage limit from a cluster.
#
# GET /
# operationId: GET_DeleteUsageLimit
export def "api get-delete-usage-limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --usage-limit-id: string # The identifier of the usage limit to delete.
  --action: string@action-completer-42
  --version: string@version-completer
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
  let qp = [(serialize-qp "UsageLimitId" $usage_limit_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"UsageLimitId": $usage_limit_id, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes a usage limit from a cluster.
#
# POST /
# operationId: POST_DeleteUsageLimit
export def "api create-delete-usage-limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-42
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a list of attributes attached to an account
#
# GET /
# operationId: GET_DescribeAccountAttributes
export def "api get-account-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-names: list # A list of attribute names.
  --action: string@action-completer-43
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AccountAttributes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AttributeNames" $attribute_names "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AttributeNames": $attribute_names, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a list of attributes attached to an account
#
# POST /
# operationId: POST_DescribeAccountAttributes
export def "api create-get-account-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-43
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<AccountAttributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Describes an authentication profile.
#
# GET /
# operationId: GET_DescribeAuthenticationProfiles
export def "api get-authentication-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authentication-profile-name: string # The name of the authentication profile to describe. If not specified then all authentication profiles owned by the account are listed.
  --action: string@action-completer-44
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AuthenticationProfiles: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AuthenticationProfileName" $authentication_profile_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AuthenticationProfileName": $authentication_profile_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Describes an authentication profile.
#
# POST /
# operationId: POST_DescribeAuthenticationProfiles
export def "api create-get-authentication-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-44
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<AuthenticationProfiles: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns an array of ClusterDbRevision objects.
#
# GET /
# operationId: GET_DescribeClusterDbRevisions
export def "api get-db-revisions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # A unique identifier for a cluster whose ClusterDbRevisions you are requesting. This parameter is case sensitive. All clusters defined for an account are returned by default.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in the marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the marker parameter and retrying the request. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point for returning a set of response records. When the results of a DescribeClusterDbRevisions request exceed the value specified in MaxRecords, Amazon Redshift returns a value in the marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the marker parameter and retrying the request. Constraints: You can specify either the ClusterIdentifier parameter, or the marker parameter, but not both.
  --action: string@action-completer-45
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, ClusterDbRevisions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns an array of ClusterDbRevision objects.
#
# POST /
# operationId: POST_DescribeClusterDbRevisions
export def "api create-get-db-revisions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-45
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, ClusterDbRevisions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a list of Amazon Redshift parameter groups, including parameter groups you created and the default parameter group. For each parameter group, the response includes the parameter group name, description, and parameter group family name. You can optionally specify a name to retrieve the description of a specific parameter group. For more information about parameters and parameter groups, go to Amazon Redshift Parameter Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-parameter-groups.html) in the Amazon Redshift Cluster Management Guide. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all parameter groups that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all parameter groups that have any combination of those values are returned. If both tag keys and values are omitted from the request, parameter groups are returned regardless of whether they have tag keys or values associated with them.
#
# GET /
# operationId: GET_DescribeClusterParameterGroups
export def "api get-parameter-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameter-group-name: string # The name of a specific parameter group for which to return details. By default, details about all parameter groups and the default parameter group are returned.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeClusterParameterGroups request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --tag-keys: list # A tag key or keys for which you want to return all matching cluster parameter groups that are associated with the specified key or keys. For example, suppose that you have parameter groups that are tagged with keys called owner and environment. If you specify both of these tag keys in the request, Amazon Redshift returns a response with the parameter groups that have either or both of these tag keys associated with them.
  --tag-values: list # A tag value or values for which you want to return all matching cluster parameter groups that are associated with the specified tag value or values. For example, suppose that you have parameter groups that are tagged with values called admin and test. If you specify both of these tag values in the request, Amazon Redshift returns a response with the parameter groups that have either or both of these tag values associated with them.
  --action: string@action-completer-46
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, ParameterGroups: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ParameterGroupName" $parameter_group_name "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "TagValues" $tag_values "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ParameterGroupName": $parameter_group_name, "MaxRecords": $max_records, "Marker": $marker, "TagKeys": $tag_keys, "TagValues": $tag_values, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a list of Amazon Redshift parameter groups, including parameter groups you created and the default parameter group. For each parameter group, the response includes the parameter group name, description, and parameter group family name. You can optionally specify a name to retrieve the description of a specific parameter group. For more information about parameters and parameter groups, go to Amazon Redshift Parameter Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-parameter-groups.html) in the Amazon Redshift Cluster Management Guide. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all parameter groups that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all parameter groups that have any combination of those values are returned. If both tag keys and values are omitted from the request, parameter groups are returned regardless of whether they have tag keys or values associated with them.
#
# POST /
# operationId: POST_DescribeClusterParameterGroups
export def "api create-get-parameter-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-46
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, ParameterGroups: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a detailed list of parameters contained within the specified Amazon Redshift parameter group. For each parameter the response includes information such as parameter name, description, data type, value, whether the parameter value is modifiable, and so on. You can specify source filter to retrieve parameters of only specific type. For example, to retrieve parameters that were modified by a user action such as from ModifyClusterParameterGroup, you can specify source equal to user. For more information about parameters and parameter groups, go to Amazon Redshift Parameter Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-parameter-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_DescribeClusterParameters
export def "api get-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameter-group-name: string # The name of a cluster parameter group for which to return details.
  --qp-source: string # The parameter types to return. Specify user to show parameters that are different form the default. Similarly, specify engine-default to show parameters that are the same as the default parameter group. Default: All parameter types returned. Valid Values: user | engine-default
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeClusterParameters request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --action: string@action-completer-47
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Parameters: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ParameterGroupName" $parameter_group_name "scalar") (serialize-qp "Source" $qp_source "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ParameterGroupName": $parameter_group_name, "Source": $qp_source, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a detailed list of parameters contained within the specified Amazon Redshift parameter group. For each parameter the response includes information such as parameter name, description, data type, value, whether the parameter value is modifiable, and so on. You can specify source filter to retrieve parameters of only specific type. For example, to retrieve parameters that were modified by a user action such as from ModifyClusterParameterGroup, you can specify source equal to user. For more information about parameters and parameter groups, go to Amazon Redshift Parameter Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-parameter-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_DescribeClusterParameters
export def "api create-get-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-47
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Parameters: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns information about Amazon Redshift security groups. If the name of a security group is specified, the response will contain only information about only that security group. For information about managing security groups, go to Amazon Redshift Cluster Security Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-security-groups.html) in the Amazon Redshift Cluster Management Guide. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all security groups that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all security groups that have any combination of those values are returned. If both tag keys and values are omitted from the request, security groups are returned regardless of whether they have tag keys or values associated with them.
#
# GET /
# operationId: GET_DescribeClusterSecurityGroups
export def "api get-security-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-security-group-name: string # The name of a cluster security group for which you are requesting details. You must specify either the Marker parameter or a ClusterSecurityGroupName parameter, but not both. Example: securitygroup1
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeClusterSecurityGroups request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request. Constraints: You must specify either the ClusterSecurityGroupName parameter or the Marker parameter, but not both.
  --tag-keys: list # A tag key or keys for which you want to return all matching cluster security groups that are associated with the specified key or keys. For example, suppose that you have security groups that are tagged with keys called owner and environment. If you specify both of these tag keys in the request, Amazon Redshift returns a response with the security groups that have either or both of these tag keys associated with them.
  --tag-values: list # A tag value or values for which you want to return all matching cluster security groups that are associated with the specified tag value or values. For example, suppose that you have security groups that are tagged with values called admin and test. If you specify both of these tag values in the request, Amazon Redshift returns a response with the security groups that have either or both of these tag values associated with them.
  --action: string@action-completer-48
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, ClusterSecurityGroups: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterSecurityGroupName" $cluster_security_group_name "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "TagValues" $tag_values "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterSecurityGroupName": $cluster_security_group_name, "MaxRecords": $max_records, "Marker": $marker, "TagKeys": $tag_keys, "TagValues": $tag_values, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns information about Amazon Redshift security groups. If the name of a security group is specified, the response will contain only information about only that security group. For information about managing security groups, go to Amazon Redshift Cluster Security Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-security-groups.html) in the Amazon Redshift Cluster Management Guide. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all security groups that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all security groups that have any combination of those values are returned. If both tag keys and values are omitted from the request, security groups are returned regardless of whether they have tag keys or values associated with them.
#
# POST /
# operationId: POST_DescribeClusterSecurityGroups
export def "api create-get-security-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-48
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, ClusterSecurityGroups: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns one or more snapshot objects, which contain metadata about your cluster snapshots. By default, this operation returns information about all snapshots of all clusters that are owned by your Amazon Web Services account. No information is returned for snapshots owned by inactive Amazon Web Services accounts. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all snapshots that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all snapshots that have any combination of those values are returned. Only snapshots that you own are returned in the response; shared snapshots are not returned with the tag key and tag value request parameters. If both tag keys and values are omitted from the request, snapshots are returned regardless of whether they have tag keys or values associated with them.
#
# GET /
# operationId: GET_DescribeClusterSnapshots
export def "api get-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The identifier of the cluster which generated the requested snapshots.
  --snapshot-identifier: string # The snapshot identifier of the snapshot about which to return information.
  --snapshot-arn: string # The Amazon Resource Name (ARN) of the snapshot associated with the message to describe cluster snapshots.
  --snapshot-type: string # The type of snapshots for which you are requesting information. By default, snapshots of all types are returned. Valid Values: automated | manual
  --start-time: string # A value that requests only snapshots created at or after the specified time. The time value is specified in ISO 8601 format. For more information about ISO 8601, go to the ISO8601 Wikipedia page. (http://en.wikipedia.org/wiki/ISO_8601) Example: 2012-07-16T18:00:00Z (format: date-time)
  --end-time: string # A time value that requests only snapshots created at or before the specified time. The time value is specified in ISO 8601 format. For more information about ISO 8601, go to the ISO8601 Wikipedia page. (http://en.wikipedia.org/wiki/ISO_8601) Example: 2012-07-16T18:00:00Z (format: date-time)
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 500.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeClusterSnapshots request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --owner-account: string # The Amazon Web Services account used to create or copy the snapshot. Use this field to filter the results to snapshots owned by a particular account. To describe snapshots you own, either specify your Amazon Web Services account, or do not specify the parameter.
  --tag-keys: list # A tag key or keys for which you want to return all matching cluster snapshots that are associated with the specified key or keys. For example, suppose that you have snapshots that are tagged with keys called owner and environment. If you specify both of these tag keys in the request, Amazon Redshift returns a response with the snapshots that have either or both of these tag keys associated with them.
  --tag-values: list # A tag value or values for which you want to return all matching cluster snapshots that are associated with the specified tag value or values. For example, suppose that you have snapshots that are tagged with values called admin and test. If you specify both of these tag values in the request, Amazon Redshift returns a response with the snapshots that have either or both of these tag values associated with them.
  --cluster-exists: oneof<nothing, bool> # A value that indicates whether to return snapshots only for an existing cluster. You can perform table-level restore only by using a snapshot of an existing cluster, that is, a cluster that has not been deleted. Values for this parameter work as follows: If ClusterExists is set to true, ClusterIdentifier is required. If ClusterExists is set to false and ClusterIdentifier isn't specified, all snapshots associated with deleted clusters (orphaned snapshots) are returned. If ClusterExists is set to false and ClusterIdentifier is specified for a deleted cluster, snapshots associated with that cluster are returned. If ClusterExists is set to false and ClusterIdentifier is specified for an existing cluster, no snapshots are returned.
  --sorting-entities: list
  --action: string@action-completer-49
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, Snapshots: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "SnapshotIdentifier" $snapshot_identifier "scalar") (serialize-qp "SnapshotArn" $snapshot_arn "scalar") (serialize-qp "SnapshotType" $snapshot_type "scalar") (serialize-qp "StartTime" $start_time "scalar") (serialize-qp "EndTime" $end_time "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "OwnerAccount" $owner_account "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "TagValues" $tag_values "multi") (serialize-qp "ClusterExists" $cluster_exists "scalar") (serialize-qp "SortingEntities" $sorting_entities "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "SnapshotIdentifier": $snapshot_identifier, "SnapshotArn": $snapshot_arn, "SnapshotType": $snapshot_type, "StartTime": $start_time, "EndTime": $end_time, "MaxRecords": $max_records, "Marker": $marker, "OwnerAccount": $owner_account, "TagKeys": $tag_keys, "TagValues": $tag_values, "ClusterExists": $cluster_exists, "SortingEntities": $sorting_entities, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns one or more snapshot objects, which contain metadata about your cluster snapshots. By default, this operation returns information about all snapshots of all clusters that are owned by your Amazon Web Services account. No information is returned for snapshots owned by inactive Amazon Web Services accounts. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all snapshots that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all snapshots that have any combination of those values are returned. Only snapshots that you own are returned in the response; shared snapshots are not returned with the tag key and tag value request parameters. If both tag keys and values are omitted from the request, snapshots are returned regardless of whether they have tag keys or values associated with them.
#
# POST /
# operationId: POST_DescribeClusterSnapshots
export def "api create-get-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-49
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, Snapshots: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns one or more cluster subnet group objects, which contain metadata about your cluster subnet groups. By default, this operation returns information about all cluster subnet groups that are defined in your Amazon Web Services account. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all subnet groups that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all subnet groups that have any combination of those values are returned. If both tag keys and values are omitted from the request, subnet groups are returned regardless of whether they have tag keys or values associated with them.
#
# GET /
# operationId: GET_DescribeClusterSubnetGroups
export def "api get-subnet-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-subnet-group-name: string # The name of the cluster subnet group for which information is requested.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeClusterSubnetGroups request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --tag-keys: list # A tag key or keys for which you want to return all matching cluster subnet groups that are associated with the specified key or keys. For example, suppose that you have subnet groups that are tagged with keys called owner and environment. If you specify both of these tag keys in the request, Amazon Redshift returns a response with the subnet groups that have either or both of these tag keys associated with them.
  --tag-values: list # A tag value or values for which you want to return all matching cluster subnet groups that are associated with the specified tag value or values. For example, suppose that you have subnet groups that are tagged with values called admin and test. If you specify both of these tag values in the request, Amazon Redshift returns a response with the subnet groups that have either or both of these tag values associated with them.
  --action: string@action-completer-50
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, ClusterSubnetGroups: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterSubnetGroupName" $cluster_subnet_group_name "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "TagValues" $tag_values "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterSubnetGroupName": $cluster_subnet_group_name, "MaxRecords": $max_records, "Marker": $marker, "TagKeys": $tag_keys, "TagValues": $tag_values, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns one or more cluster subnet group objects, which contain metadata about your cluster subnet groups. By default, this operation returns information about all cluster subnet groups that are defined in your Amazon Web Services account. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all subnet groups that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all subnet groups that have any combination of those values are returned. If both tag keys and values are omitted from the request, subnet groups are returned regardless of whether they have tag keys or values associated with them.
#
# POST /
# operationId: POST_DescribeClusterSubnetGroups
export def "api create-get-subnet-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-50
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, ClusterSubnetGroups: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a list of all the available maintenance tracks.
#
# GET /
# operationId: GET_DescribeClusterTracks
export def "api get-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maintenance-track-name: string # The name of the maintenance track.
  --max-records: int # An integer value for the maximum number of maintenance tracks to return.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeClusterTracks request exceed the value specified in MaxRecords, Amazon Redshift returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --action: string@action-completer-51
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<MaintenanceTracks: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaintenanceTrackName" $maintenance_track_name "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"MaintenanceTrackName": $maintenance_track_name, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a list of all the available maintenance tracks.
#
# POST /
# operationId: POST_DescribeClusterTracks
export def "api create-get-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-51
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<MaintenanceTracks: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns descriptions of the available Amazon Redshift cluster versions. You can call this operation even before creating any clusters to learn more about the Amazon Redshift versions. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_DescribeClusterVersions
export def "api get-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-version: string # The specific cluster version to return. Example: 1.0
  --cluster-parameter-group-family: string # The name of a specific cluster parameter group family to return details for. Constraints: Must be 1 to 255 alphanumeric characters First character must be a letter Cannot end with a hyphen or contain two consecutive hyphens
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeClusterVersions request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --action: string@action-completer-52
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, ClusterVersions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterVersion" $cluster_version "scalar") (serialize-qp "ClusterParameterGroupFamily" $cluster_parameter_group_family "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterVersion": $cluster_version, "ClusterParameterGroupFamily": $cluster_parameter_group_family, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns descriptions of the available Amazon Redshift cluster versions. You can call this operation even before creating any clusters to learn more about the Amazon Redshift versions. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_DescribeClusterVersions
export def "api create-get-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-52
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, ClusterVersions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns properties of provisioned clusters including general cluster properties, cluster database properties, maintenance and backup properties, and security and access properties. This operation supports pagination. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all clusters that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all clusters that have any combination of those values are returned. If both tag keys and values are omitted from the request, clusters are returned regardless of whether they have tag keys or values associated with them.
#
# GET /
# operationId: GET_DescribeClusters
export def "api get-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The unique identifier of a cluster whose properties you are requesting. This parameter is case sensitive. The default is that all clusters defined for an account are returned.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeClusters request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request. Constraints: You can specify either the ClusterIdentifier parameter or the Marker parameter, but not both.
  --tag-keys: list # A tag key or keys for which you want to return all matching clusters that are associated with the specified key or keys. For example, suppose that you have clusters that are tagged with keys called owner and environment. If you specify both of these tag keys in the request, Amazon Redshift returns a response with the clusters that have either or both of these tag keys associated with them.
  --tag-values: list # A tag value or values for which you want to return all matching clusters that are associated with the specified tag value or values. For example, suppose that you have clusters that are tagged with values called admin and test. If you specify both of these tag values in the request, Amazon Redshift returns a response with the clusters that have either or both of these tag values associated with them.
  --action: string@action-completer-53
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, Clusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "TagValues" $tag_values "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "MaxRecords": $max_records, "Marker": $marker, "TagKeys": $tag_keys, "TagValues": $tag_values, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns properties of provisioned clusters including general cluster properties, cluster database properties, maintenance and backup properties, and security and access properties. This operation supports pagination. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all clusters that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all clusters that have any combination of those values are returned. If both tag keys and values are omitted from the request, clusters are returned regardless of whether they have tag keys or values associated with them.
#
# POST /
# operationId: POST_DescribeClusters
export def "api create-get-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-53
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, Clusters: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Shows the status of any inbound or outbound datashares available in the specified account.
#
# GET /
# operationId: GET_DescribeDataShares
export def "api get-data-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-share-arn: string # The identifier of the datashare to describe details of.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeDataShares request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --action: string@action-completer-54
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DataShares: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DataShareArn" $data_share_arn "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"DataShareArn": $data_share_arn, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Shows the status of any inbound or outbound datashares available in the specified account.
#
# POST /
# operationId: POST_DescribeDataShares
export def "api create-get-data-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-54
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DataShares: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a list of datashares where the account identifier being called is a consumer account identifier.
#
# GET /
# operationId: GET_DescribeDataSharesForConsumer
export def "api get-data-shares-for-consumer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --consumer-arn: string # The Amazon Resource Name (ARN) of the consumer that returns in the list of datashares.
  --status: string@status-completer # An identifier giving the status of a datashare in the consumer cluster. If this field is specified, Amazon Redshift returns the list of datashares that have the specified status.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeDataSharesForConsumer request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --action: string@action-completer-55
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DataShares: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ConsumerArn" $consumer_arn "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ConsumerArn": $consumer_arn, "Status": $status, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a list of datashares where the account identifier being called is a consumer account identifier.
#
# POST /
# operationId: POST_DescribeDataSharesForConsumer
export def "api create-get-data-shares-for-consumer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-55
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DataShares: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a list of datashares when the account identifier being called is a producer account identifier.
#
# GET /
# operationId: GET_DescribeDataSharesForProducer
export def "api get-data-shares-for-producer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --producer-arn: string # The Amazon Resource Name (ARN) of the producer that returns in the list of datashares.
  --status: string@status-completer-1 # An identifier giving the status of a datashare in the producer. If this field is specified, Amazon Redshift returns the list of datashares that have the specified status.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeDataSharesForProducer request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --action: string@action-completer-56
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DataShares: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ProducerArn" $producer_arn "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ProducerArn": $producer_arn, "Status": $status, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a list of datashares when the account identifier being called is a producer account identifier.
#
# POST /
# operationId: POST_DescribeDataSharesForProducer
export def "api create-get-data-shares-for-producer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-56
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DataShares: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a list of parameter settings for the specified parameter group family. For more information about parameters and parameter groups, go to Amazon Redshift Parameter Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-parameter-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_DescribeDefaultClusterParameters
export def "api get-default-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameter-group-family: string # The name of the cluster parameter group family.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeDefaultClusterParameters request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --action: string@action-completer-57
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DefaultClusterParameters: record<ParameterGroupFamily: record, Marker: record, Parameters: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ParameterGroupFamily" $parameter_group_family "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ParameterGroupFamily": $parameter_group_family, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a list of parameter settings for the specified parameter group family. For more information about parameters and parameter groups, go to Amazon Redshift Parameter Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-parameter-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_DescribeDefaultClusterParameters
export def "api create-get-default-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-57
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DefaultClusterParameters: record<ParameterGroupFamily: record, Marker: record, Parameters: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Describes a Redshift-managed VPC endpoint.
#
# GET /
# operationId: GET_DescribeEndpointAccess
export def "api get-endpoint-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The cluster identifier associated with the described endpoint.
  --resource-owner: string # The Amazon Web Services account ID of the owner of the cluster.
  --endpoint-name: string # The name of the endpoint to be described.
  --vpc-id: string # The virtual private cloud (VPC) identifier with access to the cluster.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a Marker is included in the response so that the remaining results can be retrieved.
  --marker: string # An optional pagination token provided by a previous DescribeEndpointAccess request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by the MaxRecords parameter.
  --action: string@action-completer-58
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<EndpointAccessList: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "ResourceOwner" $resource_owner "scalar") (serialize-qp "EndpointName" $endpoint_name "scalar") (serialize-qp "VpcId" $vpc_id "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "ResourceOwner": $resource_owner, "EndpointName": $endpoint_name, "VpcId": $vpc_id, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Describes a Redshift-managed VPC endpoint.
#
# POST /
# operationId: POST_DescribeEndpointAccess
export def "api create-get-endpoint-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-58
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<EndpointAccessList: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Describes an endpoint authorization.
#
# GET /
# operationId: GET_DescribeEndpointAuthorization
export def "api get-endpoint-authorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The cluster identifier of the cluster to access.
  --account: string # The Amazon Web Services account ID of either the cluster owner (grantor) or grantee. If Grantee parameter is true, then the Account value is of the grantor.
  --grantee: oneof<nothing, bool> # Indicates whether to check authorization from a grantor or grantee point of view. If true, Amazon Redshift returns endpoint authorizations that you've been granted. If false (default), checks authorization from a grantor point of view.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a Marker is included in the response so that the remaining results can be retrieved.
  --marker: string # An optional pagination token provided by a previous DescribeEndpointAuthorization request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by the MaxRecords parameter.
  --action: string@action-completer-59
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<EndpointAuthorizationList: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "Account" $account "scalar") (serialize-qp "Grantee" $grantee "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "Account": $account, "Grantee": $grantee, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Describes an endpoint authorization.
#
# POST /
# operationId: POST_DescribeEndpointAuthorization
export def "api create-get-endpoint-authorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-59
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<EndpointAuthorizationList: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Displays a list of event categories for all event source types, or for a specified source type. For a list of the event categories and source types, go to Amazon Redshift Event Notifications (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-event-notifications.html).
#
# GET /
# operationId: GET_DescribeEventCategories
export def "api get-event-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-type: string # The source type, such as cluster or parameter group, to which the described event categories apply. Valid values: cluster, cluster-snapshot, cluster-parameter-group, cluster-security-group, and scheduled-action.
  --action: string@action-completer-60
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<EventCategoriesMapList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SourceType" $source_type "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SourceType": $source_type, "Action": $action, "Version": $version} | compact), body: null}
}

# Displays a list of event categories for all event source types, or for a specified source type. For a list of the event categories and source types, go to Amazon Redshift Event Notifications (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-event-notifications.html).
#
# POST /
# operationId: POST_DescribeEventCategories
export def "api create-get-event-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-60
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<EventCategoriesMapList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Lists descriptions of all the Amazon Redshift event notification subscriptions for a customer account. If you specify a subscription name, lists the description for that subscription. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all event notification subscriptions that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all subscriptions that have any combination of those values are returned. If both tag keys and values are omitted from the request, subscriptions are returned regardless of whether they have tag keys or values associated with them.
#
# GET /
# operationId: GET_DescribeEventSubscriptions
export def "api get-event-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the Amazon Redshift event notification subscription to be described.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeEventSubscriptions request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --tag-keys: list # A tag key or keys for which you want to return all matching event notification subscriptions that are associated with the specified key or keys. For example, suppose that you have subscriptions that are tagged with keys called owner and environment. If you specify both of these tag keys in the request, Amazon Redshift returns a response with the subscriptions that have either or both of these tag keys associated with them.
  --tag-values: list # A tag value or values for which you want to return all matching event notification subscriptions that are associated with the specified tag value or values. For example, suppose that you have subscriptions that are tagged with values called admin and test. If you specify both of these tag values in the request, Amazon Redshift returns a response with the subscriptions that have either or both of these tag values associated with them.
  --action: string@action-completer-61
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, EventSubscriptionsList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SubscriptionName" $subscription_name "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "TagValues" $tag_values "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SubscriptionName": $subscription_name, "MaxRecords": $max_records, "Marker": $marker, "TagKeys": $tag_keys, "TagValues": $tag_values, "Action": $action, "Version": $version} | compact), body: null}
}

# Lists descriptions of all the Amazon Redshift event notification subscriptions for a customer account. If you specify a subscription name, lists the description for that subscription. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all event notification subscriptions that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all subscriptions that have any combination of those values are returned. If both tag keys and values are omitted from the request, subscriptions are returned regardless of whether they have tag keys or values associated with them.
#
# POST /
# operationId: POST_DescribeEventSubscriptions
export def "api create-get-event-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-61
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, EventSubscriptionsList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns events related to clusters, security groups, snapshots, and parameter groups for the past 14 days. Events specific to a particular cluster, security group, snapshot or parameter group can be obtained by providing the name as a parameter. By default, the past hour of events are returned.
#
# GET /
# operationId: GET_DescribeEvents
export def "api get-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-identifier: string # The identifier of the event source for which events will be returned. If this parameter is not specified, then all sources are included in the response. Constraints: If SourceIdentifier is supplied, SourceType must also be provided. Specify a cluster identifier when SourceType is cluster. Specify a cluster security group name when SourceType is cluster-security-group. Specify a cluster parameter group name when SourceType is cluster-parameter-group. Specify a cluster snapshot identifier when SourceType is cluster-snapshot.
  --source-type: string@source-type-completer # The event source to retrieve events for. If no value is specified, all events are returned. Constraints: If SourceType is supplied, SourceIdentifier must also be provided. Specify cluster when SourceIdentifier is a cluster identifier. Specify cluster-security-group when SourceIdentifier is a cluster security group name. Specify cluster-parameter-group when SourceIdentifier is a cluster parameter group name. Specify cluster-snapshot when SourceIdentifier is a cluster snapshot identifier.
  --start-time: string # The beginning of the time interval to retrieve events for, specified in ISO 8601 format. For more information about ISO 8601, go to the ISO8601 Wikipedia page. (http://en.wikipedia.org/wiki/ISO_8601) Example: 2009-07-08T18:00Z (format: date-time)
  --end-time: string # The end of the time interval for which to retrieve events, specified in ISO 8601 format. For more information about ISO 8601, go to the ISO8601 Wikipedia page. (http://en.wikipedia.org/wiki/ISO_8601) Example: 2009-07-08T18:00Z (format: date-time)
  --duration: int # The number of minutes prior to the time of the request for which to retrieve events. For example, if the request is sent at 18:00 and you specify a duration of 60, then only events which have occurred after 17:00 will be returned. Default: 60
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeEvents request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --action: string@action-completer-62
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, Events: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SourceIdentifier" $source_identifier "scalar") (serialize-qp "SourceType" $source_type "scalar") (serialize-qp "StartTime" $start_time "scalar") (serialize-qp "EndTime" $end_time "scalar") (serialize-qp "Duration" $duration "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SourceIdentifier": $source_identifier, "SourceType": $source_type, "StartTime": $start_time, "EndTime": $end_time, "Duration": $duration, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns events related to clusters, security groups, snapshots, and parameter groups for the past 14 days. Events specific to a particular cluster, security group, snapshot or parameter group can be obtained by providing the name as a parameter. By default, the past hour of events are returned.
#
# POST /
# operationId: POST_DescribeEvents
export def "api create-get-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-62
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, Events: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns information about the specified HSM client certificate. If no certificate ID is specified, returns information about all the HSM certificates owned by your Amazon Web Services account. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all HSM client certificates that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all HSM client certificates that have any combination of those values are returned. If both tag keys and values are omitted from the request, HSM client certificates are returned regardless of whether they have tag keys or values associated with them.
#
# GET /
# operationId: GET_DescribeHsmClientCertificates
export def "api get-hsm-client-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hsm-client-certificate-identifier: string # The identifier of a specific HSM client certificate for which you want information. If no identifier is specified, information is returned for all HSM client certificates owned by your Amazon Web Services account.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeHsmClientCertificates request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --tag-keys: list # A tag key or keys for which you want to return all matching HSM client certificates that are associated with the specified key or keys. For example, suppose that you have HSM client certificates that are tagged with keys called owner and environment. If you specify both of these tag keys in the request, Amazon Redshift returns a response with the HSM client certificates that have either or both of these tag keys associated with them.
  --tag-values: list # A tag value or values for which you want to return all matching HSM client certificates that are associated with the specified tag value or values. For example, suppose that you have HSM client certificates that are tagged with values called admin and test. If you specify both of these tag values in the request, Amazon Redshift returns a response with the HSM client certificates that have either or both of these tag values associated with them.
  --action: string@action-completer-63
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, HsmClientCertificates: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "HsmClientCertificateIdentifier" $hsm_client_certificate_identifier "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "TagValues" $tag_values "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"HsmClientCertificateIdentifier": $hsm_client_certificate_identifier, "MaxRecords": $max_records, "Marker": $marker, "TagKeys": $tag_keys, "TagValues": $tag_values, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns information about the specified HSM client certificate. If no certificate ID is specified, returns information about all the HSM certificates owned by your Amazon Web Services account. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all HSM client certificates that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all HSM client certificates that have any combination of those values are returned. If both tag keys and values are omitted from the request, HSM client certificates are returned regardless of whether they have tag keys or values associated with them.
#
# POST /
# operationId: POST_DescribeHsmClientCertificates
export def "api create-get-hsm-client-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-63
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, HsmClientCertificates: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns information about the specified Amazon Redshift HSM configuration. If no configuration ID is specified, returns information about all the HSM configurations owned by your Amazon Web Services account. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all HSM connections that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all HSM connections that have any combination of those values are returned. If both tag keys and values are omitted from the request, HSM connections are returned regardless of whether they have tag keys or values associated with them.
#
# GET /
# operationId: GET_DescribeHsmConfigurations
export def "api get-hsm-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hsm-configuration-identifier: string # The identifier of a specific Amazon Redshift HSM configuration to be described. If no identifier is specified, information is returned for all HSM configurations owned by your Amazon Web Services account.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeHsmConfigurations request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --tag-keys: list # A tag key or keys for which you want to return all matching HSM configurations that are associated with the specified key or keys. For example, suppose that you have HSM configurations that are tagged with keys called owner and environment. If you specify both of these tag keys in the request, Amazon Redshift returns a response with the HSM configurations that have either or both of these tag keys associated with them.
  --tag-values: list # A tag value or values for which you want to return all matching HSM configurations that are associated with the specified tag value or values. For example, suppose that you have HSM configurations that are tagged with values called admin and test. If you specify both of these tag values in the request, Amazon Redshift returns a response with the HSM configurations that have either or both of these tag values associated with them.
  --action: string@action-completer-64
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, HsmConfigurations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "HsmConfigurationIdentifier" $hsm_configuration_identifier "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "TagValues" $tag_values "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"HsmConfigurationIdentifier": $hsm_configuration_identifier, "MaxRecords": $max_records, "Marker": $marker, "TagKeys": $tag_keys, "TagValues": $tag_values, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns information about the specified Amazon Redshift HSM configuration. If no configuration ID is specified, returns information about all the HSM configurations owned by your Amazon Web Services account. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all HSM connections that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all HSM connections that have any combination of those values are returned. If both tag keys and values are omitted from the request, HSM connections are returned regardless of whether they have tag keys or values associated with them.
#
# POST /
# operationId: POST_DescribeHsmConfigurations
export def "api create-get-hsm-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-64
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, HsmConfigurations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Describes whether information, such as queries and connection attempts, is being logged for the specified Amazon Redshift cluster.
#
# GET /
# operationId: GET_DescribeLoggingStatus
export def "api get-logging-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The identifier of the cluster from which to get the logging status. Example: examplecluster
  --action: string@action-completer-65
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<LoggingEnabled: record, BucketName: record, S3KeyPrefix: record, LastSuccessfulDeliveryTime: record, LastFailureTime: record, LastFailureMessage: record, LogDestinationType: record, LogExports: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Describes whether information, such as queries and connection attempts, is being logged for the specified Amazon Redshift cluster.
#
# POST /
# operationId: POST_DescribeLoggingStatus
export def "api create-get-logging-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-65
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<LoggingEnabled: record, BucketName: record, S3KeyPrefix: record, LastSuccessfulDeliveryTime: record, LastFailureTime: record, LastFailureMessage: record, LogDestinationType: record, LogExports: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns properties of possible node configurations such as node type, number of nodes, and disk usage for the specified action type.
#
# GET /
# operationId: GET_DescribeNodeConfigurationOptions
export def "api get-node-configuration-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-type: string@action-type-completer # The action type to evaluate for possible node configurations. Specify "restore-cluster" to get configuration combinations based on an existing snapshot. Specify "recommend-node-config" to get configuration recommendations based on an existing cluster or snapshot. Specify "resize-cluster" to get configuration combinations for elastic resize based on an existing cluster.
  --cluster-identifier: string # The identifier of the cluster to evaluate for possible node configurations.
  --snapshot-identifier: string # The identifier of the snapshot to evaluate for possible node configurations.
  --snapshot-arn: string # The Amazon Resource Name (ARN) of the snapshot associated with the message to describe node configuration.
  --owner-account: string # The Amazon Web Services account used to create or copy the snapshot. Required if you are restoring a snapshot you do not own, optional if you own the snapshot.
  --filter: list # A set of name, operator, and value items to filter the results.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeNodeConfigurationOptions request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 500 Constraints: minimum 100, maximum 500.
  --action: string@action-completer-66
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NodeConfigurationOptionList: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ActionType" $action_type "scalar") (serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "SnapshotIdentifier" $snapshot_identifier "scalar") (serialize-qp "SnapshotArn" $snapshot_arn "scalar") (serialize-qp "OwnerAccount" $owner_account "scalar") (serialize-qp "Filter" $filter "multi") (serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ActionType": $action_type, "ClusterIdentifier": $cluster_identifier, "SnapshotIdentifier": $snapshot_identifier, "SnapshotArn": $snapshot_arn, "OwnerAccount": $owner_account, "Filter": $filter, "Marker": $marker, "MaxRecords": $max_records, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns properties of possible node configurations such as node type, number of nodes, and disk usage for the specified action type.
#
# POST /
# operationId: POST_DescribeNodeConfigurationOptions
export def "api create-get-node-configuration-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-66
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<NodeConfigurationOptionList: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a list of orderable cluster options. Before you create a new cluster you can use this operation to find what options are available, such as the EC2 Availability Zones (AZ) in the specific Amazon Web Services Region that you can specify, and the node types you can request. The node types differ by available storage, memory, CPU and price. With the cost involved you might want to obtain a list of cluster options in the specific region and specify values when creating a cluster. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_DescribeOrderableClusterOptions
export def "api get-orderable-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-version: string # The version filter value. Specify this parameter to show only the available offerings matching the specified version. Default: All versions. Constraints: Must be one of the version returned from DescribeClusterVersions.
  --node-type: string # The node type filter value. Specify this parameter to show only the available offerings matching the specified node type.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeOrderableClusterOptions request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --action: string@action-completer-67
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<OrderableClusterOptions: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterVersion" $cluster_version "scalar") (serialize-qp "NodeType" $node_type "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterVersion": $cluster_version, "NodeType": $node_type, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a list of orderable cluster options. Before you create a new cluster you can use this operation to find what options are available, such as the EC2 Availability Zones (AZ) in the specific Amazon Web Services Region that you can specify, and the node types you can request. The node types differ by available storage, memory, CPU and price. With the cost involved you might want to obtain a list of cluster options in the specific region and specify values when creating a cluster. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_DescribeOrderableClusterOptions
export def "api create-get-orderable-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-67
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<OrderableClusterOptions: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns information about the partner integrations defined for a cluster.
#
# GET /
# operationId: GET_DescribePartners
export def "api get-partners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The Amazon Web Services account ID that owns the cluster.
  --cluster-identifier: string # The cluster identifier of the cluster whose partner integration is being described.
  --database-name: string # The name of the database whose partner integration is being described. If database name is not specified, then all databases in the cluster are described.
  --partner-name: string # The name of the partner that is being described. If partner name is not specified, then all partner integrations are described.
  --action: string@action-completer-68
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<PartnerIntegrationInfoList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AccountId" $account_id "scalar") (serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "DatabaseName" $database_name "scalar") (serialize-qp "PartnerName" $partner_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AccountId": $account_id, "ClusterIdentifier": $cluster_identifier, "DatabaseName": $database_name, "PartnerName": $partner_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns information about the partner integrations defined for a cluster.
#
# POST /
# operationId: POST_DescribePartners
export def "api create-get-partners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-68
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<PartnerIntegrationInfoList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns exchange status details and associated metadata for a reserved-node exchange. Statuses include such values as in progress and requested.
#
# GET /
# operationId: GET_DescribeReservedNodeExchangeStatus
export def "api get-reserved-node-exchange-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reserved-node-id: string # The identifier of the source reserved node in a reserved-node exchange request.
  --reserved-node-exchange-request-id: string # The identifier of the reserved-node exchange request.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a Marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value.
  --marker: string # An optional pagination token provided by a previous DescribeReservedNodeExchangeStatus request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by the MaxRecords parameter. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --action: string@action-completer-69
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ReservedNodeExchangeStatusDetails: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ReservedNodeId" $reserved_node_id "scalar") (serialize-qp "ReservedNodeExchangeRequestId" $reserved_node_exchange_request_id "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ReservedNodeId": $reserved_node_id, "ReservedNodeExchangeRequestId": $reserved_node_exchange_request_id, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns exchange status details and associated metadata for a reserved-node exchange. Statuses include such values as in progress and requested.
#
# POST /
# operationId: POST_DescribeReservedNodeExchangeStatus
export def "api create-get-reserved-node-exchange-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-69
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ReservedNodeExchangeStatusDetails: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a list of the available reserved node offerings by Amazon Redshift with their descriptions including the node type, the fixed and recurring costs of reserving the node and duration the node will be reserved for you. These descriptions help you determine which reserve node offering you want to purchase. You then use the unique offering ID in you call to PurchaseReservedNodeOffering to reserve one or more nodes for your Amazon Redshift cluster. For more information about reserved node offerings, go to Purchasing Reserved Nodes (https://docs.aws.amazon.com/redshift/latest/mgmt/purchase-reserved-node-instance.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_DescribeReservedNodeOfferings
export def "api get-reserved-node-offerings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reserved-node-offering-id: string # The unique identifier for the offering.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeReservedNodeOfferings request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --action: string@action-completer-70
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, ReservedNodeOfferings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ReservedNodeOfferingId" $reserved_node_offering_id "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ReservedNodeOfferingId": $reserved_node_offering_id, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a list of the available reserved node offerings by Amazon Redshift with their descriptions including the node type, the fixed and recurring costs of reserving the node and duration the node will be reserved for you. These descriptions help you determine which reserve node offering you want to purchase. You then use the unique offering ID in you call to PurchaseReservedNodeOffering to reserve one or more nodes for your Amazon Redshift cluster. For more information about reserved node offerings, go to Purchasing Reserved Nodes (https://docs.aws.amazon.com/redshift/latest/mgmt/purchase-reserved-node-instance.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_DescribeReservedNodeOfferings
export def "api create-get-reserved-node-offerings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-70
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, ReservedNodeOfferings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns the descriptions of the reserved nodes.
#
# GET /
# operationId: GET_DescribeReservedNodes
export def "api get-reserved-nodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reserved-node-id: string # Identifier for the node reservation.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeReservedNodes request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --action: string@action-completer-71
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, ReservedNodes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ReservedNodeId" $reserved_node_id "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ReservedNodeId": $reserved_node_id, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns the descriptions of the reserved nodes.
#
# POST /
# operationId: POST_DescribeReservedNodes
export def "api create-get-reserved-nodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-71
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, ReservedNodes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns information about the last resize operation for the specified cluster. If no resize operation has ever been initiated for the specified cluster, a HTTP 404 error is returned. If a resize operation was initiated and completed, the status of the resize remains as SUCCEEDED until the next resize. A resize operation can be requested using ModifyCluster and specifying a different number or type of nodes for the cluster.
#
# GET /
# operationId: GET_DescribeResize
export def "api get-resize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The unique identifier of a cluster whose resize progress you are requesting. This parameter is case-sensitive. By default, resize operations for all clusters defined for an Amazon Web Services account are returned.
  --action: string@action-completer-72
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TargetNodeType: record, TargetNumberOfNodes: record, TargetClusterType: record, Status: record, ImportTablesCompleted: record, ImportTablesInProgress: record, ImportTablesNotStarted: record, AvgResizeRateInMegaBytesPerSecond: record, TotalResizeDataInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record, ResizeType: record, Message: record, TargetEncryptionType: record, DataTransferProgressPercent: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns information about the last resize operation for the specified cluster. If no resize operation has ever been initiated for the specified cluster, a HTTP 404 error is returned. If a resize operation was initiated and completed, the status of the resize remains as SUCCEEDED until the next resize. A resize operation can be requested using ModifyCluster and specifying a different number or type of nodes for the cluster.
#
# POST /
# operationId: POST_DescribeResize
export def "api create-get-resize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-72
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<TargetNodeType: record, TargetNumberOfNodes: record, TargetClusterType: record, Status: record, ImportTablesCompleted: record, ImportTablesInProgress: record, ImportTablesNotStarted: record, AvgResizeRateInMegaBytesPerSecond: record, TotalResizeDataInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record, ResizeType: record, Message: record, TargetEncryptionType: record, DataTransferProgressPercent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Describes properties of scheduled actions.
#
# GET /
# operationId: GET_DescribeScheduledActions
export def "api get-scheduled-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scheduled-action-name: string # The name of the scheduled action to retrieve.
  --target-action-type: string@target-action-type-completer # The type of the scheduled actions to retrieve.
  --start-time: string # The start time in UTC of the scheduled actions to retrieve. Only active scheduled actions that have invocations after this time are retrieved. (format: date-time)
  --end-time: string # The end time in UTC of the scheduled action to retrieve. Only active scheduled actions that have invocations before this time are retrieved. (format: date-time)
  --active: oneof<nothing, bool> # If true, retrieve only active scheduled actions. If false, retrieve only disabled scheduled actions.
  --filters: list # List of scheduled action filters.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeScheduledActions request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --action: string@action-completer-73
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, ScheduledActions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ScheduledActionName" $scheduled_action_name "scalar") (serialize-qp "TargetActionType" $target_action_type "scalar") (serialize-qp "StartTime" $start_time "scalar") (serialize-qp "EndTime" $end_time "scalar") (serialize-qp "Active" $active "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ScheduledActionName": $scheduled_action_name, "TargetActionType": $target_action_type, "StartTime": $start_time, "EndTime": $end_time, "Active": $active, "Filters": $filters, "Marker": $marker, "MaxRecords": $max_records, "Action": $action, "Version": $version} | compact), body: null}
}

# Describes properties of scheduled actions.
#
# POST /
# operationId: POST_DescribeScheduledActions
export def "api create-get-scheduled-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-73
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, ScheduledActions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a list of snapshot copy grants owned by the Amazon Web Services account in the destination region. For more information about managing snapshot copy grants, go to Amazon Redshift Database Encryption (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-db-encryption.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_DescribeSnapshotCopyGrants
export def "api get-snapshot-copy-grants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-copy-grant-name: string # The name of the snapshot copy grant.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeSnapshotCopyGrant request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request. Constraints: You can specify either the SnapshotCopyGrantName parameter or the Marker parameter, but not both.
  --tag-keys: list # A tag key or keys for which you want to return all matching resources that are associated with the specified key or keys. For example, suppose that you have resources tagged with keys called owner and environment. If you specify both of these tag keys in the request, Amazon Redshift returns a response with all resources that have either or both of these tag keys associated with them.
  --tag-values: list # A tag value or values for which you want to return all matching resources that are associated with the specified value or values. For example, suppose that you have resources tagged with values called admin and test. If you specify both of these tag values in the request, Amazon Redshift returns a response with all resources that have either or both of these tag values associated with them.
  --action: string@action-completer-74
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, SnapshotCopyGrants: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SnapshotCopyGrantName" $snapshot_copy_grant_name "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "TagValues" $tag_values "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SnapshotCopyGrantName": $snapshot_copy_grant_name, "MaxRecords": $max_records, "Marker": $marker, "TagKeys": $tag_keys, "TagValues": $tag_values, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a list of snapshot copy grants owned by the Amazon Web Services account in the destination region. For more information about managing snapshot copy grants, go to Amazon Redshift Database Encryption (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-db-encryption.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_DescribeSnapshotCopyGrants
export def "api create-get-snapshot-copy-grants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-74
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, SnapshotCopyGrants: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a list of snapshot schedules.
#
# GET /
# operationId: GET_DescribeSnapshotSchedules
export def "api get-snapshot-schedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The unique identifier for the cluster whose snapshot schedules you want to view.
  --schedule-identifier: string # A unique identifier for a snapshot schedule.
  --tag-keys: list # The key value for a snapshot schedule tag.
  --tag-values: list # The value corresponding to the key of the snapshot schedule tag.
  --marker: string # A value that indicates the starting point for the next set of response records in a subsequent request. If a value is returned in a response, you can retrieve the next set of records by providing this returned marker value in the marker parameter and retrying the command. If the marker field is empty, all response records have been retrieved for the request.
  --max-records: int # The maximum number or response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value.
  --action: string@action-completer-75
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<SnapshotSchedules: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "ScheduleIdentifier" $schedule_identifier "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "TagValues" $tag_values "multi") (serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "ScheduleIdentifier": $schedule_identifier, "TagKeys": $tag_keys, "TagValues": $tag_values, "Marker": $marker, "MaxRecords": $max_records, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a list of snapshot schedules.
#
# POST /
# operationId: POST_DescribeSnapshotSchedules
export def "api create-get-snapshot-schedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-75
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<SnapshotSchedules: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns account level backups storage size and provisional storage.
#
# GET /
# operationId: GET_DescribeStorage
export def "api get-storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-76
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TotalBackupSizeInMegaBytes: record, TotalProvisionedStorageInMegaBytes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Returns account level backups storage size and provisional storage.
#
# POST /
# operationId: POST_DescribeStorage
export def "api create-get-storage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-76
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TotalBackupSizeInMegaBytes: record, TotalProvisionedStorageInMegaBytes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Lists the status of one or more table restore requests made using the RestoreTableFromClusterSnapshot API action. If you don't specify a value for the TableRestoreRequestId parameter, then DescribeTableRestoreStatus returns the status of all table restore requests ordered by the date and time of the request in ascending order. Otherwise DescribeTableRestoreStatus returns the status of the table specified by TableRestoreRequestId.
#
# GET /
# operationId: GET_DescribeTableRestoreStatus
export def "api get-table-restore-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The Amazon Redshift cluster that the table is being restored to.
  --table-restore-request-id: string # The identifier of the table restore request to return status for. If you don't specify a TableRestoreRequestId value, then DescribeTableRestoreStatus returns the status of all in-progress table restore requests.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.
  --marker: string # An optional pagination token provided by a previous DescribeTableRestoreStatus request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by the MaxRecords parameter.
  --action: string@action-completer-77
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TableRestoreStatusDetails: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "TableRestoreRequestId" $table_restore_request_id "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "TableRestoreRequestId": $table_restore_request_id, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Lists the status of one or more table restore requests made using the RestoreTableFromClusterSnapshot API action. If you don't specify a value for the TableRestoreRequestId parameter, then DescribeTableRestoreStatus returns the status of all table restore requests ordered by the date and time of the request in ascending order. Otherwise DescribeTableRestoreStatus returns the status of the table specified by TableRestoreRequestId.
#
# POST /
# operationId: POST_DescribeTableRestoreStatus
export def "api create-get-table-restore-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-77
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<TableRestoreStatusDetails: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a list of tags. You can return tags from a specific resource by specifying an ARN, or you can return all tags for a given type of resource, such as clusters, snapshots, and so on. The following are limitations for DescribeTags: You cannot specify an ARN and a resource-type value together in the same request. You cannot use the MaxRecords and Marker parameters together with the ARN parameter. The MaxRecords parameter can be a range from 10 to 50 results to return in a request. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all resources that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all resources that have any combination of those values are returned. If both tag keys and values are omitted from the request, resources are returned regardless of whether they have tag keys or values associated with them.
#
# GET /
# operationId: GET_DescribeTags
export def "api get-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-name: string # The Amazon Resource Name (ARN) for which you want to describe the tag or tags. For example, arn:aws:redshift:us-east-2:123456789:cluster:t1.
  --resource-type: string # The type of resource with which you want to view tags. Valid resource types are: Cluster CIDR/IP EC2 security group Snapshot Cluster security group Subnet group HSM connection HSM certificate Parameter group Snapshot copy grant For more information about Amazon Redshift resource types and constructing ARNs, go to Specifying Policy Elements: Actions, Effects, Resources, and Principals (https://docs.aws.amazon.com/redshift/latest/mgmt/redshift-iam-access-control-overview.html#redshift-iam-access-control-specify-actions) in the Amazon Redshift Cluster Management Guide.
  --max-records: int # The maximum number or response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value.
  --marker: string # A value that indicates the starting point for the next set of response records in a subsequent request. If a value is returned in a response, you can retrieve the next set of records by providing this returned marker value in the marker parameter and retrying the command. If the marker field is empty, all response records have been retrieved for the request.
  --tag-keys: list # A tag key or keys for which you want to return all matching resources that are associated with the specified key or keys. For example, suppose that you have resources tagged with keys called owner and environment. If you specify both of these tag keys in the request, Amazon Redshift returns a response with all resources that have either or both of these tag keys associated with them.
  --tag-values: list # A tag value or values for which you want to return all matching resources that are associated with the specified value or values. For example, suppose that you have resources tagged with values called admin and test. If you specify both of these tag values in the request, Amazon Redshift returns a response with all resources that have either or both of these tag values associated with them.
  --action: string@action-completer-78
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TaggedResources: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ResourceName" $resource_name "scalar") (serialize-qp "ResourceType" $resource_type "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "TagValues" $tag_values "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ResourceName": $resource_name, "ResourceType": $resource_type, "MaxRecords": $max_records, "Marker": $marker, "TagKeys": $tag_keys, "TagValues": $tag_values, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a list of tags. You can return tags from a specific resource by specifying an ARN, or you can return all tags for a given type of resource, such as clusters, snapshots, and so on. The following are limitations for DescribeTags: You cannot specify an ARN and a resource-type value together in the same request. You cannot use the MaxRecords and Marker parameters together with the ARN parameter. The MaxRecords parameter can be a range from 10 to 50 results to return in a request. If you specify both tag keys and tag values in the same request, Amazon Redshift returns all resources that match any combination of the specified keys and values. For example, if you have owner and environment for tag keys, and admin and test for tag values, all resources that have any combination of those values are returned. If both tag keys and values are omitted from the request, resources are returned regardless of whether they have tag keys or values associated with them.
#
# POST /
# operationId: POST_DescribeTags
export def "api create-get-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-78
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<TaggedResources: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Shows usage limits on a cluster. Results are filtered based on the combination of input usage limit identifier, cluster identifier, and feature type parameters: If usage limit identifier, cluster identifier, and feature type are not provided, then all usage limit objects for the current account in the current region are returned. If usage limit identifier is provided, then the corresponding usage limit object is returned. If cluster identifier is provided, then all usage limit objects for the specified cluster are returned. If cluster identifier and feature type are provided, then all usage limit objects for the combination of cluster and feature are returned.
#
# GET /
# operationId: GET_DescribeUsageLimits
export def "api get-usage-limits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --usage-limit-id: string # The identifier of the usage limit to describe.
  --cluster-identifier: string # The identifier of the cluster for which you want to describe usage limits.
  --feature-type: string@feature-type-completer # The feature type for which you want to describe usage limits.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value. Default: 100 Constraints: minimum 20, maximum 100.
  --marker: string # An optional parameter that specifies the starting point to return a set of response records. When the results of a DescribeUsageLimits request exceed the value specified in MaxRecords, Amazon Web Services returns a value in the Marker field of the response. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --tag-keys: list # A tag key or keys for which you want to return all matching usage limit objects that are associated with the specified key or keys. For example, suppose that you have parameter groups that are tagged with keys called owner and environment. If you specify both of these tag keys in the request, Amazon Redshift returns a response with the usage limit objects have either or both of these tag keys associated with them.
  --tag-values: list # A tag value or values for which you want to return all matching usage limit objects that are associated with the specified tag value or values. For example, suppose that you have parameter groups that are tagged with values called admin and test. If you specify both of these tag values in the request, Amazon Redshift returns a response with the usage limit objects that have either or both of these tag values associated with them.
  --action: string@action-completer-79
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<UsageLimits: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UsageLimitId" $usage_limit_id "scalar") (serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "FeatureType" $feature_type "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "TagValues" $tag_values "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"UsageLimitId": $usage_limit_id, "ClusterIdentifier": $cluster_identifier, "FeatureType": $feature_type, "MaxRecords": $max_records, "Marker": $marker, "TagKeys": $tag_keys, "TagValues": $tag_values, "Action": $action, "Version": $version} | compact), body: null}
}

# Shows usage limits on a cluster. Results are filtered based on the combination of input usage limit identifier, cluster identifier, and feature type parameters: If usage limit identifier, cluster identifier, and feature type are not provided, then all usage limit objects for the current account in the current region are returned. If usage limit identifier is provided, then the corresponding usage limit object is returned. If cluster identifier is provided, then all usage limit objects for the specified cluster are returned. If cluster identifier and feature type are provided, then all usage limit objects for the combination of cluster and feature are returned.
#
# POST /
# operationId: POST_DescribeUsageLimits
export def "api create-get-usage-limits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-79
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<UsageLimits: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Stops logging information, such as queries and connection attempts, for the specified Amazon Redshift cluster.
#
# GET /
# operationId: GET_DisableLogging
export def "api get-disable-logging" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The identifier of the cluster on which logging is to be stopped. Example: examplecluster
  --action: string@action-completer-80
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<LoggingEnabled: record, BucketName: record, S3KeyPrefix: record, LastSuccessfulDeliveryTime: record, LastFailureTime: record, LastFailureMessage: record, LogDestinationType: record, LogExports: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Stops logging information, such as queries and connection attempts, for the specified Amazon Redshift cluster.
#
# POST /
# operationId: POST_DisableLogging
export def "api create-disable-logging" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-80
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<LoggingEnabled: record, BucketName: record, S3KeyPrefix: record, LastSuccessfulDeliveryTime: record, LastFailureTime: record, LastFailureMessage: record, LogDestinationType: record, LogExports: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Disables the automatic copying of snapshots from one region to another region for a specified cluster. If your cluster and its snapshots are encrypted using an encrypted symmetric key from Key Management Service, use DeleteSnapshotCopyGrant to delete the grant that grants Amazon Redshift permission to the key in the destination region.
#
# GET /
# operationId: GET_DisableSnapshotCopy
export def "api get-disable-snapshot-copy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The unique identifier of the source cluster that you want to disable copying of snapshots to a destination region. Constraints: Must be the valid name of an existing cluster that has cross-region snapshot copy enabled.
  --action: string@action-completer-81
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Disables the automatic copying of snapshots from one region to another region for a specified cluster. If your cluster and its snapshots are encrypted using an encrypted symmetric key from Key Management Service, use DeleteSnapshotCopyGrant to delete the grant that grants Amazon Redshift permission to the key in the destination region.
#
# POST /
# operationId: POST_DisableSnapshotCopy
export def "api create-disable-snapshot-copy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-81
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# From a datashare consumer account, remove association for the specified datashare.
#
# GET /
# operationId: GET_DisassociateDataShareConsumer
export def "api get-disassociate-data-share-consumer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-share-arn: string # The Amazon Resource Name (ARN) of the datashare to remove association for.
  --disassociate-entire-account: oneof<nothing, bool> # A value that specifies whether association for the datashare is removed from the entire account.
  --consumer-arn: string # The Amazon Resource Name (ARN) of the consumer that association for the datashare is removed from.
  --consumer-region: string # From a datashare consumer account, removes association of a datashare from all the existing and future namespaces in the specified Amazon Web Services Region.
  --action: string@action-completer-82
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DataShareArn: record, ProducerArn: record, AllowPubliclyAccessibleConsumers: record, DataShareAssociations: record, ManagedBy: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DataShareArn" $data_share_arn "scalar") (serialize-qp "DisassociateEntireAccount" $disassociate_entire_account "scalar") (serialize-qp "ConsumerArn" $consumer_arn "scalar") (serialize-qp "ConsumerRegion" $consumer_region "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"DataShareArn": $data_share_arn, "DisassociateEntireAccount": $disassociate_entire_account, "ConsumerArn": $consumer_arn, "ConsumerRegion": $consumer_region, "Action": $action, "Version": $version} | compact), body: null}
}

# From a datashare consumer account, remove association for the specified datashare.
#
# POST /
# operationId: POST_DisassociateDataShareConsumer
export def "api create-disassociate-data-share-consumer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-82
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DataShareArn: record, ProducerArn: record, AllowPubliclyAccessibleConsumers: record, DataShareAssociations: record, ManagedBy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Starts logging information, such as queries and connection attempts, for the specified Amazon Redshift cluster.
#
# GET /
# operationId: GET_EnableLogging
export def "api get-enable-logging" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The identifier of the cluster on which logging is to be started. Example: examplecluster
  --bucket-name: string # The name of an existing S3 bucket where the log files are to be stored. Constraints: Must be in the same region as the cluster The cluster must have read bucket and put object permissions
  --s3-key-prefix: string # The prefix applied to the log file names. Constraints: Cannot exceed 512 characters Cannot contain spaces( ), double quotes ("), single quotes ('), a backslash (\), or control characters. The hexadecimal codes for invalid characters are: x00 to x20 x22 x27 x5c x7f or larger
  --log-destination-type: string@log-destination-type-completer # The log destination type. An enum with possible values of s3 and cloudwatch.
  --log-exports: list # The collection of exported log types. Possible values are connectionlog, useractivitylog, and userlog.
  --action: string@action-completer-83
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<LoggingEnabled: record, BucketName: record, S3KeyPrefix: record, LastSuccessfulDeliveryTime: record, LastFailureTime: record, LastFailureMessage: record, LogDestinationType: record, LogExports: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "BucketName" $bucket_name "scalar") (serialize-qp "S3KeyPrefix" $s3_key_prefix "scalar") (serialize-qp "LogDestinationType" $log_destination_type "scalar") (serialize-qp "LogExports" $log_exports "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "BucketName": $bucket_name, "S3KeyPrefix": $s3_key_prefix, "LogDestinationType": $log_destination_type, "LogExports": $log_exports, "Action": $action, "Version": $version} | compact), body: null}
}

# Starts logging information, such as queries and connection attempts, for the specified Amazon Redshift cluster.
#
# POST /
# operationId: POST_EnableLogging
export def "api create-enable-logging" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-83
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<LoggingEnabled: record, BucketName: record, S3KeyPrefix: record, LastSuccessfulDeliveryTime: record, LastFailureTime: record, LastFailureMessage: record, LogDestinationType: record, LogExports: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Enables the automatic copy of snapshots from one region to another region for a specified cluster.
#
# GET /
# operationId: GET_EnableSnapshotCopy
export def "api get-enable-snapshot-copy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The unique identifier of the source cluster to copy snapshots from. Constraints: Must be the valid name of an existing cluster that does not already have cross-region snapshot copy enabled.
  --destination-region: string # The destination Amazon Web Services Region that you want to copy snapshots to. Constraints: Must be the name of a valid Amazon Web Services Region. For more information, see Regions and Endpoints (https://docs.aws.amazon.com/general/latest/gr/rande.html#redshift_region) in the Amazon Web Services General Reference.
  --retention-period: int # The number of days to retain automated snapshots in the destination region after they are copied from the source region. Default: 7. Constraints: Must be at least 1 and no more than 35.
  --snapshot-copy-grant-name: string # The name of the snapshot copy grant to use when snapshots of an Amazon Web Services KMS-encrypted cluster are copied to the destination region.
  --manual-snapshot-retention-period: int # The number of days to retain newly copied snapshots in the destination Amazon Web Services Region after they are copied from the source Amazon Web Services Region. If the value is -1, the manual snapshot is retained indefinitely. The value must be either -1 or an integer between 1 and 3,653.
  --action: string@action-completer-84
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "DestinationRegion" $destination_region "scalar") (serialize-qp "RetentionPeriod" $retention_period "scalar") (serialize-qp "SnapshotCopyGrantName" $snapshot_copy_grant_name "scalar") (serialize-qp "ManualSnapshotRetentionPeriod" $manual_snapshot_retention_period "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "DestinationRegion": $destination_region, "RetentionPeriod": $retention_period, "SnapshotCopyGrantName": $snapshot_copy_grant_name, "ManualSnapshotRetentionPeriod": $manual_snapshot_retention_period, "Action": $action, "Version": $version} | compact), body: null}
}

# Enables the automatic copy of snapshots from one region to another region for a specified cluster.
#
# POST /
# operationId: POST_EnableSnapshotCopy
export def "api create-enable-snapshot-copy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-84
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a database user name and temporary password with temporary authorization to log on to an Amazon Redshift database. The action returns the database user name prefixed with IAM: if AutoCreate is False or IAMA: if AutoCreate is True. You can optionally specify one or more database user groups that the user will join at log on. By default, the temporary credentials expire in 900 seconds. You can optionally specify a duration between 900 seconds (15 minutes) and 3600 seconds (60 minutes). For more information, see Using IAM Authentication to Generate Database User Credentials (https://docs.aws.amazon.com/redshift/latest/mgmt/generating-user-credentials.html) in the Amazon Redshift Cluster Management Guide. The Identity and Access Management (IAM) user or role that runs GetClusterCredentials must have an IAM policy attached that allows access to all necessary actions and resources. For more information about permissions, see Resource Policies for GetClusterCredentials (https://docs.aws.amazon.com/redshift/latest/mgmt/redshift-iam-access-control-identity-based.html#redshift-policy-resources.getclustercredentials-resources) in the Amazon Redshift Cluster Management Guide. If the DbGroups parameter is specified, the IAM policy must allow the redshift:JoinGroup action with access to the listed dbgroups. In addition, if the AutoCreate parameter is set to True, then the policy must include the redshift:CreateClusterUser permission. If the DbName parameter is specified, the IAM policy must allow access to the resource dbname for the specified database name.
#
# GET /
# operationId: GET_GetClusterCredentials
export def "api get-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-user: string # The name of a database user. If a user name matching DbUser exists in the database, the temporary user credentials have the same permissions as the existing user. If DbUser doesn't exist in the database and Autocreate is True, a new user is created using the value for DbUser with PUBLIC permissions. If a database user matching the value for DbUser doesn't exist and Autocreate is False, then the command succeeds but the connection attempt will fail because the user doesn't exist in the database. For more information, see CREATE USER (https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_USER.html) in the Amazon Redshift Database Developer Guide. Constraints: Must be 1 to 64 alphanumeric characters or hyphens. The user name can't be PUBLIC. Must contain uppercase or lowercase letters, numbers, underscore, plus sign, period (dot), at symbol (@), or hyphen. First character must be a letter. Must not contain a colon ( : ) or slash ( / ). Cannot be a reserved word. A list of reserved words can be found in Reserved Words (http://docs.aws.amazon.com/redshift/latest/dg/r_pg_keywords.html) in the Amazon Redshift Database Developer Guide.
  --db-name: string # The name of a database that DbUser is authorized to log on to. If DbName is not specified, DbUser can log on to any existing database. Constraints: Must be 1 to 64 alphanumeric characters or hyphens Must contain uppercase or lowercase letters, numbers, underscore, plus sign, period (dot), at symbol (@), or hyphen. First character must be a letter. Must not contain a colon ( : ) or slash ( / ). Cannot be a reserved word. A list of reserved words can be found in Reserved Words (http://docs.aws.amazon.com/redshift/latest/dg/r_pg_keywords.html) in the Amazon Redshift Database Developer Guide.
  --cluster-identifier: string # The unique identifier of the cluster that contains the database for which you are requesting credentials. This parameter is case sensitive.
  --duration-seconds: int # The number of seconds until the returned temporary password expires. Constraint: minimum 900, maximum 3600. Default: 900
  --auto-create: oneof<nothing, bool> # Create a database user with the name specified for the user named in DbUser if one does not exist.
  --db-groups: list # A list of the names of existing database groups that the user named in DbUser will join for the current session, in addition to any group memberships for an existing user. If not specified, a new user is added only to PUBLIC. Database group name constraints Must be 1 to 64 alphanumeric characters or hyphens Must contain only lowercase letters, numbers, underscore, plus sign, period (dot), at symbol (@), or hyphen. First character must be a letter. Must not contain a colon ( : ) or slash ( / ). Cannot be a reserved word. A list of reserved words can be found in Reserved Words (http://docs.aws.amazon.com/redshift/latest/dg/r_pg_keywords.html) in the Amazon Redshift Database Developer Guide.
  --action: string@action-completer-85
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DbUser: record, DbPassword: record, Expiration: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DbUser" $db_user "scalar") (serialize-qp "DbName" $db_name "scalar") (serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "DurationSeconds" $duration_seconds "scalar") (serialize-qp "AutoCreate" $auto_create "scalar") (serialize-qp "DbGroups" $db_groups "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"DbUser": $db_user, "DbName": $db_name, "ClusterIdentifier": $cluster_identifier, "DurationSeconds": $duration_seconds, "AutoCreate": $auto_create, "DbGroups": $db_groups, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a database user name and temporary password with temporary authorization to log on to an Amazon Redshift database. The action returns the database user name prefixed with IAM: if AutoCreate is False or IAMA: if AutoCreate is True. You can optionally specify one or more database user groups that the user will join at log on. By default, the temporary credentials expire in 900 seconds. You can optionally specify a duration between 900 seconds (15 minutes) and 3600 seconds (60 minutes). For more information, see Using IAM Authentication to Generate Database User Credentials (https://docs.aws.amazon.com/redshift/latest/mgmt/generating-user-credentials.html) in the Amazon Redshift Cluster Management Guide. The Identity and Access Management (IAM) user or role that runs GetClusterCredentials must have an IAM policy attached that allows access to all necessary actions and resources. For more information about permissions, see Resource Policies for GetClusterCredentials (https://docs.aws.amazon.com/redshift/latest/mgmt/redshift-iam-access-control-identity-based.html#redshift-policy-resources.getclustercredentials-resources) in the Amazon Redshift Cluster Management Guide. If the DbGroups parameter is specified, the IAM policy must allow the redshift:JoinGroup action with access to the listed dbgroups. In addition, if the AutoCreate parameter is set to True, then the policy must include the redshift:CreateClusterUser permission. If the DbName parameter is specified, the IAM policy must allow access to the resource dbname for the specified database name.
#
# POST /
# operationId: POST_GetClusterCredentials
export def "api create-get-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-85
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DbUser: record, DbPassword: record, Expiration: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a database user name and temporary password with temporary authorization to log in to an Amazon Redshift database. The database user is mapped 1:1 to the source Identity and Access Management (IAM) identity. For more information about IAM identities, see IAM Identities (users, user groups, and roles) (https://docs.aws.amazon.com/IAM/latest/UserGuide/id.html) in the Amazon Web Services Identity and Access Management User Guide. The Identity and Access Management (IAM) identity that runs this operation must have an IAM policy attached that allows access to all necessary actions and resources. For more information about permissions, see Using identity-based policies (IAM policies) (https://docs.aws.amazon.com/redshift/latest/mgmt/redshift-iam-access-control-identity-based.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_GetClusterCredentialsWithIAM
export def "api get-credentials-with-iam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-name: string # The name of the database for which you are requesting credentials. If the database name is specified, the IAM policy must allow access to the resource dbname for the specified database name. If the database name is not specified, access to all databases is allowed.
  --cluster-identifier: string # The unique identifier of the cluster that contains the database for which you are requesting credentials.
  --duration-seconds: int # The number of seconds until the returned temporary password expires. Range: 900-3600. Default: 900.
  --action: string@action-completer-86
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DbUser: record, DbPassword: record, Expiration: record, NextRefreshTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DbName" $db_name "scalar") (serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "DurationSeconds" $duration_seconds "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"DbName": $db_name, "ClusterIdentifier": $cluster_identifier, "DurationSeconds": $duration_seconds, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a database user name and temporary password with temporary authorization to log in to an Amazon Redshift database. The database user is mapped 1:1 to the source Identity and Access Management (IAM) identity. For more information about IAM identities, see IAM Identities (users, user groups, and roles) (https://docs.aws.amazon.com/IAM/latest/UserGuide/id.html) in the Amazon Web Services Identity and Access Management User Guide. The Identity and Access Management (IAM) identity that runs this operation must have an IAM policy attached that allows access to all necessary actions and resources. For more information about permissions, see Using identity-based policies (IAM policies) (https://docs.aws.amazon.com/redshift/latest/mgmt/redshift-iam-access-control-identity-based.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_GetClusterCredentialsWithIAM
export def "api create-get-credentials-with-iam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-86
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DbUser: record, DbPassword: record, Expiration: record, NextRefreshTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Gets the configuration options for the reserved-node exchange. These options include information about the source reserved node and target reserved node offering. Details include the node type, the price, the node count, and the offering type.
#
# GET /
# operationId: GET_GetReservedNodeExchangeConfigurationOptions
export def "api get-reserved-node-exchange-configuration-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-type: string@action-type-completer-1 # The action type of the reserved-node configuration. The action type can be an exchange initiated from either a snapshot or a resize.
  --cluster-identifier: string # The identifier for the cluster that is the source for a reserved-node exchange.
  --snapshot-identifier: string # The identifier for the snapshot that is the source for the reserved-node exchange.
  --max-records: int # The maximum number of response records to return in each call. If the number of remaining response records exceeds the specified MaxRecords value, a value is returned in a Marker field of the response. You can retrieve the next set of records by retrying the command with the returned marker value.
  --marker: string # An optional pagination token provided by a previous GetReservedNodeExchangeConfigurationOptions request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by the MaxRecords parameter. You can retrieve the next set of response records by providing the returned marker value in the Marker parameter and retrying the request.
  --action: string@action-completer-87
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, ReservedNodeConfigurationOptionList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ActionType" $action_type "scalar") (serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "SnapshotIdentifier" $snapshot_identifier "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ActionType": $action_type, "ClusterIdentifier": $cluster_identifier, "SnapshotIdentifier": $snapshot_identifier, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Gets the configuration options for the reserved-node exchange. These options include information about the source reserved node and target reserved node offering. Details include the node type, the price, the node count, and the offering type.
#
# POST /
# operationId: POST_GetReservedNodeExchangeConfigurationOptions
export def "api create-get-reserved-node-exchange-configuration-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-87
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, ReservedNodeConfigurationOptionList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns an array of DC2 ReservedNodeOfferings that matches the payment type, term, and usage price of the given DC1 reserved node.
#
# GET /
# operationId: GET_GetReservedNodeExchangeOfferings
export def "api get-reserved-node-exchange-offerings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reserved-node-id: string # A string representing the node identifier for the DC1 Reserved Node to be exchanged.
  --max-records: int # An integer setting the maximum number of ReservedNodeOfferings to retrieve.
  --marker: string # A value that indicates the starting point for the next set of ReservedNodeOfferings.
  --action: string@action-completer-88
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, ReservedNodeOfferings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ReservedNodeId" $reserved_node_id "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ReservedNodeId": $reserved_node_id, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns an array of DC2 ReservedNodeOfferings that matches the payment type, term, and usage price of the given DC1 reserved node.
#
# POST /
# operationId: POST_GetReservedNodeExchangeOfferings
export def "api create-get-reserved-node-exchange-offerings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-88
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Marker: record, ReservedNodeOfferings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# This operation is retired. Calling this operation does not change AQUA configuration. Amazon Redshift automatically determines whether to use AQUA (Advanced Query Accelerator).
#
# GET /
# operationId: GET_ModifyAquaConfiguration
export def "api get-modify-aqua-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The identifier of the cluster to be modified.
  --aqua-configuration-status: string@aqua-configuration-status-completer # This parameter is retired. Amazon Redshift automatically determines whether to use AQUA (Advanced Query Accelerator).
  --action: string@action-completer-89
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "AquaConfigurationStatus" $aqua_configuration_status "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "AquaConfigurationStatus": $aqua_configuration_status, "Action": $action, "Version": $version} | compact), body: null}
}

# This operation is retired. Calling this operation does not change AQUA configuration. Amazon Redshift automatically determines whether to use AQUA (Advanced Query Accelerator).
#
# POST /
# operationId: POST_ModifyAquaConfiguration
export def "api create-modify-aqua-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-89
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies an authentication profile.
#
# GET /
# operationId: GET_ModifyAuthenticationProfile
export def "api get-modify-authentication-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authentication-profile-name: string # The name of the authentication profile to replace.
  --authentication-profile-content: string # The new content of the authentication profile in JSON format. The maximum length of the JSON string is determined by a quota for your account.
  --action: string@action-completer-90
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AuthenticationProfileName: record, AuthenticationProfileContent: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AuthenticationProfileName" $authentication_profile_name "scalar") (serialize-qp "AuthenticationProfileContent" $authentication_profile_content "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AuthenticationProfileName": $authentication_profile_name, "AuthenticationProfileContent": $authentication_profile_content, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies an authentication profile.
#
# POST /
# operationId: POST_ModifyAuthenticationProfile
export def "api create-modify-authentication-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-90
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<AuthenticationProfileName: record, AuthenticationProfileContent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies the settings for a cluster. You can also change node type and the number of nodes to scale up or down the cluster. When resizing a cluster, you must specify both the number of nodes and the node type even if one of the parameters does not change. You can add another security or parameter group, or change the admin user password. Resetting a cluster password or modifying the security groups associated with a cluster do not need a reboot. However, modifying a parameter group requires a reboot for parameters to take effect. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_ModifyCluster
export def "api get-modify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The unique identifier of the cluster to be modified. Example: examplecluster
  --cluster-type: string # The new cluster type. When you submit your cluster resize request, your existing cluster goes into a read-only mode. After Amazon Redshift provisions a new cluster based on your resize requirements, there will be outage for a period while the old cluster is deleted and your connection is switched to the new cluster. You can use DescribeResize to track the progress of the resize request. Valid Values: multi-node | single-node
  --node-type: string # The new node type of the cluster. If you specify a new node type, you must also specify the number of nodes parameter. For more information about resizing clusters, go to Resizing Clusters in Amazon Redshift (https://docs.aws.amazon.com/redshift/latest/mgmt/rs-resize-tutorial.html) in the Amazon Redshift Cluster Management Guide. Valid Values: ds2.xlarge | ds2.8xlarge | dc1.large | dc1.8xlarge | dc2.large | dc2.8xlarge | ra3.xlplus | ra3.4xlarge | ra3.16xlarge
  --number-of-nodes: int # The new number of nodes of the cluster. If you specify a new number of nodes, you must also specify the node type parameter. For more information about resizing clusters, go to Resizing Clusters in Amazon Redshift (https://docs.aws.amazon.com/redshift/latest/mgmt/rs-resize-tutorial.html) in the Amazon Redshift Cluster Management Guide. Valid Values: Integer greater than 0.
  --cluster-security-groups: list # A list of cluster security groups to be authorized on this cluster. This change is asynchronously applied as soon as possible. Security groups currently associated with the cluster, and not in the list of groups to apply, will be revoked from the cluster. Constraints: Must be 1 to 255 alphanumeric characters or hyphens First character must be a letter Cannot end with a hyphen or contain two consecutive hyphens
  --vpc-security-group-ids: list # A list of virtual private cloud (VPC) security groups to be associated with the cluster. This change is asynchronously applied as soon as possible.
  --master-user-password: string # The new password for the cluster admin user. This change is asynchronously applied as soon as possible. Between the time of the request and the completion of the request, the MasterUserPassword element exists in the PendingModifiedValues element of the operation response. Operations never return the password, so this operation provides a way to regain access to the admin user for a cluster if the password is lost. Default: Uses existing setting. Constraints: Must be between 8 and 64 characters in length. Must contain at least one uppercase letter. Must contain at least one lowercase letter. Must contain one number. Can be any printable ASCII character (ASCII code 33-126) except ' (single quote), " (double quote), \, /, or @.
  --cluster-parameter-group-name: string # The name of the cluster parameter group to apply to this cluster. This change is applied only after the cluster is rebooted. To reboot a cluster use RebootCluster. Default: Uses existing setting. Constraints: The cluster parameter group must be in the same parameter group family that matches the cluster version.
  --automated-snapshot-retention-period: int # The number of days that automated snapshots are retained. If the value is 0, automated snapshots are disabled. Even if automated snapshots are disabled, you can still create manual snapshots when you want with CreateClusterSnapshot. If you decrease the automated snapshot retention period from its current value, existing automated snapshots that fall outside of the new retention period will be immediately deleted. You can't disable automated snapshots for RA3 node types. Set the automated retention period from 1-35 days. Default: Uses existing setting. Constraints: Must be a value from 0 to 35.
  --manual-snapshot-retention-period: int # The default for number of days that a newly created manual snapshot is retained. If the value is -1, the manual snapshot is retained indefinitely. This value doesn't retroactively change the retention periods of existing manual snapshots. The value must be either -1 or an integer between 1 and 3,653. The default value is -1.
  --preferred-maintenance-window: string # The weekly time range (in UTC) during which system maintenance can occur, if necessary. If system maintenance is necessary during the window, it may result in an outage. This maintenance window change is made immediately. If the new maintenance window indicates the current time, there must be at least 120 minutes between the current time and end of the window in order to ensure that pending changes are applied. Default: Uses existing setting. Format: ddd:hh24:mi-ddd:hh24:mi, for example wed:07:30-wed:08:00. Valid Days: Mon | Tue | Wed | Thu | Fri | Sat | Sun Constraints: Must be at least 30 minutes.
  --cluster-version: string # The new version number of the Amazon Redshift engine to upgrade to. For major version upgrades, if a non-default cluster parameter group is currently in use, a new cluster parameter group in the cluster parameter group family for the new version must be specified. The new cluster parameter group can be the default for that cluster parameter group family. For more information about parameters and parameter groups, go to Amazon Redshift Parameter Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-parameter-groups.html) in the Amazon Redshift Cluster Management Guide. Example: 1.0
  --allow-version-upgrade: oneof<nothing, bool> # If true, major version upgrades will be applied automatically to the cluster during the maintenance window. Default: false
  --hsm-client-certificate-identifier: string # Specifies the name of the HSM client certificate the Amazon Redshift cluster uses to retrieve the data encryption keys stored in an HSM.
  --hsm-configuration-identifier: string # Specifies the name of the HSM configuration that contains the information the Amazon Redshift cluster can use to retrieve and store keys in an HSM.
  --new-cluster-identifier: string # The new identifier for the cluster. Constraints: Must contain from 1 to 63 alphanumeric characters or hyphens. Alphabetic characters must be lowercase. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Must be unique for all clusters within an Amazon Web Services account. Example: examplecluster
  --publicly-accessible: oneof<nothing, bool> # If true, the cluster can be accessed from a public network. Only clusters in VPCs can be set to be publicly available.
  --elastic-ip: string # The Elastic IP (EIP) address for the cluster. Constraints: The cluster must be provisioned in EC2-VPC and publicly-accessible through an Internet gateway. For more information about provisioning clusters in EC2-VPC, go to Supported Platforms to Launch Your Cluster (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html#cluster-platforms) in the Amazon Redshift Cluster Management Guide.
  --enhanced-vpc-routing: oneof<nothing, bool> # An option that specifies whether to create the cluster with enhanced VPC routing enabled. To create a cluster that uses enhanced VPC routing, the cluster must be in a VPC. For more information, see Enhanced VPC Routing (https://docs.aws.amazon.com/redshift/latest/mgmt/enhanced-vpc-routing.html) in the Amazon Redshift Cluster Management Guide. If this option is true, enhanced VPC routing is enabled. Default: false
  --maintenance-track-name: string # The name for the maintenance track that you want to assign for the cluster. This name change is asynchronous. The new track name stays in the PendingModifiedValues for the cluster until the next maintenance window. When the maintenance track changes, the cluster is switched to the latest cluster release available for the maintenance track. At this point, the maintenance track name is applied.
  --encrypted: oneof<nothing, bool> # Indicates whether the cluster is encrypted. If the value is encrypted (true) and you provide a value for the KmsKeyId parameter, we encrypt the cluster with the provided KmsKeyId. If you don't provide a KmsKeyId, we encrypt with the default key. If the value is not encrypted (false), then the cluster is decrypted.
  --kms-key-id: string # The Key Management Service (KMS) key ID of the encryption key that you want to use to encrypt data in the cluster.
  --availability-zone-relocation: oneof<nothing, bool> # The option to enable relocation for an Amazon Redshift cluster between Availability Zones after the cluster modification is complete.
  --availability-zone: string # The option to initiate relocation for an Amazon Redshift cluster to the target Availability Zone.
  --port: int # The option to change the port of an Amazon Redshift cluster.
  --action: string@action-completer-91
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "ClusterType" $cluster_type "scalar") (serialize-qp "NodeType" $node_type "scalar") (serialize-qp "NumberOfNodes" $number_of_nodes "scalar") (serialize-qp "ClusterSecurityGroups" $cluster_security_groups "multi") (serialize-qp "VpcSecurityGroupIds" $vpc_security_group_ids "multi") (serialize-qp "MasterUserPassword" $master_user_password "scalar") (serialize-qp "ClusterParameterGroupName" $cluster_parameter_group_name "scalar") (serialize-qp "AutomatedSnapshotRetentionPeriod" $automated_snapshot_retention_period "scalar") (serialize-qp "ManualSnapshotRetentionPeriod" $manual_snapshot_retention_period "scalar") (serialize-qp "PreferredMaintenanceWindow" $preferred_maintenance_window "scalar") (serialize-qp "ClusterVersion" $cluster_version "scalar") (serialize-qp "AllowVersionUpgrade" $allow_version_upgrade "scalar") (serialize-qp "HsmClientCertificateIdentifier" $hsm_client_certificate_identifier "scalar") (serialize-qp "HsmConfigurationIdentifier" $hsm_configuration_identifier "scalar") (serialize-qp "NewClusterIdentifier" $new_cluster_identifier "scalar") (serialize-qp "PubliclyAccessible" $publicly_accessible "scalar") (serialize-qp "ElasticIp" $elastic_ip "scalar") (serialize-qp "EnhancedVpcRouting" $enhanced_vpc_routing "scalar") (serialize-qp "MaintenanceTrackName" $maintenance_track_name "scalar") (serialize-qp "Encrypted" $encrypted "scalar") (serialize-qp "KmsKeyId" $kms_key_id "scalar") (serialize-qp "AvailabilityZoneRelocation" $availability_zone_relocation "scalar") (serialize-qp "AvailabilityZone" $availability_zone "scalar") (serialize-qp "Port" $port "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "ClusterType": $cluster_type, "NodeType": $node_type, "NumberOfNodes": $number_of_nodes, "ClusterSecurityGroups": $cluster_security_groups, "VpcSecurityGroupIds": $vpc_security_group_ids, "MasterUserPassword": $master_user_password, "ClusterParameterGroupName": $cluster_parameter_group_name, "AutomatedSnapshotRetentionPeriod": $automated_snapshot_retention_period, "ManualSnapshotRetentionPeriod": $manual_snapshot_retention_period, "PreferredMaintenanceWindow": $preferred_maintenance_window, "ClusterVersion": $cluster_version, "AllowVersionUpgrade": $allow_version_upgrade, "HsmClientCertificateIdentifier": $hsm_client_certificate_identifier, "HsmConfigurationIdentifier": $hsm_configuration_identifier, "NewClusterIdentifier": $new_cluster_identifier, "PubliclyAccessible": $publicly_accessible, "ElasticIp": $elastic_ip, "EnhancedVpcRouting": $enhanced_vpc_routing, "MaintenanceTrackName": $maintenance_track_name, "Encrypted": $encrypted, "KmsKeyId": $kms_key_id, "AvailabilityZoneRelocation": $availability_zone_relocation, "AvailabilityZone": $availability_zone, "Port": $port, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies the settings for a cluster. You can also change node type and the number of nodes to scale up or down the cluster. When resizing a cluster, you must specify both the number of nodes and the node type even if one of the parameters does not change. You can add another security or parameter group, or change the admin user password. Resetting a cluster password or modifying the security groups associated with a cluster do not need a reboot. However, modifying a parameter group requires a reboot for parameters to take effect. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_ModifyCluster
export def "api create-modify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-91
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies the database revision of a cluster. The database revision is a unique revision of the database running in a cluster.
#
# GET /
# operationId: GET_ModifyClusterDbRevision
export def "api get-modify-db-revision" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The unique identifier of a cluster whose database revision you want to modify. Example: examplecluster
  --revision-target: string # The identifier of the database revision. You can retrieve this value from the response to the DescribeClusterDbRevisions request.
  --action: string@action-completer-92
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "RevisionTarget" $revision_target "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "RevisionTarget": $revision_target, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies the database revision of a cluster. The database revision is a unique revision of the database running in a cluster.
#
# POST /
# operationId: POST_ModifyClusterDbRevision
export def "api create-modify-db-revision" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-92
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies the list of Identity and Access Management (IAM) roles that can be used by the cluster to access other Amazon Web Services services. The maximum number of IAM roles that you can associate is subject to a quota. For more information, go to Quotas and limits (https://docs.aws.amazon.com/redshift/latest/mgmt/amazon-redshift-limits.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_ModifyClusterIamRoles
export def "api get-modify-iam-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The unique identifier of the cluster for which you want to associate or disassociate IAM roles.
  --add-iam-roles: list # Zero or more IAM roles to associate with the cluster. The roles must be in their Amazon Resource Name (ARN) format.
  --remove-iam-roles: list # Zero or more IAM roles in ARN format to disassociate from the cluster.
  --default-iam-role-arn: string # The Amazon Resource Name (ARN) for the IAM role that was set as default for the cluster when the cluster was last modified.
  --action: string@action-completer-93
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "AddIamRoles" $add_iam_roles "multi") (serialize-qp "RemoveIamRoles" $remove_iam_roles "multi") (serialize-qp "DefaultIamRoleArn" $default_iam_role_arn "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "AddIamRoles": $add_iam_roles, "RemoveIamRoles": $remove_iam_roles, "DefaultIamRoleArn": $default_iam_role_arn, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies the list of Identity and Access Management (IAM) roles that can be used by the cluster to access other Amazon Web Services services. The maximum number of IAM roles that you can associate is subject to a quota. For more information, go to Quotas and limits (https://docs.aws.amazon.com/redshift/latest/mgmt/amazon-redshift-limits.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_ModifyClusterIamRoles
export def "api create-modify-iam-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-93
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies the maintenance settings of a cluster.
#
# GET /
# operationId: GET_ModifyClusterMaintenance
export def "api get-modify-maintenance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # A unique identifier for the cluster.
  --defer-maintenance: oneof<nothing, bool> # A boolean indicating whether to enable the deferred maintenance window.
  --defer-maintenance-identifier: string # A unique identifier for the deferred maintenance window.
  --defer-maintenance-start-time: string # A timestamp indicating the start time for the deferred maintenance window. (format: date-time)
  --defer-maintenance-end-time: string # A timestamp indicating end time for the deferred maintenance window. If you specify an end time, you can't specify a duration. (format: date-time)
  --defer-maintenance-duration: int # An integer indicating the duration of the maintenance window in days. If you specify a duration, you can't specify an end time. The duration must be 45 days or less.
  --action: string@action-completer-94
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "DeferMaintenance" $defer_maintenance "scalar") (serialize-qp "DeferMaintenanceIdentifier" $defer_maintenance_identifier "scalar") (serialize-qp "DeferMaintenanceStartTime" $defer_maintenance_start_time "scalar") (serialize-qp "DeferMaintenanceEndTime" $defer_maintenance_end_time "scalar") (serialize-qp "DeferMaintenanceDuration" $defer_maintenance_duration "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "DeferMaintenance": $defer_maintenance, "DeferMaintenanceIdentifier": $defer_maintenance_identifier, "DeferMaintenanceStartTime": $defer_maintenance_start_time, "DeferMaintenanceEndTime": $defer_maintenance_end_time, "DeferMaintenanceDuration": $defer_maintenance_duration, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies the maintenance settings of a cluster.
#
# POST /
# operationId: POST_ModifyClusterMaintenance
export def "api create-modify-maintenance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-94
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies the parameters of a parameter group. For the parameters parameter, it can't contain ASCII characters. For more information about parameters and parameter groups, go to Amazon Redshift Parameter Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-parameter-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_ModifyClusterParameterGroup
export def "api get-modify-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameter-group-name: string # The name of the parameter group to be modified.
  --parameters: list # An array of parameters to be modified. A maximum of 20 parameters can be modified in a single request. For each parameter to be modified, you must supply at least the parameter name and parameter value; other name-value pairs of the parameter are optional. For the workload management (WLM) configuration, you must supply all the name-value pairs in the wlm_json_configuration parameter.
  --action: string@action-completer-95
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ParameterGroupName: record, ParameterGroupStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ParameterGroupName" $parameter_group_name "scalar") (serialize-qp "Parameters" $parameters "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ParameterGroupName": $parameter_group_name, "Parameters": $parameters, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies the parameters of a parameter group. For the parameters parameter, it can't contain ASCII characters. For more information about parameters and parameter groups, go to Amazon Redshift Parameter Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-parameter-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_ModifyClusterParameterGroup
export def "api create-modify-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-95
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ParameterGroupName: record, ParameterGroupStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies the settings for a snapshot. This exanmple modifies the manual retention period setting for a cluster snapshot.
#
# GET /
# operationId: GET_ModifyClusterSnapshot
export def "api get-modify-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-identifier: string # The identifier of the snapshot whose setting you want to modify.
  --manual-snapshot-retention-period: int # The number of days that a manual snapshot is retained. If the value is -1, the manual snapshot is retained indefinitely. If the manual snapshot falls outside of the new retention period, you can specify the force option to immediately delete the snapshot. The value must be either -1 or an integer between 1 and 3,653.
  --force: oneof<nothing, bool> # A Boolean option to override an exception if the retention period has already passed.
  --action: string@action-completer-96
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Snapshot: record<SnapshotIdentifier: record, ClusterIdentifier: record, SnapshotCreateTime: record, Status: record, Port: record, AvailabilityZone: record, ClusterCreateTime: record, MasterUsername: record, ClusterVersion: record, EngineFullVersion: record, SnapshotType: record, NodeType: record, NumberOfNodes: record, DBName: record, VpcId: record, Encrypted: record, KmsKeyId: record, EncryptedWithHSM: record, AccountsWithRestoreAccess: record, OwnerAccount: record, TotalBackupSizeInMegaBytes: record, ActualIncrementalBackupSizeInMegaBytes: record, BackupProgressInMegaBytes: record, CurrentBackupRateInMegaBytesPerSecond: record, EstimatedSecondsToCompletion: record, ElapsedTimeInSeconds: record, SourceRegion: record, Tags: record, RestorableNodeTypes: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, ManualSnapshotRetentionPeriod: record, ManualSnapshotRemainingDays: record, SnapshotRetentionStartTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SnapshotIdentifier" $snapshot_identifier "scalar") (serialize-qp "ManualSnapshotRetentionPeriod" $manual_snapshot_retention_period "scalar") (serialize-qp "Force" $force "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SnapshotIdentifier": $snapshot_identifier, "ManualSnapshotRetentionPeriod": $manual_snapshot_retention_period, "Force": $force, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies the settings for a snapshot. This exanmple modifies the manual retention period setting for a cluster snapshot.
#
# POST /
# operationId: POST_ModifyClusterSnapshot
export def "api create-modify-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-96
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Snapshot: record<SnapshotIdentifier: record, ClusterIdentifier: record, SnapshotCreateTime: record, Status: record, Port: record, AvailabilityZone: record, ClusterCreateTime: record, MasterUsername: record, ClusterVersion: record, EngineFullVersion: record, SnapshotType: record, NodeType: record, NumberOfNodes: record, DBName: record, VpcId: record, Encrypted: record, KmsKeyId: record, EncryptedWithHSM: record, AccountsWithRestoreAccess: record, OwnerAccount: record, TotalBackupSizeInMegaBytes: record, ActualIncrementalBackupSizeInMegaBytes: record, BackupProgressInMegaBytes: record, CurrentBackupRateInMegaBytesPerSecond: record, EstimatedSecondsToCompletion: record, ElapsedTimeInSeconds: record, SourceRegion: record, Tags: record, RestorableNodeTypes: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, ManualSnapshotRetentionPeriod: record, ManualSnapshotRemainingDays: record, SnapshotRetentionStartTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies a snapshot schedule for a cluster.
#
# GET /
# operationId: GET_ModifyClusterSnapshotSchedule
export def "api get-modify-snapshot-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # A unique identifier for the cluster whose snapshot schedule you want to modify.
  --schedule-identifier: string # A unique alphanumeric identifier for the schedule that you want to associate with the cluster.
  --disassociate-schedule: oneof<nothing, bool> # A boolean to indicate whether to remove the assoiciation between the cluster and the schedule.
  --action: string@action-completer-97
  --version: string@version-completer
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
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "ScheduleIdentifier" $schedule_identifier "scalar") (serialize-qp "DisassociateSchedule" $disassociate_schedule "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "ScheduleIdentifier": $schedule_identifier, "DisassociateSchedule": $disassociate_schedule, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies a snapshot schedule for a cluster.
#
# POST /
# operationId: POST_ModifyClusterSnapshotSchedule
export def "api create-modify-snapshot-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-97
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies a cluster subnet group to include the specified list of VPC subnets. The operation replaces the existing list of subnets with the new list of subnets.
#
# GET /
# operationId: GET_ModifyClusterSubnetGroup
export def "api get-modify-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-subnet-group-name: string # The name of the subnet group to be modified.
  --description: string # A text description of the subnet group to be modified.
  --subnet-ids: list # An array of VPC subnet IDs. A maximum of 20 subnets can be modified in a single request.
  --action: string@action-completer-98
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ClusterSubnetGroup: record<ClusterSubnetGroupName: record, Description: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterSubnetGroupName" $cluster_subnet_group_name "scalar") (serialize-qp "Description" $description "scalar") (serialize-qp "SubnetIds" $subnet_ids "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterSubnetGroupName": $cluster_subnet_group_name, "Description": $description, "SubnetIds": $subnet_ids, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies a cluster subnet group to include the specified list of VPC subnets. The operation replaces the existing list of subnets with the new list of subnets.
#
# POST /
# operationId: POST_ModifyClusterSubnetGroup
export def "api create-modify-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-98
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ClusterSubnetGroup: record<ClusterSubnetGroupName: record, Description: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies a Redshift-managed VPC endpoint.
#
# GET /
# operationId: GET_ModifyEndpointAccess
export def "api get-modify-endpoint-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --endpoint-name: string # The endpoint to be modified.
  --vpc-security-group-ids: list # The complete list of VPC security groups associated with the endpoint after the endpoint is modified.
  --action: string@action-completer-99
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ClusterIdentifier: record, ResourceOwner: record, SubnetGroupName: record, EndpointStatus: record, EndpointName: record, EndpointCreateTime: record, Port: record, Address: record, VpcSecurityGroups: record, VpcEndpoint: record<VpcEndpointId: record, VpcId: record, NetworkInterfaces: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EndpointName" $endpoint_name "scalar") (serialize-qp "VpcSecurityGroupIds" $vpc_security_group_ids "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"EndpointName": $endpoint_name, "VpcSecurityGroupIds": $vpc_security_group_ids, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies a Redshift-managed VPC endpoint.
#
# POST /
# operationId: POST_ModifyEndpointAccess
export def "api create-modify-endpoint-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-99
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ClusterIdentifier: record, ResourceOwner: record, SubnetGroupName: record, EndpointStatus: record, EndpointName: record, EndpointCreateTime: record, Port: record, Address: record, VpcSecurityGroups: record, VpcEndpoint: record<VpcEndpointId: record, VpcId: record, NetworkInterfaces: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies an existing Amazon Redshift event notification subscription.
#
# GET /
# operationId: GET_ModifyEventSubscription
export def "api get-modify-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the modified Amazon Redshift event notification subscription.
  --sns-topic-arn: string # The Amazon Resource Name (ARN) of the SNS topic to be used by the event notification subscription.
  --source-type: string # The type of source that will be generating the events. For example, if you want to be notified of events generated by a cluster, you would set this parameter to cluster. If this value is not specified, events are returned for all Amazon Redshift objects in your Amazon Web Services account. You must specify a source type in order to specify source IDs. Valid values: cluster, cluster-parameter-group, cluster-security-group, cluster-snapshot, and scheduled-action.
  --source-ids: list # A list of one or more identifiers of Amazon Redshift source objects. All of the objects must be of the same type as was specified in the source type parameter. The event subscription will return only events generated by the specified objects. If not specified, then events are returned for all objects within the source type specified. Example: my-cluster-1, my-cluster-2 Example: my-snapshot-20131010
  --event-categories: list # Specifies the Amazon Redshift event categories to be published by the event notification subscription. Values: configuration, management, monitoring, security, pending
  --severity: string # Specifies the Amazon Redshift event severity to be published by the event notification subscription. Values: ERROR, INFO
  --enabled: oneof<nothing, bool> # A Boolean value indicating if the subscription is enabled. true indicates the subscription is enabled
  --action: string@action-completer-100
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<EventSubscription: record<CustomerAwsId: record, CustSubscriptionId: record, SnsTopicArn: record, Status: record, SubscriptionCreationTime: record, SourceType: record, SourceIdsList: record, EventCategoriesList: record, Severity: record, Enabled: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SubscriptionName" $subscription_name "scalar") (serialize-qp "SnsTopicArn" $sns_topic_arn "scalar") (serialize-qp "SourceType" $source_type "scalar") (serialize-qp "SourceIds" $source_ids "multi") (serialize-qp "EventCategories" $event_categories "multi") (serialize-qp "Severity" $severity "scalar") (serialize-qp "Enabled" $enabled "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SubscriptionName": $subscription_name, "SnsTopicArn": $sns_topic_arn, "SourceType": $source_type, "SourceIds": $source_ids, "EventCategories": $event_categories, "Severity": $severity, "Enabled": $enabled, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies an existing Amazon Redshift event notification subscription.
#
# POST /
# operationId: POST_ModifyEventSubscription
export def "api create-modify-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-100
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<EventSubscription: record<CustomerAwsId: record, CustSubscriptionId: record, SnsTopicArn: record, Status: record, SubscriptionCreationTime: record, SourceType: record, SourceIdsList: record, EventCategoriesList: record, Severity: record, Enabled: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies a scheduled action.
#
# GET /
# operationId: GET_ModifyScheduledAction
export def "api get-modify-scheduled-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scheduled-action-name: string # The name of the scheduled action to modify.
  --target-action: record # A modified JSON format of the scheduled action. For more information about this parameter, see ScheduledAction.
  --schedule: string # A modified schedule in either at( ) or cron( ) format. For more information about this parameter, see ScheduledAction.
  --iam-role: string # A different IAM role to assume to run the target action. For more information about this parameter, see ScheduledAction.
  --scheduled-action-description: string # A modified description of the scheduled action.
  --start-time: string # A modified start time of the scheduled action. For more information about this parameter, see ScheduledAction. (format: date-time)
  --end-time: string # A modified end time of the scheduled action. For more information about this parameter, see ScheduledAction. (format: date-time)
  --enable: oneof<nothing, bool> # A modified enable flag of the scheduled action. If true, the scheduled action is active. If false, the scheduled action is disabled.
  --action: string@action-completer-101
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ScheduledActionName: record, TargetAction: record<ResizeCluster: record<ClusterIdentifier: record, ClusterType: record, NodeType: record, NumberOfNodes: record, Classic: record, ReservedNodeId: record, TargetReservedNodeOfferingId: record>, PauseCluster: record<ClusterIdentifier: record>, ResumeCluster: record<ClusterIdentifier: record>>, Schedule: record, IamRole: record, ScheduledActionDescription: record, State: record, NextInvocations: record, StartTime: record, EndTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ScheduledActionName" $scheduled_action_name "scalar") (serialize-qp "TargetAction" $target_action "multi") (serialize-qp "Schedule" $schedule "scalar") (serialize-qp "IamRole" $iam_role "scalar") (serialize-qp "ScheduledActionDescription" $scheduled_action_description "scalar") (serialize-qp "StartTime" $start_time "scalar") (serialize-qp "EndTime" $end_time "scalar") (serialize-qp "Enable" $enable "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ScheduledActionName": $scheduled_action_name, "TargetAction": $target_action, "Schedule": $schedule, "IamRole": $iam_role, "ScheduledActionDescription": $scheduled_action_description, "StartTime": $start_time, "EndTime": $end_time, "Enable": $enable, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies a scheduled action.
#
# POST /
# operationId: POST_ModifyScheduledAction
export def "api create-modify-scheduled-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-101
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ScheduledActionName: record, TargetAction: record<ResizeCluster: record<ClusterIdentifier: record, ClusterType: record, NodeType: record, NumberOfNodes: record, Classic: record, ReservedNodeId: record, TargetReservedNodeOfferingId: record>, PauseCluster: record<ClusterIdentifier: record>, ResumeCluster: record<ClusterIdentifier: record>>, Schedule: record, IamRole: record, ScheduledActionDescription: record, State: record, NextInvocations: record, StartTime: record, EndTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies the number of days to retain snapshots in the destination Amazon Web Services Region after they are copied from the source Amazon Web Services Region. By default, this operation only changes the retention period of copied automated snapshots. The retention periods for both new and existing copied automated snapshots are updated with the new retention period. You can set the manual option to change only the retention periods of copied manual snapshots. If you set this option, only newly copied manual snapshots have the new retention period.
#
# GET /
# operationId: GET_ModifySnapshotCopyRetentionPeriod
export def "api get-modify-snapshot-copy-retention-period" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The unique identifier of the cluster for which you want to change the retention period for either automated or manual snapshots that are copied to a destination Amazon Web Services Region. Constraints: Must be the valid name of an existing cluster that has cross-region snapshot copy enabled.
  --retention-period: int # The number of days to retain automated snapshots in the destination Amazon Web Services Region after they are copied from the source Amazon Web Services Region. By default, this only changes the retention period of copied automated snapshots. If you decrease the retention period for automated snapshots that are copied to a destination Amazon Web Services Region, Amazon Redshift deletes any existing automated snapshots that were copied to the destination Amazon Web Services Region and that fall outside of the new retention period. Constraints: Must be at least 1 and no more than 35 for automated snapshots. If you specify the manual option, only newly copied manual snapshots will have the new retention period. If you specify the value of -1 newly copied manual snapshots are retained indefinitely. Constraints: The number of days must be either -1 or an integer between 1 and 3,653 for manual snapshots.
  --manual: oneof<nothing, bool> # Indicates whether to apply the snapshot retention period to newly copied manual snapshots instead of automated snapshots.
  --action: string@action-completer-102
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "RetentionPeriod" $retention_period "scalar") (serialize-qp "Manual" $manual "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "RetentionPeriod": $retention_period, "Manual": $manual, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies the number of days to retain snapshots in the destination Amazon Web Services Region after they are copied from the source Amazon Web Services Region. By default, this operation only changes the retention period of copied automated snapshots. The retention periods for both new and existing copied automated snapshots are updated with the new retention period. You can set the manual option to change only the retention periods of copied manual snapshots. If you set this option, only newly copied manual snapshots have the new retention period.
#
# POST /
# operationId: POST_ModifySnapshotCopyRetentionPeriod
export def "api create-modify-snapshot-copy-retention-period" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-102
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies a snapshot schedule. Any schedule associated with a cluster is modified asynchronously.
#
# GET /
# operationId: GET_ModifySnapshotSchedule
export def "api get-modify-snapshot-schedule-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schedule-identifier: string # A unique alphanumeric identifier of the schedule to modify.
  --schedule-definitions: list # An updated list of schedule definitions. A schedule definition is made up of schedule expressions, for example, "cron(30 12 *)" or "rate(12 hours)".
  --action: string@action-completer-103
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ScheduleDefinitions: record, ScheduleIdentifier: record, ScheduleDescription: record, Tags: record, NextInvocations: record, AssociatedClusterCount: record, AssociatedClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ScheduleIdentifier" $schedule_identifier "scalar") (serialize-qp "ScheduleDefinitions" $schedule_definitions "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ScheduleIdentifier": $schedule_identifier, "ScheduleDefinitions": $schedule_definitions, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies a snapshot schedule. Any schedule associated with a cluster is modified asynchronously.
#
# POST /
# operationId: POST_ModifySnapshotSchedule
export def "api create-modify-snapshot-schedule-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-103
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ScheduleDefinitions: record, ScheduleIdentifier: record, ScheduleDescription: record, Tags: record, NextInvocations: record, AssociatedClusterCount: record, AssociatedClusters: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Modifies a usage limit in a cluster. You can't modify the feature type or period of a usage limit.
#
# GET /
# operationId: GET_ModifyUsageLimit
export def "api get-modify-usage-limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --usage-limit-id: string # The identifier of the usage limit to modify.
  --amount: int # The new limit amount. For more information about this parameter, see UsageLimit.
  --breach-action: string@breach-action-completer # The new action that Amazon Redshift takes when the limit is reached. For more information about this parameter, see UsageLimit.
  --action: string@action-completer-104
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<UsageLimitId: record, ClusterIdentifier: record, FeatureType: record, LimitType: record, Amount: record, Period: record, BreachAction: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UsageLimitId" $usage_limit_id "scalar") (serialize-qp "Amount" $amount "scalar") (serialize-qp "BreachAction" $breach_action "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"UsageLimitId": $usage_limit_id, "Amount": $amount, "BreachAction": $breach_action, "Action": $action, "Version": $version} | compact), body: null}
}

# Modifies a usage limit in a cluster. You can't modify the feature type or period of a usage limit.
#
# POST /
# operationId: POST_ModifyUsageLimit
export def "api create-modify-usage-limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-104
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<UsageLimitId: record, ClusterIdentifier: record, FeatureType: record, LimitType: record, Amount: record, Period: record, BreachAction: record, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Pauses a cluster.
#
# GET /
# operationId: GET_PauseCluster
export def "api get-pause" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The identifier of the cluster to be paused.
  --action: string@action-completer-105
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Pauses a cluster.
#
# POST /
# operationId: POST_PauseCluster
export def "api create-pause" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-105
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Allows you to purchase reserved nodes. Amazon Redshift offers a predefined set of reserved node offerings. You can purchase one or more of the offerings. You can call the DescribeReservedNodeOfferings API to obtain the available reserved node offerings. You can call this API by providing a specific reserved node offering and the number of nodes you want to reserve. For more information about reserved node offerings, go to Purchasing Reserved Nodes (https://docs.aws.amazon.com/redshift/latest/mgmt/purchase-reserved-node-instance.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_PurchaseReservedNodeOffering
export def "api get-purchase-reserved-node-offering" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reserved-node-offering-id: string # The unique identifier of the reserved node offering you want to purchase.
  --node-count: int # The number of reserved nodes that you want to purchase. Default: 1
  --action: string@action-completer-106
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ReservedNode: record<ReservedNodeId: record, ReservedNodeOfferingId: record, NodeType: record, StartTime: record, Duration: record, FixedPrice: record, UsagePrice: record, CurrencyCode: record, NodeCount: record, State: record, OfferingType: record, RecurringCharges: record, ReservedNodeOfferingType: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ReservedNodeOfferingId" $reserved_node_offering_id "scalar") (serialize-qp "NodeCount" $node_count "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ReservedNodeOfferingId": $reserved_node_offering_id, "NodeCount": $node_count, "Action": $action, "Version": $version} | compact), body: null}
}

# Allows you to purchase reserved nodes. Amazon Redshift offers a predefined set of reserved node offerings. You can purchase one or more of the offerings. You can call the DescribeReservedNodeOfferings API to obtain the available reserved node offerings. You can call this API by providing a specific reserved node offering and the number of nodes you want to reserve. For more information about reserved node offerings, go to Purchasing Reserved Nodes (https://docs.aws.amazon.com/redshift/latest/mgmt/purchase-reserved-node-instance.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_PurchaseReservedNodeOffering
export def "api create-purchase-reserved-node-offering" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-106
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ReservedNode: record<ReservedNodeId: record, ReservedNodeOfferingId: record, NodeType: record, StartTime: record, Duration: record, FixedPrice: record, UsagePrice: record, CurrencyCode: record, NodeCount: record, State: record, OfferingType: record, RecurringCharges: record, ReservedNodeOfferingType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Reboots a cluster. This action is taken as soon as possible. It results in a momentary outage to the cluster, during which the cluster status is set to rebooting. A cluster event is created when the reboot is completed. Any pending cluster modifications (see ModifyCluster) are applied at this reboot. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_RebootCluster
export def "api get-reboot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The cluster identifier.
  --action: string@action-completer-107
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Reboots a cluster. This action is taken as soon as possible. It results in a momentary outage to the cluster, during which the cluster status is set to rebooting. A cluster event is created when the reboot is completed. Any pending cluster modifications (see ModifyCluster) are applied at this reboot. For more information about managing clusters, go to Amazon Redshift Clusters (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_RebootCluster
export def "api create-reboot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-107
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# From a datashare consumer account, rejects the specified datashare.
#
# GET /
# operationId: GET_RejectDataShare
export def "api get-reject-data-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-share-arn: string # The Amazon Resource Name (ARN) of the datashare to reject.
  --action: string@action-completer-108
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DataShareArn: record, ProducerArn: record, AllowPubliclyAccessibleConsumers: record, DataShareAssociations: record, ManagedBy: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DataShareArn" $data_share_arn "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"DataShareArn": $data_share_arn, "Action": $action, "Version": $version} | compact), body: null}
}

# From a datashare consumer account, rejects the specified datashare.
#
# POST /
# operationId: POST_RejectDataShare
export def "api create-reject-data-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-108
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DataShareArn: record, ProducerArn: record, AllowPubliclyAccessibleConsumers: record, DataShareAssociations: record, ManagedBy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Sets one or more parameters of the specified parameter group to their default values and sets the source values of the parameters to "engine-default". To reset the entire parameter group specify the ResetAllParameters parameter. For parameter changes to take effect you must reboot any associated clusters.
#
# GET /
# operationId: GET_ResetClusterParameterGroup
export def "api get-reset-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameter-group-name: string # The name of the cluster parameter group to be reset.
  --reset-all-parameters: oneof<nothing, bool> # If true, all parameters in the specified parameter group will be reset to their default values. Default: true
  --parameters: list # An array of names of parameters to be reset. If ResetAllParameters option is not used, then at least one parameter name must be supplied. Constraints: A maximum of 20 parameters can be reset in a single request.
  --action: string@action-completer-109
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ParameterGroupName: record, ParameterGroupStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ParameterGroupName" $parameter_group_name "scalar") (serialize-qp "ResetAllParameters" $reset_all_parameters "scalar") (serialize-qp "Parameters" $parameters "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ParameterGroupName": $parameter_group_name, "ResetAllParameters": $reset_all_parameters, "Parameters": $parameters, "Action": $action, "Version": $version} | compact), body: null}
}

# Sets one or more parameters of the specified parameter group to their default values and sets the source values of the parameters to "engine-default". To reset the entire parameter group specify the ResetAllParameters parameter. For parameter changes to take effect you must reboot any associated clusters.
#
# POST /
# operationId: POST_ResetClusterParameterGroup
export def "api create-reset-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-109
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ParameterGroupName: record, ParameterGroupStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Changes the size of the cluster. You can change the cluster's type, or change the number or type of nodes. The default behavior is to use the elastic resize method. With an elastic resize, your cluster is available for read and write operations more quickly than with the classic resize method. Elastic resize operations have the following restrictions: You can only resize clusters of the following types: dc1.large (if your cluster is in a VPC) dc1.8xlarge (if your cluster is in a VPC) dc2.large dc2.8xlarge ds2.xlarge ds2.8xlarge ra3.xlplus ra3.4xlarge ra3.16xlarge The type of nodes that you add must match the node type for the cluster.
#
# GET /
# operationId: GET_ResizeCluster
export def "api get-resize-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The unique identifier for the cluster to resize.
  --cluster-type: string # The new cluster type for the specified cluster.
  --node-type: string # The new node type for the nodes you are adding. If not specified, the cluster's current node type is used.
  --number-of-nodes: int # The new number of nodes for the cluster. If not specified, the cluster's current number of nodes is used.
  --classic: oneof<nothing, bool> # A boolean value indicating whether the resize operation is using the classic resize process. If you don't provide this parameter or set the value to false, the resize type is elastic.
  --reserved-node-id: string # The identifier of the reserved node.
  --target-reserved-node-offering-id: string # The identifier of the target reserved node offering.
  --action: string@action-completer-110
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "ClusterType" $cluster_type "scalar") (serialize-qp "NodeType" $node_type "scalar") (serialize-qp "NumberOfNodes" $number_of_nodes "scalar") (serialize-qp "Classic" $classic "scalar") (serialize-qp "ReservedNodeId" $reserved_node_id "scalar") (serialize-qp "TargetReservedNodeOfferingId" $target_reserved_node_offering_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "ClusterType": $cluster_type, "NodeType": $node_type, "NumberOfNodes": $number_of_nodes, "Classic": $classic, "ReservedNodeId": $reserved_node_id, "TargetReservedNodeOfferingId": $target_reserved_node_offering_id, "Action": $action, "Version": $version} | compact), body: null}
}

# Changes the size of the cluster. You can change the cluster's type, or change the number or type of nodes. The default behavior is to use the elastic resize method. With an elastic resize, your cluster is available for read and write operations more quickly than with the classic resize method. Elastic resize operations have the following restrictions: You can only resize clusters of the following types: dc1.large (if your cluster is in a VPC) dc1.8xlarge (if your cluster is in a VPC) dc2.large dc2.8xlarge ds2.xlarge ds2.8xlarge ra3.xlplus ra3.4xlarge ra3.16xlarge The type of nodes that you add must match the node type for the cluster.
#
# POST /
# operationId: POST_ResizeCluster
export def "api create-resize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-110
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates a new cluster from a snapshot. By default, Amazon Redshift creates the resulting cluster with the same configuration as the original cluster from which the snapshot was created, except that the new cluster is created with the default cluster security and parameter groups. After Amazon Redshift creates the cluster, you can use the ModifyCluster API to associate a different security group and different parameter group with the restored cluster. If you are using a DS node type, you can also choose to change to another DS node type of the same size during restore. If you restore a cluster into a VPC, you must provide a cluster subnet group where you want the cluster restored. For more information about working with snapshots, go to Amazon Redshift Snapshots (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-snapshots.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_RestoreFromClusterSnapshot
export def "api get-restore-from-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The identifier of the cluster that will be created from restoring the snapshot. Constraints: Must contain from 1 to 63 alphanumeric characters or hyphens. Alphabetic characters must be lowercase. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Must be unique for all clusters within an Amazon Web Services account.
  --snapshot-identifier: string # The name of the snapshot from which to create the new cluster. This parameter isn't case sensitive. You must specify this parameter or snapshotArn, but not both. Example: my-snapshot-id
  --snapshot-arn: string # The Amazon Resource Name (ARN) of the snapshot associated with the message to restore from a cluster. You must specify this parameter or snapshotIdentifier, but not both.
  --snapshot-cluster-identifier: string # The name of the cluster the source snapshot was created from. This parameter is required if your IAM user or role has a policy containing a snapshot resource element that specifies anything other than * for the cluster name.
  --port: int # The port number on which the cluster accepts connections. Default: The same port as the original cluster. Constraints: Must be between 1115 and 65535.
  --availability-zone: string # The Amazon EC2 Availability Zone in which to restore the cluster. Default: A random, system-chosen Availability Zone. Example: us-east-2a
  --allow-version-upgrade: oneof<nothing, bool> # If true, major version upgrades can be applied during the maintenance window to the Amazon Redshift engine that is running on the cluster. Default: true
  --cluster-subnet-group-name: string # The name of the subnet group where you want to cluster restored. A snapshot of cluster in VPC can be restored only in VPC. Therefore, you must provide subnet group name where you want the cluster restored.
  --publicly-accessible: oneof<nothing, bool> # If true, the cluster can be accessed from a public network.
  --owner-account: string # The Amazon Web Services account used to create or copy the snapshot. Required if you are restoring a snapshot you do not own, optional if you own the snapshot.
  --hsm-client-certificate-identifier: string # Specifies the name of the HSM client certificate the Amazon Redshift cluster uses to retrieve the data encryption keys stored in an HSM.
  --hsm-configuration-identifier: string # Specifies the name of the HSM configuration that contains the information the Amazon Redshift cluster can use to retrieve and store keys in an HSM.
  --elastic-ip: string # The Elastic IP (EIP) address for the cluster. Don't specify the Elastic IP address for a publicly accessible cluster with availability zone relocation turned on.
  --cluster-parameter-group-name: string # The name of the parameter group to be associated with this cluster. Default: The default Amazon Redshift cluster parameter group. For information about the default parameter group, go to Working with Amazon Redshift Parameter Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-parameter-groups.html). Constraints: Must be 1 to 255 alphanumeric characters or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens.
  --cluster-security-groups: list # A list of security groups to be associated with this cluster. Default: The default cluster security group for Amazon Redshift. Cluster security groups only apply to clusters outside of VPCs.
  --vpc-security-group-ids: list # A list of Virtual Private Cloud (VPC) security groups to be associated with the cluster. Default: The default VPC security group is associated with the cluster. VPC security groups only apply to clusters in VPCs.
  --preferred-maintenance-window: string # The weekly time range (in UTC) during which automated cluster maintenance can occur. Format: ddd:hh24:mi-ddd:hh24:mi Default: The value selected for the cluster from which the snapshot was taken. For more information about the time blocks for each region, see Maintenance Windows (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html#rs-maintenance-windows) in Amazon Redshift Cluster Management Guide. Valid Days: Mon | Tue | Wed | Thu | Fri | Sat | Sun Constraints: Minimum 30-minute window.
  --automated-snapshot-retention-period: int # The number of days that automated snapshots are retained. If the value is 0, automated snapshots are disabled. Even if automated snapshots are disabled, you can still create manual snapshots when you want with CreateClusterSnapshot. You can't disable automated snapshots for RA3 node types. Set the automated retention period from 1-35 days. Default: The value selected for the cluster from which the snapshot was taken. Constraints: Must be a value from 0 to 35.
  --manual-snapshot-retention-period: int # The default number of days to retain a manual snapshot. If the value is -1, the snapshot is retained indefinitely. This setting doesn't change the retention period of existing snapshots. The value must be either -1 or an integer between 1 and 3,653.
  --kms-key-id: string # The Key Management Service (KMS) key ID of the encryption key that encrypts data in the cluster restored from a shared snapshot. You can also provide the key ID when you restore from an unencrypted snapshot to an encrypted cluster in the same account. Additionally, you can specify a new KMS key ID when you restore from an encrypted snapshot in the same account in order to change it. In that case, the restored cluster is encrypted with the new KMS key ID.
  --node-type: string # The node type that the restored cluster will be provisioned with. Default: The node type of the cluster from which the snapshot was taken. You can modify this if you are using any DS node type. In that case, you can choose to restore into another DS node type of the same size. For example, you can restore ds1.8xlarge into ds2.8xlarge, or ds1.xlarge into ds2.xlarge. If you have a DC instance type, you must restore into that same instance type and size. In other words, you can only restore a dc1.large instance type into another dc1.large instance type or dc2.large instance type. You can't restore dc1.8xlarge to dc2.8xlarge. First restore to a dc1.8xlarge cluster, then resize to a dc2.8large cluster. For more information about node types, see About Clusters and Nodes (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html#rs-about-clusters-and-nodes) in the Amazon Redshift Cluster Management Guide.
  --enhanced-vpc-routing: oneof<nothing, bool> # An option that specifies whether to create the cluster with enhanced VPC routing enabled. To create a cluster that uses enhanced VPC routing, the cluster must be in a VPC. For more information, see Enhanced VPC Routing (https://docs.aws.amazon.com/redshift/latest/mgmt/enhanced-vpc-routing.html) in the Amazon Redshift Cluster Management Guide. If this option is true, enhanced VPC routing is enabled. Default: false
  --additional-info: string # Reserved.
  --iam-roles: list # A list of Identity and Access Management (IAM) roles that can be used by the cluster to access other Amazon Web Services services. You must supply the IAM roles in their Amazon Resource Name (ARN) format. The maximum number of IAM roles that you can associate is subject to a quota. For more information, go to Quotas and limits (https://docs.aws.amazon.com/redshift/latest/mgmt/amazon-redshift-limits.html) in the Amazon Redshift Cluster Management Guide.
  --maintenance-track-name: string # The name of the maintenance track for the restored cluster. When you take a snapshot, the snapshot inherits the MaintenanceTrack value from the cluster. The snapshot might be on a different track than the cluster that was the source for the snapshot. For example, suppose that you take a snapshot of a cluster that is on the current track and then change the cluster to be on the trailing track. In this case, the snapshot and the source cluster are on different tracks.
  --snapshot-schedule-identifier: string # A unique identifier for the snapshot schedule.
  --number-of-nodes: int # The number of nodes specified when provisioning the restored cluster.
  --availability-zone-relocation: oneof<nothing, bool> # The option to enable relocation for an Amazon Redshift cluster between Availability Zones after the cluster is restored.
  --aqua-configuration-status: string@aqua-configuration-status-completer # This parameter is retired. It does not set the AQUA configuration status. Amazon Redshift automatically determines whether to use AQUA (Advanced Query Accelerator).
  --default-iam-role-arn: string # The Amazon Resource Name (ARN) for the IAM role that was set as default for the cluster when the cluster was last modified while it was restored from a snapshot.
  --reserved-node-id: string # The identifier of the target reserved node offering.
  --target-reserved-node-offering-id: string # The identifier of the target reserved node offering.
  --encrypted: oneof<nothing, bool> # Enables support for restoring an unencrypted snapshot to a cluster encrypted with Key Management Service (KMS) and a customer managed key.
  --action: string@action-completer-111
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "SnapshotIdentifier" $snapshot_identifier "scalar") (serialize-qp "SnapshotArn" $snapshot_arn "scalar") (serialize-qp "SnapshotClusterIdentifier" $snapshot_cluster_identifier "scalar") (serialize-qp "Port" $port "scalar") (serialize-qp "AvailabilityZone" $availability_zone "scalar") (serialize-qp "AllowVersionUpgrade" $allow_version_upgrade "scalar") (serialize-qp "ClusterSubnetGroupName" $cluster_subnet_group_name "scalar") (serialize-qp "PubliclyAccessible" $publicly_accessible "scalar") (serialize-qp "OwnerAccount" $owner_account "scalar") (serialize-qp "HsmClientCertificateIdentifier" $hsm_client_certificate_identifier "scalar") (serialize-qp "HsmConfigurationIdentifier" $hsm_configuration_identifier "scalar") (serialize-qp "ElasticIp" $elastic_ip "scalar") (serialize-qp "ClusterParameterGroupName" $cluster_parameter_group_name "scalar") (serialize-qp "ClusterSecurityGroups" $cluster_security_groups "multi") (serialize-qp "VpcSecurityGroupIds" $vpc_security_group_ids "multi") (serialize-qp "PreferredMaintenanceWindow" $preferred_maintenance_window "scalar") (serialize-qp "AutomatedSnapshotRetentionPeriod" $automated_snapshot_retention_period "scalar") (serialize-qp "ManualSnapshotRetentionPeriod" $manual_snapshot_retention_period "scalar") (serialize-qp "KmsKeyId" $kms_key_id "scalar") (serialize-qp "NodeType" $node_type "scalar") (serialize-qp "EnhancedVpcRouting" $enhanced_vpc_routing "scalar") (serialize-qp "AdditionalInfo" $additional_info "scalar") (serialize-qp "IamRoles" $iam_roles "multi") (serialize-qp "MaintenanceTrackName" $maintenance_track_name "scalar") (serialize-qp "SnapshotScheduleIdentifier" $snapshot_schedule_identifier "scalar") (serialize-qp "NumberOfNodes" $number_of_nodes "scalar") (serialize-qp "AvailabilityZoneRelocation" $availability_zone_relocation "scalar") (serialize-qp "AquaConfigurationStatus" $aqua_configuration_status "scalar") (serialize-qp "DefaultIamRoleArn" $default_iam_role_arn "scalar") (serialize-qp "ReservedNodeId" $reserved_node_id "scalar") (serialize-qp "TargetReservedNodeOfferingId" $target_reserved_node_offering_id "scalar") (serialize-qp "Encrypted" $encrypted "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "SnapshotIdentifier": $snapshot_identifier, "SnapshotArn": $snapshot_arn, "SnapshotClusterIdentifier": $snapshot_cluster_identifier, "Port": $port, "AvailabilityZone": $availability_zone, "AllowVersionUpgrade": $allow_version_upgrade, "ClusterSubnetGroupName": $cluster_subnet_group_name, "PubliclyAccessible": $publicly_accessible, "OwnerAccount": $owner_account, "HsmClientCertificateIdentifier": $hsm_client_certificate_identifier, "HsmConfigurationIdentifier": $hsm_configuration_identifier, "ElasticIp": $elastic_ip, "ClusterParameterGroupName": $cluster_parameter_group_name, "ClusterSecurityGroups": $cluster_security_groups, "VpcSecurityGroupIds": $vpc_security_group_ids, "PreferredMaintenanceWindow": $preferred_maintenance_window, "AutomatedSnapshotRetentionPeriod": $automated_snapshot_retention_period, "ManualSnapshotRetentionPeriod": $manual_snapshot_retention_period, "KmsKeyId": $kms_key_id, "NodeType": $node_type, "EnhancedVpcRouting": $enhanced_vpc_routing, "AdditionalInfo": $additional_info, "IamRoles": $iam_roles, "MaintenanceTrackName": $maintenance_track_name, "SnapshotScheduleIdentifier": $snapshot_schedule_identifier, "NumberOfNodes": $number_of_nodes, "AvailabilityZoneRelocation": $availability_zone_relocation, "AquaConfigurationStatus": $aqua_configuration_status, "DefaultIamRoleArn": $default_iam_role_arn, "ReservedNodeId": $reserved_node_id, "TargetReservedNodeOfferingId": $target_reserved_node_offering_id, "Encrypted": $encrypted, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates a new cluster from a snapshot. By default, Amazon Redshift creates the resulting cluster with the same configuration as the original cluster from which the snapshot was created, except that the new cluster is created with the default cluster security and parameter groups. After Amazon Redshift creates the cluster, you can use the ModifyCluster API to associate a different security group and different parameter group with the restored cluster. If you are using a DS node type, you can also choose to change to another DS node type of the same size during restore. If you restore a cluster into a VPC, you must provide a cluster subnet group where you want the cluster restored. For more information about working with snapshots, go to Amazon Redshift Snapshots (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-snapshots.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_RestoreFromClusterSnapshot
export def "api create-restore-from-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-111
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates a new table from a table in an Amazon Redshift cluster snapshot. You must create the new table within the Amazon Redshift cluster that the snapshot was taken from. You cannot use RestoreTableFromClusterSnapshot to restore a table with the same name as an existing table in an Amazon Redshift cluster. That is, you cannot overwrite an existing table in a cluster with a restored table. If you want to replace your original table with a new, restored table, then rename or drop your original table before you call RestoreTableFromClusterSnapshot. When you have renamed your original table, then you can pass the original name of the table as the NewTableName parameter value in the call to RestoreTableFromClusterSnapshot. This way, you can replace the original table with the table created from the snapshot. You can't use this operation to restore tables with interleaved sort keys (https://docs.aws.amazon.com/redshift/latest/dg/t_Sorting_data.html#t_Sorting_data-interleaved).
#
# GET /
# operationId: GET_RestoreTableFromClusterSnapshot
export def "api get-restore-table-from-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The identifier of the Amazon Redshift cluster to restore the table to.
  --snapshot-identifier: string # The identifier of the snapshot to restore the table from. This snapshot must have been created from the Amazon Redshift cluster specified by the ClusterIdentifier parameter.
  --source-database-name: string # The name of the source database that contains the table to restore from.
  --source-schema-name: string # The name of the source schema that contains the table to restore from. If you do not specify a SourceSchemaName value, the default is public.
  --source-table-name: string # The name of the source table to restore from.
  --target-database-name: string # The name of the database to restore the table to.
  --target-schema-name: string # The name of the schema to restore the table to.
  --new-table-name: string # The name of the table to create as a result of the current request.
  --enable-case-sensitive-identifier: oneof<nothing, bool> # Indicates whether name identifiers for database, schema, and table are case sensitive. If true, the names are case sensitive. If false (default), the names are not case sensitive.
  --action: string@action-completer-112
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TableRestoreStatus: record<TableRestoreRequestId: record, Status: record, Message: record, RequestTime: record, ProgressInMegaBytes: record, TotalDataInMegaBytes: record, ClusterIdentifier: record, SnapshotIdentifier: record, SourceDatabaseName: record, SourceSchemaName: record, SourceTableName: record, TargetDatabaseName: record, TargetSchemaName: record, NewTableName: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "SnapshotIdentifier" $snapshot_identifier "scalar") (serialize-qp "SourceDatabaseName" $source_database_name "scalar") (serialize-qp "SourceSchemaName" $source_schema_name "scalar") (serialize-qp "SourceTableName" $source_table_name "scalar") (serialize-qp "TargetDatabaseName" $target_database_name "scalar") (serialize-qp "TargetSchemaName" $target_schema_name "scalar") (serialize-qp "NewTableName" $new_table_name "scalar") (serialize-qp "EnableCaseSensitiveIdentifier" $enable_case_sensitive_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "SnapshotIdentifier": $snapshot_identifier, "SourceDatabaseName": $source_database_name, "SourceSchemaName": $source_schema_name, "SourceTableName": $source_table_name, "TargetDatabaseName": $target_database_name, "TargetSchemaName": $target_schema_name, "NewTableName": $new_table_name, "EnableCaseSensitiveIdentifier": $enable_case_sensitive_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates a new table from a table in an Amazon Redshift cluster snapshot. You must create the new table within the Amazon Redshift cluster that the snapshot was taken from. You cannot use RestoreTableFromClusterSnapshot to restore a table with the same name as an existing table in an Amazon Redshift cluster. That is, you cannot overwrite an existing table in a cluster with a restored table. If you want to replace your original table with a new, restored table, then rename or drop your original table before you call RestoreTableFromClusterSnapshot. When you have renamed your original table, then you can pass the original name of the table as the NewTableName parameter value in the call to RestoreTableFromClusterSnapshot. This way, you can replace the original table with the table created from the snapshot. You can't use this operation to restore tables with interleaved sort keys (https://docs.aws.amazon.com/redshift/latest/dg/t_Sorting_data.html#t_Sorting_data-interleaved).
#
# POST /
# operationId: POST_RestoreTableFromClusterSnapshot
export def "api create-restore-table-from-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-112
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<TableRestoreStatus: record<TableRestoreRequestId: record, Status: record, Message: record, RequestTime: record, ProgressInMegaBytes: record, TotalDataInMegaBytes: record, ClusterIdentifier: record, SnapshotIdentifier: record, SourceDatabaseName: record, SourceSchemaName: record, SourceTableName: record, TargetDatabaseName: record, TargetSchemaName: record, NewTableName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Resumes a paused cluster.
#
# GET /
# operationId: GET_ResumeCluster
export def "api get-resume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The identifier of the cluster to be resumed.
  --action: string@action-completer-113
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Resumes a paused cluster.
#
# POST /
# operationId: POST_ResumeCluster
export def "api create-resume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-113
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Revokes an ingress rule in an Amazon Redshift security group for a previously authorized IP range or Amazon EC2 security group. To add an ingress rule, see AuthorizeClusterSecurityGroupIngress. For information about managing security groups, go to Amazon Redshift Cluster Security Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-security-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_RevokeClusterSecurityGroupIngress
export def "api get-delete-security-group-ingress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-security-group-name: string # The name of the security Group from which to revoke the ingress rule.
  --cidrip: string # The IP range for which to revoke access. This range must be a valid Classless Inter-Domain Routing (CIDR) block of IP addresses. If CIDRIP is specified, EC2SecurityGroupName and EC2SecurityGroupOwnerId cannot be provided.
  --ec2-security-group-name: string # The name of the EC2 Security Group whose access is to be revoked. If EC2SecurityGroupName is specified, EC2SecurityGroupOwnerId must also be provided and CIDRIP cannot be provided.
  --ec2-security-group-owner-id: string # The Amazon Web Services account number of the owner of the security group specified in the EC2SecurityGroupName parameter. The Amazon Web Services access key ID is not an acceptable value. If EC2SecurityGroupOwnerId is specified, EC2SecurityGroupName must also be provided. and CIDRIP cannot be provided. Example: 111122223333
  --action: string@action-completer-114
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ClusterSecurityGroup: record<ClusterSecurityGroupName: record, Description: record, EC2SecurityGroups: record, IPRanges: record, Tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterSecurityGroupName" $cluster_security_group_name "scalar") (serialize-qp "CIDRIP" $cidrip "scalar") (serialize-qp "EC2SecurityGroupName" $ec2_security_group_name "scalar") (serialize-qp "EC2SecurityGroupOwnerId" $ec2_security_group_owner_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterSecurityGroupName": $cluster_security_group_name, "CIDRIP": $cidrip, "EC2SecurityGroupName": $ec2_security_group_name, "EC2SecurityGroupOwnerId": $ec2_security_group_owner_id, "Action": $action, "Version": $version} | compact), body: null}
}

# Revokes an ingress rule in an Amazon Redshift security group for a previously authorized IP range or Amazon EC2 security group. To add an ingress rule, see AuthorizeClusterSecurityGroupIngress. For information about managing security groups, go to Amazon Redshift Cluster Security Groups (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-security-groups.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_RevokeClusterSecurityGroupIngress
export def "api create-delete-security-group-ingress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-114
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<ClusterSecurityGroup: record<ClusterSecurityGroupName: record, Description: record, EC2SecurityGroups: record, IPRanges: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Revokes access to a cluster.
#
# GET /
# operationId: GET_RevokeEndpointAccess
export def "api get-delete-endpoint-access-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The cluster to revoke access from.
  --account: string # The Amazon Web Services account ID whose access is to be revoked.
  --vpc-ids: list # The virtual private cloud (VPC) identifiers for which access is to be revoked.
  --force: oneof<nothing, bool> # Indicates whether to force the revoke action. If true, the Redshift-managed VPC endpoints associated with the endpoint authorization are also deleted.
  --action: string@action-completer-115
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Grantor: record, Grantee: record, ClusterIdentifier: record, AuthorizeTime: record, ClusterStatus: record, Status: record, AllowedAllVPCs: record, AllowedVPCs: record, EndpointCount: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "Account" $account "scalar") (serialize-qp "VpcIds" $vpc_ids "multi") (serialize-qp "Force" $force "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "Account": $account, "VpcIds": $vpc_ids, "Force": $force, "Action": $action, "Version": $version} | compact), body: null}
}

# Revokes access to a cluster.
#
# POST /
# operationId: POST_RevokeEndpointAccess
export def "api create-delete-endpoint-access-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-115
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Grantor: record, Grantee: record, ClusterIdentifier: record, AuthorizeTime: record, ClusterStatus: record, Status: record, AllowedAllVPCs: record, AllowedVPCs: record, EndpointCount: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Removes the ability of the specified Amazon Web Services account to restore the specified snapshot. If the account is currently restoring the snapshot, the restore will run to completion. For more information about working with snapshots, go to Amazon Redshift Snapshots (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-snapshots.html) in the Amazon Redshift Cluster Management Guide.
#
# GET /
# operationId: GET_RevokeSnapshotAccess
export def "api get-delete-snapshot-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-identifier: string # The identifier of the snapshot that the account can no longer access.
  --snapshot-arn: string # The Amazon Resource Name (ARN) of the snapshot associated with the message to revoke access.
  --snapshot-cluster-identifier: string # The identifier of the cluster the snapshot was created from. This parameter is required if your IAM user or role has a policy containing a snapshot resource element that specifies anything other than * for the cluster name.
  --account-with-restore-access: string # The identifier of the Amazon Web Services account that can no longer restore the specified snapshot.
  --action: string@action-completer-116
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Snapshot: record<SnapshotIdentifier: record, ClusterIdentifier: record, SnapshotCreateTime: record, Status: record, Port: record, AvailabilityZone: record, ClusterCreateTime: record, MasterUsername: record, ClusterVersion: record, EngineFullVersion: record, SnapshotType: record, NodeType: record, NumberOfNodes: record, DBName: record, VpcId: record, Encrypted: record, KmsKeyId: record, EncryptedWithHSM: record, AccountsWithRestoreAccess: record, OwnerAccount: record, TotalBackupSizeInMegaBytes: record, ActualIncrementalBackupSizeInMegaBytes: record, BackupProgressInMegaBytes: record, CurrentBackupRateInMegaBytesPerSecond: record, EstimatedSecondsToCompletion: record, ElapsedTimeInSeconds: record, SourceRegion: record, Tags: record, RestorableNodeTypes: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, ManualSnapshotRetentionPeriod: record, ManualSnapshotRemainingDays: record, SnapshotRetentionStartTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SnapshotIdentifier" $snapshot_identifier "scalar") (serialize-qp "SnapshotArn" $snapshot_arn "scalar") (serialize-qp "SnapshotClusterIdentifier" $snapshot_cluster_identifier "scalar") (serialize-qp "AccountWithRestoreAccess" $account_with_restore_access "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SnapshotIdentifier": $snapshot_identifier, "SnapshotArn": $snapshot_arn, "SnapshotClusterIdentifier": $snapshot_cluster_identifier, "AccountWithRestoreAccess": $account_with_restore_access, "Action": $action, "Version": $version} | compact), body: null}
}

# Removes the ability of the specified Amazon Web Services account to restore the specified snapshot. If the account is currently restoring the snapshot, the restore will run to completion. For more information about working with snapshots, go to Amazon Redshift Snapshots (https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-snapshots.html) in the Amazon Redshift Cluster Management Guide.
#
# POST /
# operationId: POST_RevokeSnapshotAccess
export def "api create-delete-snapshot-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-116
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Snapshot: record<SnapshotIdentifier: record, ClusterIdentifier: record, SnapshotCreateTime: record, Status: record, Port: record, AvailabilityZone: record, ClusterCreateTime: record, MasterUsername: record, ClusterVersion: record, EngineFullVersion: record, SnapshotType: record, NodeType: record, NumberOfNodes: record, DBName: record, VpcId: record, Encrypted: record, KmsKeyId: record, EncryptedWithHSM: record, AccountsWithRestoreAccess: record, OwnerAccount: record, TotalBackupSizeInMegaBytes: record, ActualIncrementalBackupSizeInMegaBytes: record, BackupProgressInMegaBytes: record, CurrentBackupRateInMegaBytesPerSecond: record, EstimatedSecondsToCompletion: record, ElapsedTimeInSeconds: record, SourceRegion: record, Tags: record, RestorableNodeTypes: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, ManualSnapshotRetentionPeriod: record, ManualSnapshotRemainingDays: record, SnapshotRetentionStartTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Rotates the encryption keys for a cluster.
#
# GET /
# operationId: GET_RotateEncryptionKey
export def "api get-rotate-encryption-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-identifier: string # The unique identifier of the cluster that you want to rotate the encryption keys for. Constraints: Must be the name of valid cluster that has encryption enabled.
  --action: string@action-completer-117
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ClusterIdentifier": $cluster_identifier, "Action": $action, "Version": $version} | compact), body: null}
}

# Rotates the encryption keys for a cluster.
#
# POST /
# operationId: POST_RotateEncryptionKey
export def "api create-rotate-encryption-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-117
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<Cluster: record<ClusterIdentifier: record, NodeType: record, ClusterStatus: record, ClusterAvailabilityStatus: record, ModifyStatus: record, MasterUsername: record, DBName: record, Endpoint: record<Address: record, Port: record, VpcEndpoints: record>, ClusterCreateTime: record, AutomatedSnapshotRetentionPeriod: record, ManualSnapshotRetentionPeriod: record, ClusterSecurityGroups: record, VpcSecurityGroups: record, ClusterParameterGroups: record, ClusterSubnetGroupName: record, VpcId: record, AvailabilityZone: record, PreferredMaintenanceWindow: record, PendingModifiedValues: record<MasterUserPassword: record, NodeType: record, NumberOfNodes: record, ClusterType: record, ClusterVersion: record, AutomatedSnapshotRetentionPeriod: record, ClusterIdentifier: record, PubliclyAccessible: record, EnhancedVpcRouting: record, MaintenanceTrackName: record, EncryptionType: record>, ClusterVersion: record, AllowVersionUpgrade: record, NumberOfNodes: record, PubliclyAccessible: record, Encrypted: record, RestoreStatus: record<Status: record, CurrentRestoreRateInMegaBytesPerSecond: record, SnapshotSizeInMegaBytes: record, ProgressInMegaBytes: record, ElapsedTimeInSeconds: record, EstimatedTimeToCompletionInSeconds: record>, DataTransferProgress: record<Status: record, CurrentRateInMegaBytesPerSecond: record, TotalDataInMegaBytes: record, DataTransferredInMegaBytes: record, EstimatedTimeToCompletionInSeconds: record, ElapsedTimeInSeconds: record>, HsmStatus: record<HsmClientCertificateIdentifier: record, HsmConfigurationIdentifier: record, Status: record>, ClusterSnapshotCopyStatus: record<DestinationRegion: record, RetentionPeriod: record, ManualSnapshotRetentionPeriod: record, SnapshotCopyGrantName: record>, ClusterPublicKey: record, ClusterNodes: record, ElasticIpStatus: record<ElasticIp: record, Status: record>, ClusterRevisionNumber: record, Tags: record, KmsKeyId: record, EnhancedVpcRouting: record, IamRoles: record, PendingActions: record, MaintenanceTrackName: record, ElasticResizeNumberOfNodeOptions: record, DeferredMaintenanceWindows: record, SnapshotScheduleIdentifier: record, SnapshotScheduleState: record, ExpectedNextSnapshotScheduleTime: record, ExpectedNextSnapshotScheduleTimeStatus: record, NextMaintenanceWindowStartTime: record, ResizeInfo: record<ResizeType: record, AllowCancelResize: record>, AvailabilityZoneRelocationStatus: record, ClusterNamespaceArn: record, TotalStorageCapacityInMegaBytes: record, AquaConfiguration: record<AquaStatus: record, AquaConfigurationStatus: record>, DefaultIamRoleArn: record, ReservedNodeExchangeStatus: record<ReservedNodeExchangeRequestId: record, Status: record, RequestTime: record, SourceReservedNodeId: record, SourceReservedNodeType: record, SourceReservedNodeCount: record, TargetReservedNodeOfferingId: record, TargetReservedNodeType: record, TargetReservedNodeCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Updates the status of a partner integration.
#
# GET /
# operationId: GET_UpdatePartnerStatus
export def "api get-update-partner-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The Amazon Web Services account ID that owns the cluster.
  --cluster-identifier: string # The cluster identifier of the cluster whose partner integration status is being updated.
  --database-name: string # The name of the database whose partner integration status is being updated.
  --partner-name: string # The name of the partner whose integration status is being updated.
  --status: string@status-completer-2 # The value of the updated status.
  --status-message: string # The status message provided by the partner.
  --action: string@action-completer-118
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DatabaseName: record, PartnerName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AccountId" $account_id "scalar") (serialize-qp "ClusterIdentifier" $cluster_identifier "scalar") (serialize-qp "DatabaseName" $database_name "scalar") (serialize-qp "PartnerName" $partner_name "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "StatusMessage" $status_message "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AccountId": $account_id, "ClusterIdentifier": $cluster_identifier, "DatabaseName": $database_name, "PartnerName": $partner_name, "Status": $status, "StatusMessage": $status_message, "Action": $action, "Version": $version} | compact), body: null}
}

# Updates the status of a partner integration.
#
# POST /
# operationId: POST_UpdatePartnerStatus
export def "api create-update-partner-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-118
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> record<DatabaseName: record, PartnerName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}
