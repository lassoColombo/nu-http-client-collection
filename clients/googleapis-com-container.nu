# Auto-generated client for Kubernetes Engine API vv1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/container/v1beta1/openapi.json
# Auth: --token flag or $env.KUBERNETES_ENGINE_API_TOKEN

const BASE_URL = "https://container.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KUBERNETES_ENGINE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://container.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def action-completer [] { ["GENERATE_PASSWORD" "SET_PASSWORD" "SET_USERNAME" "UNKNOWN"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta1-projects-zones-clusters list" } } | get name | first)
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

# Lists all clusters owned by a project in either the specified zone or all zones.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/clusters
# operationId: container.projects.zones.clusters.list
export def "v1beta1-projects-zones-clusters list" [
  project_id: string
  zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --parent: string # The parent (project and location) where the clusters will be listed. Specified in the format `projects/*/locations/*`. Location "-" matches all zones and all regions.
]: nothing -> record<clusters: table<addonsConfig: record, authenticatorGroupsConfig: record, autopilot: record, autoscaling: record, binaryAuthorization: record, clusterIpv4Cidr: string, clusterTelemetry: record, conditions: list, confidentialNodes: record, costManagementConfig: record, createTime: string, currentMasterVersion: string, currentNodeCount: int, currentNodeVersion: string, databaseEncryption: record, defaultMaxPodsConstraint: record, description: string, enableKubernetesAlpha: bool, enableTpu: bool, endpoint: string, etag: string, expireTime: string, fleet: record, id: string, identityServiceConfig: record, initialClusterVersion: string, initialNodeCount: int, instanceGroupUrls: list, ipAllocationPolicy: record, labelFingerprint: string, legacyAbac: record, location: string, locations: list, loggingConfig: record, loggingService: string, maintenancePolicy: record, master: record, masterAuth: record, masterAuthorizedNetworksConfig: record, masterIpv4CidrBlock: string, meshCertificates: record, monitoringConfig: record, monitoringService: string, name: string, network: string, networkConfig: record, networkPolicy: record, nodeConfig: record, nodeIpv4CidrSize: int, nodePoolAutoConfig: record, nodePoolDefaults: record, nodePools: list, notificationConfig: record, podSecurityPolicyConfig: record, privateCluster: bool, privateClusterConfig: record, protectConfig: record, releaseChannel: record, resourceLabels: record, resourceUsageExportConfig: record, selfLink: string, servicesIpv4Cidr: string, shieldedNodes: record, status: string, statusMessage: string, subnetwork: string, tpuConfig: record, tpuIpv4CidrBlock: string, verticalPodAutoscaling: record, workloadAltsConfig: record, workloadCertificates: record, workloadIdentityConfig: record, zone: string>, missingZones: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "parent": $parent} | compact), body: null}
}

# Creates a cluster, consisting of the specified number and type of Google Compute Engine instances. By default, the cluster is created in the project's [default network](https://cloud.google.com/compute/docs/networks-and-firewalls#networks). One firewall is added for the cluster. After cluster creation, the Kubelet creates routes for each node to allow the containers on that node to communicate with all other instances in the cluster. Finally, an entry is added to the project's global metadata indicating which CIDR range the cluster is using.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters
# operationId: container.projects.zones.clusters.create
# --cluster shape: {addonsConfig?: record, authenticatorGroupsConfig?: record, autopilot?: record, autoscaling?: record, binaryAuthorization?: record, clusterIpv4Cidr?: string, clusterTelemetry?: record, conditions?: list, confidentialNodes?: record, costManagementConfig?: record, createTime?: string, currentMasterVersion?: string, currentNodeCount?: int, currentNodeVersion?: string, databaseEncryption?: record, defaultMaxPodsConstraint?: record, description?: string, enableKubernetesAlpha?: bool, enableTpu?: bool, ... (53 more fields)}
export def "v1beta1-projects-zones-clusters create" [
  project_id: string
  zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster: record # A Google Kubernetes Engine cluster. — shape: {addonsConfig?: record, authenticatorGroupsConfig?: record, autopilot?: record, autoscaling?: record, binaryAuthorization?: record, clusterIpv4Cidr?: string, clusterTelemetry?: record, conditions?: list, confidentialNodes?: record, costManagementConfig?: record, createTime?: string, currentMasterVersion?: string, currentNodeCount?: int, currentNodeVersion?: string, databaseEncryption?: record, defaultMaxPodsConstraint?: record, description?: string, enableKubernetesAlpha?: bool, enableTpu?: bool, ... (53 more fields)}
  --parent: string # The parent (project and location) where the cluster will be created. Specified in the format `projects/*/locations/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the parent field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters") $qp)
  let req_body = {"cluster": $cluster, "parent": $parent, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes the cluster, including the Kubernetes endpoint and all worker nodes. Firewalls and routes that were configured during cluster creation are also deleted. Other Google Compute Engine resources that might be in use by the cluster, such as load balancer resources, are not deleted if they weren't present when the cluster was initially created.
#
# DELETE /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}
# operationId: container.projects.zones.clusters.delete
export def "v1beta1-projects-zones-clusters delete" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project, location, cluster) of the cluster to delete. Specified in the format `projects/*/locations/*/clusters/*`.
]: nothing -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "name": $name} | compact), body: null}
}

# Gets the details for a specific cluster.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}
# operationId: container.projects.zones.clusters.get
export def "v1beta1-projects-zones-clusters get" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project, location, cluster) of the cluster to retrieve. Specified in the format `projects/*/locations/*/clusters/*`.
]: nothing -> record<addonsConfig: record<cloudRunConfig: record<disabled: bool, loadBalancerType: string>, configConnectorConfig: record<enabled: bool>, dnsCacheConfig: record<enabled: bool>, gcePersistentDiskCsiDriverConfig: record<enabled: bool>, gcpFilestoreCsiDriverConfig: record<enabled: bool>, gkeBackupAgentConfig: record<enabled: bool>, horizontalPodAutoscaling: record<disabled: bool>, httpLoadBalancing: record<disabled: bool>, istioConfig: record<auth: string, disabled: bool>, kalmConfig: record<enabled: bool>, kubernetesDashboard: record<disabled: bool>, networkPolicyConfig: record<disabled: bool>>, authenticatorGroupsConfig: record<enabled: bool, securityGroup: string>, autopilot: record<enabled: bool>, autoscaling: record<autoprovisioningLocations: list<string>, autoprovisioningNodePoolDefaults: record<bootDiskKmsKey: string, diskSizeGb: int, diskType: string, imageType: string, management: record, minCpuPlatform: string, oauthScopes: list, serviceAccount: string, shieldedInstanceConfig: record, upgradeSettings: record>, autoscalingProfile: string, enableNodeAutoprovisioning: bool, resourceLimits: list<record>>, binaryAuthorization: record<enabled: bool, evaluationMode: string>, clusterIpv4Cidr: string, clusterTelemetry: record<type: string>, conditions: table<canonicalCode: string, code: string, message: string>, confidentialNodes: record<enabled: bool>, costManagementConfig: record<enabled: bool>, createTime: string, currentMasterVersion: string, currentNodeCount: int, currentNodeVersion: string, databaseEncryption: record<keyName: string, state: string>, defaultMaxPodsConstraint: record<maxPodsPerNode: string>, description: string, enableKubernetesAlpha: bool, enableTpu: bool, endpoint: string, etag: string, expireTime: string, fleet: record<membership: string, preRegistered: bool, project: string>, id: string, identityServiceConfig: record<enabled: bool>, initialClusterVersion: string, initialNodeCount: int, instanceGroupUrls: list<string>, ipAllocationPolicy: record<additionalPodRangesConfig: record<podRangeNames: list>, allowRouteOverlap: bool, clusterIpv4Cidr: string, clusterIpv4CidrBlock: string, clusterSecondaryRangeName: string, createSubnetwork: bool, ipv6AccessType: string, nodeIpv4Cidr: string, nodeIpv4CidrBlock: string, podCidrOverprovisionConfig: record<disable: bool>, servicesIpv4Cidr: string, servicesIpv4CidrBlock: string, servicesIpv6CidrBlock: string, servicesSecondaryRangeName: string, stackType: string, subnetIpv6CidrBlock: string, subnetworkName: string, tpuIpv4CidrBlock: string, useIpAliases: bool, useRoutes: bool>, labelFingerprint: string, legacyAbac: record<enabled: bool>, location: string, locations: list<string>, loggingConfig: record<componentConfig: record<enableComponents: list>>, loggingService: string, maintenancePolicy: record<resourceVersion: string, window: record<dailyMaintenanceWindow: record, maintenanceExclusions: record, recurringWindow: record>>, master: record, masterAuth: record<clientCertificate: string, clientCertificateConfig: record<issueClientCertificate: bool>, clientKey: string, clusterCaCertificate: string, password: string, username: string>, masterAuthorizedNetworksConfig: record<cidrBlocks: list<record>, enabled: bool, gcpPublicCidrsAccessEnabled: bool>, masterIpv4CidrBlock: string, meshCertificates: record<enableCertificates: bool>, monitoringConfig: record<componentConfig: record<enableComponents: list>, managedPrometheusConfig: record<enabled: bool>>, monitoringService: string, name: string, network: string, networkConfig: record<datapathProvider: string, defaultSnatStatus: record<disabled: bool>, dnsConfig: record<clusterDns: string, clusterDnsDomain: string, clusterDnsScope: string>, enableIntraNodeVisibility: bool, enableL4ilbSubsetting: bool, gatewayApiConfig: record<channel: string>, network: string, privateIpv6GoogleAccess: string, serviceExternalIpsConfig: record<enabled: bool>, subnetwork: string>, networkPolicy: record<enabled: bool, provider: string>, nodeConfig: record<accelerators: list<record>, advancedMachineFeatures: record<threadsPerCore: string>, bootDiskKmsKey: string, confidentialNodes: record<enabled: bool>, diskSizeGb: int, diskType: string, ephemeralStorageConfig: record<localSsdCount: int>, ephemeralStorageLocalSsdConfig: record<localSsdCount: int>, fastSocket: record<enabled: bool>, gcfsConfig: record<enabled: bool>, gvnic: record<enabled: bool>, imageType: string, kubeletConfig: record<cpuCfsQuota: bool, cpuCfsQuotaPeriod: string, cpuManagerPolicy: string, podPidsLimit: string>, labels: record, linuxNodeConfig: record<cgroupMode: string, sysctls: record>, localNvmeSsdBlockConfig: record<localSsdCount: int>, localSsdCount: int, loggingConfig: record<variantConfig: record>, machineType: string, metadata: record, minCpuPlatform: string, nodeGroup: string, oauthScopes: list<string>, preemptible: bool, reservationAffinity: record<consumeReservationType: string, key: string, values: list>, resourceLabels: record, sandboxConfig: record<sandboxType: string, type: string>, serviceAccount: string, shieldedInstanceConfig: record<enableIntegrityMonitoring: bool, enableSecureBoot: bool>, spot: bool, tags: list<string>, taints: list<record>, windowsNodeConfig: record<osVersion: string>, workloadMetadataConfig: record<mode: string, nodeMetadata: string>>, nodeIpv4CidrSize: int, nodePoolAutoConfig: record<networkTags: record<tags: list>>, nodePoolDefaults: record<nodeConfigDefaults: record<gcfsConfig: record, loggingConfig: record>>, nodePools: table<autoscaling: record, conditions: list, config: record, etag: string, initialNodeCount: int, instanceGroupUrls: list, locations: list, management: record, maxPodsConstraint: record, name: string, networkConfig: record, placementPolicy: record, podIpv4CidrSize: int, selfLink: string, status: string, statusMessage: string, updateInfo: record, upgradeSettings: record, version: string>, notificationConfig: record<pubsub: record<enabled: bool, filter: record, topic: string>>, podSecurityPolicyConfig: record<enabled: bool>, privateCluster: bool, privateClusterConfig: record<enablePrivateEndpoint: bool, enablePrivateNodes: bool, masterGlobalAccessConfig: record<enabled: bool>, masterIpv4CidrBlock: string, peeringName: string, privateEndpoint: string, privateEndpointSubnetwork: string, publicEndpoint: string>, protectConfig: record<workloadConfig: record<auditMode: string>, workloadVulnerabilityMode: string>, releaseChannel: record<channel: string>, resourceLabels: record, resourceUsageExportConfig: record<bigqueryDestination: record<datasetId: string>, consumptionMeteringConfig: record<enabled: bool>, enableNetworkEgressMetering: bool>, selfLink: string, servicesIpv4Cidr: string, shieldedNodes: record<enabled: bool>, status: string, statusMessage: string, subnetwork: string, tpuConfig: record<enabled: bool, ipv4CidrBlock: string, useServiceNetworking: bool>, tpuIpv4CidrBlock: string, verticalPodAutoscaling: record<enabled: bool>, workloadAltsConfig: record<enableAlts: bool>, workloadCertificates: record<enableCertificates: bool>, workloadIdentityConfig: record<identityNamespace: string, identityProvider: string, workloadPool: string>, zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "name": $name} | compact), body: null}
}

# Updates the settings for a specific cluster.
#
# PUT /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}
# operationId: container.projects.zones.clusters.update
# --update shape: {additionalPodRangesConfig?: record, desiredAddonsConfig?: record, desiredAuthenticatorGroupsConfig?: record, desiredBinaryAuthorization?: record, desiredClusterAutoscaling?: record, desiredClusterTelemetry?: record, desiredCostManagementConfig?: record, desiredDatabaseEncryption?: record, desiredDatapathProvider?: "DATAPATH_PROVIDER_UNSPECIFIED"|"LEGACY_DATAPATH"|"ADVANCED_DATAPATH", desiredDefaultSnatStatus?: record, desiredDnsConfig?: record, desiredEnablePrivateEndpoint?: bool, ... (37 more fields)}
export def "v1beta1-projects-zones-clusters update" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --name: string # The name (project, location, cluster) of the cluster to update. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --update: record # ClusterUpdate describes an update to the cluster. Exactly one update can be applied to a cluster with each request, so at most one field can be provided. — shape: {additionalPodRangesConfig?: record, desiredAddonsConfig?: record, desiredAuthenticatorGroupsConfig?: record, desiredBinaryAuthorization?: record, desiredClusterAutoscaling?: record, desiredClusterTelemetry?: record, desiredCostManagementConfig?: record, desiredDatabaseEncryption?: record, desiredDatapathProvider?: "DATAPATH_PROVIDER_UNSPECIFIED"|"LEGACY_DATAPATH"|"ADVANCED_DATAPATH", desiredDefaultSnatStatus?: record, desiredDnsConfig?: record, desiredEnablePrivateEndpoint?: bool, ... (37 more fields)}
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}") $qp)
  let req_body = {"clusterId": $body_cluster_id, "name": $name, "projectId": $body_project_id, "update": $update, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the addons for a specific cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/addons
# operationId: container.projects.zones.clusters.addons
# --addonsConfig shape: {cloudRunConfig?: record, configConnectorConfig?: record, dnsCacheConfig?: record, gcePersistentDiskCsiDriverConfig?: record, gcpFilestoreCsiDriverConfig?: record, gkeBackupAgentConfig?: record, horizontalPodAutoscaling?: record, httpLoadBalancing?: record, istioConfig?: record, kalmConfig?: record, kubernetesDashboard?: record, networkPolicyConfig?: record}
export def "v1beta1-projects-zones-clusters-addons create" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --addons-config: record # Configuration for the addons that can be automatically spun up in the cluster, enabling additional functionality. — shape: {cloudRunConfig?: record, configConnectorConfig?: record, dnsCacheConfig?: record, gcePersistentDiskCsiDriverConfig?: record, gcpFilestoreCsiDriverConfig?: record, gkeBackupAgentConfig?: record, horizontalPodAutoscaling?: record, httpLoadBalancing?: record, istioConfig?: record, kalmConfig?: record, kubernetesDashboard?: record, networkPolicyConfig?: record}
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --name: string # The name (project, location, cluster) of the cluster to set addons. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/addons") $qp)
  let req_body = {"addonsConfig": $addons_config, "clusterId": $body_cluster_id, "name": $name, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Enables or disables the ABAC authorization mechanism on a cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/legacyAbac
# operationId: container.projects.zones.clusters.legacyAbac
export def "v1beta1-projects-zones-clusters-legacy-abac create" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to update. This field has been deprecated and replaced by the name field.
  --enabled: oneof<nothing, bool> # Required. Whether ABAC authorization will be enabled in the cluster.
  --name: string # The name (project, location, cluster name) of the cluster to set legacy abac. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/legacyAbac") $qp)
  let req_body = {"clusterId": $body_cluster_id, "enabled": $enabled, "name": $name, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the locations for a specific cluster. Deprecated. Use [projects.locations.clusters.update](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1beta1/projects.locations.clusters/update) instead.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/locations
# operationId: container.projects.zones.clusters.locations
export def "v1beta1-projects-zones-clusters-locations create" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --locations: list<string> # Required. The desired list of Google Compute Engine [zones](https://cloud.google.com/compute/docs/zones#available) in which the cluster's nodes should be located. Changing the locations a cluster is in will result in nodes being either created or removed from the cluster, depending on whether locations are being added or removed. This list must always include the cluster's primary zone.
  --name: string # The name (project, location, cluster) of the cluster to set locations. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/locations") $qp)
  let req_body = {"clusterId": $body_cluster_id, "locations": $locations, "name": $name, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the logging service for a specific cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/logging
# operationId: container.projects.zones.clusters.logging
export def "v1beta1-projects-zones-clusters-logging create" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --logging-service: string # Required. The logging service the cluster should use to write logs. Currently available options: * `logging.googleapis.com/kubernetes` - The Cloud Logging service with a Kubernetes-native resource model * `logging.googleapis.com` - The legacy Cloud Logging service (no longer available as of GKE 1.15). * `none` - no logs will be exported from the cluster. If left as an empty string,`logging.googleapis.com/kubernetes` will be used for GKE 1.14+ or `logging.googleapis.com` for earlier versions.
  --name: string # The name (project, location, cluster) of the cluster to set logging. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/logging") $qp)
  let req_body = {"clusterId": $body_cluster_id, "loggingService": $logging_service, "name": $name, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates the master for a specific cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/master
# operationId: container.projects.zones.clusters.master
export def "v1beta1-projects-zones-clusters-master create" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --master-version: string # Required. The Kubernetes version to change the master to. Users may specify either explicit versions offered by Kubernetes Engine or version aliases, which have the following behavior: - "latest": picks the highest valid Kubernetes version - "1.X": picks the highest valid patch+gke.N patch in the 1.X version - "1.X.Y": picks the highest valid gke.N patch in the 1.X.Y version - "1.X.Y-gke.N": picks an explicit Kubernetes version - "-": picks the default Kubernetes version
  --name: string # The name (project, location, cluster) of the cluster to update. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/master") $qp)
  let req_body = {"clusterId": $body_cluster_id, "masterVersion": $master_version, "name": $name, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the monitoring service for a specific cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/monitoring
# operationId: container.projects.zones.clusters.monitoring
export def "v1beta1-projects-zones-clusters-monitoring create" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --monitoring-service: string # Required. The monitoring service the cluster should use to write metrics. Currently available options: * "monitoring.googleapis.com/kubernetes" - The Cloud Monitoring service with a Kubernetes-native resource model * `monitoring.googleapis.com` - The legacy Cloud Monitoring service (no longer available as of GKE 1.15). * `none` - No metrics will be exported from the cluster. If left as an empty string,`monitoring.googleapis.com/kubernetes` will be used for GKE 1.14+ or `monitoring.googleapis.com` for earlier versions.
  --name: string # The name (project, location, cluster) of the cluster to set monitoring. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/monitoring") $qp)
  let req_body = {"clusterId": $body_cluster_id, "monitoringService": $monitoring_service, "name": $name, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists the node pools for a cluster.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools
# operationId: container.projects.zones.clusters.nodePools.list
export def "v1beta1-projects-zones-clusters-node-pools list" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --parent: string # The parent (project, location, cluster name) where the node pools will be listed. Specified in the format `projects/*/locations/*/clusters/*`.
]: nothing -> record<nodePools: table<autoscaling: record, conditions: list, config: record, etag: string, initialNodeCount: int, instanceGroupUrls: list, locations: list, management: record, maxPodsConstraint: record, name: string, networkConfig: record, placementPolicy: record, podIpv4CidrSize: int, selfLink: string, status: string, statusMessage: string, updateInfo: record, upgradeSettings: record, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/nodePools") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "parent": $parent} | compact), body: null}
}

# Creates a node pool for a cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools
# operationId: container.projects.zones.clusters.nodePools.create
# --nodePool shape: {autoscaling?: record, conditions?: list, config?: record, etag?: string, initialNodeCount?: int, instanceGroupUrls?: list<string>, locations?: list<string>, management?: record, maxPodsConstraint?: record, name?: string, networkConfig?: record, placementPolicy?: record, podIpv4CidrSize?: int, selfLink?: string, status?: "STATUS_UNSPECIFIED"|"PROVISIONING"|"RUNNING"|"RUNNING_WITH_ERROR"|"RECONCILING"|"STOPPING"|"ERROR", statusMessage?: string, updateInfo?: record, upgradeSettings?: record, ... (1 more fields)}
export def "v1beta1-projects-zones-clusters-node-pools create" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the parent field.
  --node-pool: record # NodePool contains the name and configuration for a cluster's node pool. Node pools are a set of nodes (i.e. VM's), with a common configuration and specification, under the control of the cluster master. They may have a set of Kubernetes labels applied to them, which may be used to reference them during pod scheduling. They may also be resized up or down, to accommodate the workload. These upgrade settings control the level of parallelism and the level of disruption caused by an upgrade. maxUnavailable controls the number of nodes that can be simultaneously unavailable. maxSurge controls the number of additional nodes that can be added to the node pool temporarily for the time of the upgrade to increase the number of available nodes. (maxUnavailable + maxSurge) determines the level of parallelism (how many nodes are being upgraded at the same time). Note: upgrades inevitably introduce some disruption since workloads need to be moved from old nodes to new, upgraded ones. Even if maxUnavailable=0, this holds true. (Disruption stays within the limits of PodDisruptionBudget, if it is configured.) Consider a hypothetical node pool with 5 nodes having maxSurge=2, maxUnavailable=1. This means the upgrade process upgrades 3 nodes simultaneously. It creates 2 additional (upgraded) nodes, then it brings down 3 old (not yet upgraded) nodes at the same time. This ensures that there are always at least 4 nodes available. — shape: {autoscaling?: record, conditions?: list, config?: record, etag?: string, initialNodeCount?: int, instanceGroupUrls?: list<string>, locations?: list<string>, management?: record, maxPodsConstraint?: record, name?: string, networkConfig?: record, placementPolicy?: record, podIpv4CidrSize?: int, selfLink?: string, status?: "STATUS_UNSPECIFIED"|"PROVISIONING"|"RUNNING"|"RUNNING_WITH_ERROR"|"RECONCILING"|"STOPPING"|"ERROR", statusMessage?: string, updateInfo?: record, upgradeSettings?: record, ... (1 more fields)}
  --parent: string # The parent (project, location, cluster name) where the node pool will be created. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the parent field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/nodePools") $qp)
  let req_body = {"clusterId": $body_cluster_id, "nodePool": $node_pool, "parent": $parent, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes a node pool from a cluster.
#
# DELETE /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}
# operationId: container.projects.zones.clusters.nodePools.delete
export def "v1beta1-projects-zones-clusters-node-pools delete" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project, location, cluster, node pool id) of the node pool to delete. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
]: nothing -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  if ($node_pool_id | is-empty) { error make --unspanned { msg: "path parameter 'nodePoolId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/nodePools/{node_pool_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "name": $name} | compact), body: null}
}

# Retrieves the requested node pool.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}
# operationId: container.projects.zones.clusters.nodePools.get
export def "v1beta1-projects-zones-clusters-node-pools get" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project, location, cluster, node pool id) of the node pool to get. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
]: nothing -> record<autoscaling: record<autoprovisioned: bool, enabled: bool, locationPolicy: string, maxNodeCount: int, minNodeCount: int, totalMaxNodeCount: int, totalMinNodeCount: int>, conditions: table<canonicalCode: string, code: string, message: string>, config: record<accelerators: list<record>, advancedMachineFeatures: record<threadsPerCore: string>, bootDiskKmsKey: string, confidentialNodes: record<enabled: bool>, diskSizeGb: int, diskType: string, ephemeralStorageConfig: record<localSsdCount: int>, ephemeralStorageLocalSsdConfig: record<localSsdCount: int>, fastSocket: record<enabled: bool>, gcfsConfig: record<enabled: bool>, gvnic: record<enabled: bool>, imageType: string, kubeletConfig: record<cpuCfsQuota: bool, cpuCfsQuotaPeriod: string, cpuManagerPolicy: string, podPidsLimit: string>, labels: record, linuxNodeConfig: record<cgroupMode: string, sysctls: record>, localNvmeSsdBlockConfig: record<localSsdCount: int>, localSsdCount: int, loggingConfig: record<variantConfig: record>, machineType: string, metadata: record, minCpuPlatform: string, nodeGroup: string, oauthScopes: list<string>, preemptible: bool, reservationAffinity: record<consumeReservationType: string, key: string, values: list>, resourceLabels: record, sandboxConfig: record<sandboxType: string, type: string>, serviceAccount: string, shieldedInstanceConfig: record<enableIntegrityMonitoring: bool, enableSecureBoot: bool>, spot: bool, tags: list<string>, taints: list<record>, windowsNodeConfig: record<osVersion: string>, workloadMetadataConfig: record<mode: string, nodeMetadata: string>>, etag: string, initialNodeCount: int, instanceGroupUrls: list<string>, locations: list<string>, management: record<autoRepair: bool, autoUpgrade: bool, upgradeOptions: record<autoUpgradeStartTime: string, description: string>>, maxPodsConstraint: record<maxPodsPerNode: string>, name: string, networkConfig: record<createPodRange: bool, enablePrivateNodes: bool, networkPerformanceConfig: record<externalIpEgressBandwidthTier: string, totalEgressBandwidthTier: string>, podCidrOverprovisionConfig: record<disable: bool>, podIpv4CidrBlock: string, podRange: string>, placementPolicy: record<type: string>, podIpv4CidrSize: int, selfLink: string, status: string, statusMessage: string, updateInfo: record<blueGreenInfo: record<blueInstanceGroupUrls: list, bluePoolDeletionStartTime: string, greenInstanceGroupUrls: list, greenPoolVersion: string, phase: string>>, upgradeSettings: record<blueGreenSettings: record<nodePoolSoakDuration: string, standardRolloutPolicy: record>, maxSurge: int, maxUnavailable: int, strategy: string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  if ($node_pool_id | is-empty) { error make --unspanned { msg: "path parameter 'nodePoolId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/nodePools/{node_pool_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "name": $name} | compact), body: null}
}

# Sets the autoscaling settings of a specific node pool.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}/autoscaling
# operationId: container.projects.zones.clusters.nodePools.autoscaling
# --autoscaling shape: {autoprovisioned?: bool, enabled?: bool, locationPolicy?: "LOCATION_POLICY_UNSPECIFIED"|"BALANCED"|"ANY", maxNodeCount?: int, minNodeCount?: int, totalMaxNodeCount?: int, totalMinNodeCount?: int}
export def "v1beta1-projects-zones-clusters-node-pools-autoscaling create" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --autoscaling: record # NodePoolAutoscaling contains information required by cluster autoscaler to adjust the size of the node pool to the current cluster usage. — shape: {autoprovisioned?: bool, enabled?: bool, locationPolicy?: "LOCATION_POLICY_UNSPECIFIED"|"BALANCED"|"ANY", maxNodeCount?: int, minNodeCount?: int, totalMaxNodeCount?: int, totalMinNodeCount?: int}
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --name: string # The name (project, location, cluster, node pool) of the node pool to set autoscaler settings. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --body-node-pool-id: string # Required. Deprecated. The name of the node pool to upgrade. This field has been deprecated and replaced by the name field.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  if ($node_pool_id | is-empty) { error make --unspanned { msg: "path parameter 'nodePoolId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/nodePools/{node_pool_id}/autoscaling") $qp)
  let req_body = {"autoscaling": $autoscaling, "clusterId": $body_cluster_id, "name": $name, "nodePoolId": $body_node_pool_id, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the NodeManagement options for a node pool.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}/setManagement
# operationId: container.projects.zones.clusters.nodePools.setManagement
# --management shape: {autoRepair?: bool, autoUpgrade?: bool, upgradeOptions?: record}
export def "v1beta1-projects-zones-clusters-node-pools-set-management update" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to update. This field has been deprecated and replaced by the name field.
  --management: record # NodeManagement defines the set of node management services turned on for the node pool. — shape: {autoRepair?: bool, autoUpgrade?: bool, upgradeOptions?: record}
  --name: string # The name (project, location, cluster, node pool id) of the node pool to set management properties. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --body-node-pool-id: string # Required. Deprecated. The name of the node pool to update. This field has been deprecated and replaced by the name field.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  if ($node_pool_id | is-empty) { error make --unspanned { msg: "path parameter 'nodePoolId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/nodePools/{node_pool_id}/setManagement") $qp)
  let req_body = {"clusterId": $body_cluster_id, "management": $management, "name": $name, "nodePoolId": $body_node_pool_id, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# SetNodePoolSizeRequest sets the size of a node pool. The new size will be used for all replicas, including future replicas created by modifying NodePool.locations.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}/setSize
# operationId: container.projects.zones.clusters.nodePools.setSize
export def "v1beta1-projects-zones-clusters-node-pools-set-size update" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to update. This field has been deprecated and replaced by the name field.
  --name: string # The name (project, location, cluster, node pool id) of the node pool to set size. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --node-count: int # Required. The desired node count for the pool. (format: int32)
  --body-node-pool-id: string # Required. Deprecated. The name of the node pool to update. This field has been deprecated and replaced by the name field.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  if ($node_pool_id | is-empty) { error make --unspanned { msg: "path parameter 'nodePoolId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/nodePools/{node_pool_id}/setSize") $qp)
  let req_body = {"clusterId": $body_cluster_id, "name": $name, "nodeCount": $node_count, "nodePoolId": $body_node_pool_id, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates the version and/or image type of a specific node pool.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}/update
# operationId: container.projects.zones.clusters.nodePools.update
# --confidentialNodes shape: {enabled?: bool}
# --fastSocket shape: {enabled?: bool}
# --gcfsConfig shape: {enabled?: bool}
# --gvnic shape: {enabled?: bool}
# --kubeletConfig shape: {cpuCfsQuota?: bool, cpuCfsQuotaPeriod?: string, cpuManagerPolicy?: string, podPidsLimit?: string}
# --labels shape: {labels?: record}
# --linuxNodeConfig shape: {cgroupMode?: "CGROUP_MODE_UNSPECIFIED"|"CGROUP_MODE_V1"|"CGROUP_MODE_V2", sysctls?: record}
# --loggingConfig shape: {variantConfig?: record}
# --nodeNetworkConfig shape: {createPodRange?: bool, enablePrivateNodes?: bool, networkPerformanceConfig?: record, podCidrOverprovisionConfig?: record, podIpv4CidrBlock?: string, podRange?: string}
# --resourceLabels shape: {labels?: record}
# --tags shape: {tags?: list<string>}
# --taints shape: {taints?: list}
# --upgradeSettings shape: {blueGreenSettings?: record, maxSurge?: int, maxUnavailable?: int, strategy?: "NODE_POOL_UPDATE_STRATEGY_UNSPECIFIED"|"BLUE_GREEN"|"SURGE"}
# --windowsNodeConfig shape: {osVersion?: "OS_VERSION_UNSPECIFIED"|"OS_VERSION_LTSC2019"|"OS_VERSION_LTSC2022"}
# --workloadMetadataConfig shape: {mode?: "MODE_UNSPECIFIED"|"GCE_METADATA"|"GKE_METADATA", nodeMetadata?: "UNSPECIFIED"|"SECURE"|"EXPOSE"|"GKE_METADATA_SERVER"}
export def "v1beta1-projects-zones-clusters-node-pools-update update" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --confidential-nodes: record # ConfidentialNodes is configuration for the confidential nodes feature, which makes nodes run on confidential VMs. — shape: {enabled?: bool}
  --etag: string # The current etag of the node pool. If an etag is provided and does not match the current etag of the node pool, update will be blocked and an ABORTED error will be returned.
  --fast-socket: record # Configuration of Fast Socket feature. — shape: {enabled?: bool}
  --gcfs-config: record # GcfsConfig contains configurations of Google Container File System. — shape: {enabled?: bool}
  --gvnic: record # Configuration of gVNIC feature. — shape: {enabled?: bool}
  --image-type: string # Required. The desired image type for the node pool. Please see https://cloud.google.com/kubernetes-engine/docs/concepts/node-images for available image types.
  --kubelet-config: record # Node kubelet configs. — shape: {cpuCfsQuota?: bool, cpuCfsQuotaPeriod?: string, cpuManagerPolicy?: string, podPidsLimit?: string}
  --labels: record # Collection of node-level [Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels). — shape: {labels?: record}
  --linux-node-config: record # Parameters that can be configured on Linux nodes. — shape: {cgroupMode?: "CGROUP_MODE_UNSPECIFIED"|"CGROUP_MODE_V1"|"CGROUP_MODE_V2", sysctls?: record}
  --locations: list<string> # The desired list of Google Compute Engine [zones](https://cloud.google.com/compute/docs/zones#available) in which the node pool's nodes should be located. Changing the locations for a node pool will result in nodes being either created or removed from the node pool, depending on whether locations are being added or removed.
  --logging-config: record # NodePoolLoggingConfig specifies logging configuration for nodepools. — shape: {variantConfig?: record}
  --name: string # The name (project, location, cluster, node pool) of the node pool to update. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --node-network-config: record # Parameters for node pool-level network config. — shape: {createPodRange?: bool, enablePrivateNodes?: bool, networkPerformanceConfig?: record, podCidrOverprovisionConfig?: record, podIpv4CidrBlock?: string, podRange?: string}
  --body-node-pool-id: string # Required. Deprecated. The name of the node pool to upgrade. This field has been deprecated and replaced by the name field.
  --node-version: string # Required. The Kubernetes version to change the nodes to (typically an upgrade). Users may specify either explicit versions offered by Kubernetes Engine or version aliases, which have the following behavior: - "latest": picks the highest valid Kubernetes version - "1.X": picks the highest valid patch+gke.N patch in the 1.X version - "1.X.Y": picks the highest valid gke.N patch in the 1.X.Y version - "1.X.Y-gke.N": picks an explicit Kubernetes version - "-": picks the Kubernetes master version
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --resource-labels: record # Collection of [GCP labels](https://cloud.google.com/resource-manager/docs/creating-managing-labels). — shape: {labels?: record}
  --tags: record # Collection of Compute Engine network tags that can be applied to a node's underlying VM instance. (See `tags` field in [`NodeConfig`](/kubernetes-engine/docs/reference/rest/v1/NodeConfig)). — shape: {tags?: list<string>}
  --taints: record # Collection of Kubernetes [node taints](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration). — shape: {taints?: list}
  --upgrade-settings: record # These upgrade settings configure the upgrade strategy for the node pool. Use strategy to switch between the strategies applied to the node pool. If the strategy is SURGE, use max_surge and max_unavailable to control the level of parallelism and the level of disruption caused by upgrade. 1. maxSurge controls the number of additional nodes that can be added to the node pool temporarily for the time of the upgrade to increase the number of available nodes. 2. maxUnavailable controls the number of nodes that can be simultaneously unavailable. 3. (maxUnavailable + maxSurge) determines the level of parallelism (how many nodes are being upgraded at the same time). If the strategy is BLUE_GREEN, use blue_green_settings to configure the blue-green upgrade related settings. 1. standard_rollout_policy is the default policy. The policy is used to control the way blue pool gets drained. The draining is executed in the batch mode. The batch size could be specified as either percentage of the node pool size or the number of nodes. batch_soak_duration is the soak time after each batch gets drained. 2. node_pool_soak_duration is the soak time after all blue nodes are drained. After this period, the blue pool nodes will be deleted. — shape: {blueGreenSettings?: record, maxSurge?: int, maxUnavailable?: int, strategy?: "NODE_POOL_UPDATE_STRATEGY_UNSPECIFIED"|"BLUE_GREEN"|"SURGE"}
  --windows-node-config: record # Parameters that can be configured on Windows nodes. Windows Node Config that define the parameters that will be used to configure the Windows node pool settings — shape: {osVersion?: "OS_VERSION_UNSPECIFIED"|"OS_VERSION_LTSC2019"|"OS_VERSION_LTSC2022"}
  --workload-metadata-config: record # WorkloadMetadataConfig defines the metadata configuration to expose to workloads on the node pool. — shape: {mode?: "MODE_UNSPECIFIED"|"GCE_METADATA"|"GKE_METADATA", nodeMetadata?: "UNSPECIFIED"|"SECURE"|"EXPOSE"|"GKE_METADATA_SERVER"}
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  if ($node_pool_id | is-empty) { error make --unspanned { msg: "path parameter 'nodePoolId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/nodePools/{node_pool_id}/update") $qp)
  let req_body = {"clusterId": $body_cluster_id, "confidentialNodes": $confidential_nodes, "etag": $etag, "fastSocket": $fast_socket, "gcfsConfig": $gcfs_config, "gvnic": $gvnic, "imageType": $image_type, "kubeletConfig": $kubelet_config, "labels": $labels, "linuxNodeConfig": $linux_node_config, "locations": $locations, "loggingConfig": $logging_config, "name": $name, "nodeNetworkConfig": $node_network_config, "nodePoolId": $body_node_pool_id, "nodeVersion": $node_version, "projectId": $body_project_id, "resourceLabels": $resource_labels, "tags": $tags, "taints": $taints, "upgradeSettings": $upgrade_settings, "windowsNodeConfig": $windows_node_config, "workloadMetadataConfig": $workload_metadata_config, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Rolls back a previously Aborted or Failed NodePool upgrade. This makes no changes if the last upgrade successfully completed.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}:rollback
# operationId: container.projects.zones.clusters.nodePools.rollback
export def "v1beta1-projects-zones-clusters-node-pools create-rollback" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to rollback. This field has been deprecated and replaced by the name field.
  --name: string # The name (project, location, cluster, node pool id) of the node poll to rollback upgrade. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --body-node-pool-id: string # Required. Deprecated. The name of the node pool to rollback. This field has been deprecated and replaced by the name field.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --respect-pdb: oneof<nothing, bool> # Option for rollback to ignore the PodDisruptionBudget. Default value is false.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  if ($node_pool_id | is-empty) { error make --unspanned { msg: "path parameter 'nodePoolId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/nodePools/{node_pool_id}:rollback") $qp)
  let req_body = {"clusterId": $body_cluster_id, "name": $name, "nodePoolId": $body_node_pool_id, "projectId": $body_project_id, "respectPdb": $respect_pdb, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets labels on a cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/resourceLabels
# operationId: container.projects.zones.clusters.resourceLabels
export def "v1beta1-projects-zones-clusters-resource-labels create" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --label-fingerprint: string # Required. The fingerprint of the previous set of labels for this resource, used to detect conflicts. The fingerprint is initially generated by Kubernetes Engine and changes after every request to modify or update labels. You must always provide an up-to-date fingerprint hash when updating or changing labels. Make a `get()` request to the resource to get the latest fingerprint.
  --name: string # The name (project, location, cluster name) of the cluster to set labels. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --resource-labels: record # Required. The labels to set for that cluster.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}/resourceLabels") $qp)
  let req_body = {"clusterId": $body_cluster_id, "labelFingerprint": $label_fingerprint, "name": $name, "projectId": $body_project_id, "resourceLabels": $resource_labels, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Completes master IP rotation.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:completeIpRotation
# operationId: container.projects.zones.clusters.completeIpRotation
export def "v1beta1-projects-zones-clusters complete-ip-rotation" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --name: string # The name (project, location, cluster name) of the cluster to complete IP rotation. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}:completeIpRotation") $qp)
  let req_body = {"clusterId": $body_cluster_id, "name": $name, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the maintenance policy for a cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:setMaintenancePolicy
# operationId: container.projects.zones.clusters.setMaintenancePolicy
# --maintenancePolicy shape: {resourceVersion?: string, window?: record}
export def "v1beta1-projects-zones-clusters update-maintenance-policy" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. The name of the cluster to update.
  --maintenance-policy: record # MaintenancePolicy defines the maintenance policy to be used for the cluster. — shape: {resourceVersion?: string, window?: record}
  --name: string # The name (project, location, cluster name) of the cluster to set maintenance policy. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
  --body-zone: string # Required. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}:setMaintenancePolicy") $qp)
  let req_body = {"clusterId": $body_cluster_id, "maintenancePolicy": $maintenance_policy, "name": $name, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets master auth materials. Currently supports changing the admin password or a specific cluster, either via password generation or explicitly setting the password.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:setMasterAuth
# operationId: container.projects.zones.clusters.setMasterAuth
# --update shape: {clientCertificate?: string, clientCertificateConfig?: record, clientKey?: string, clusterCaCertificate?: string, password?: string, username?: string}
export def "v1beta1-projects-zones-clusters update-master-auth" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --action: string@action-completer # Required. The exact form of action to be taken on the master auth.
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --name: string # The name (project, location, cluster) of the cluster to set auth. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --update: record # The authentication information for accessing the master endpoint. Authentication can be done using HTTP basic auth or using client certificates. — shape: {clientCertificate?: string, clientCertificateConfig?: record, clientKey?: string, clusterCaCertificate?: string, password?: string, username?: string}
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}:setMasterAuth") $qp)
  let req_body = {"action": $action, "clusterId": $body_cluster_id, "name": $name, "projectId": $body_project_id, "update": $update, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Enables or disables Network Policy for a cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:setNetworkPolicy
# operationId: container.projects.zones.clusters.setNetworkPolicy
# --networkPolicy shape: {enabled?: bool, provider?: "PROVIDER_UNSPECIFIED"|"CALICO"}
export def "v1beta1-projects-zones-clusters update-network-policy" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --name: string # The name (project, location, cluster name) of the cluster to set networking policy. Specified in the format `projects/*/locations/*/clusters/*`.
  --network-policy: record # Configuration options for the NetworkPolicy feature. https://kubernetes.io/docs/concepts/services-networking/networkpolicies/ — shape: {enabled?: bool, provider?: "PROVIDER_UNSPECIFIED"|"CALICO"}
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}:setNetworkPolicy") $qp)
  let req_body = {"clusterId": $body_cluster_id, "name": $name, "networkPolicy": $network_policy, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Starts master IP rotation.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:startIpRotation
# operationId: container.projects.zones.clusters.startIpRotation
export def "v1beta1-projects-zones-clusters start-ip-rotation" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --name: string # The name (project, location, cluster name) of the cluster to start IP rotation. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --rotate-credentials: oneof<nothing, bool> # Whether to rotate credentials during IP rotation.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'clusterId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/clusters/{cluster_id}:startIpRotation") $qp)
  let req_body = {"clusterId": $body_cluster_id, "name": $name, "projectId": $body_project_id, "rotateCredentials": $rotate_credentials, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists all operations in a project in the specified zone or all zones.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/operations
# operationId: container.projects.zones.operations.list
export def "v1beta1-projects-zones-operations list" [
  project_id: string
  zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --parent: string # The parent (project and location) where the operations will be listed. Specified in the format `projects/*/locations/*`. Location "-" matches all zones and all regions.
]: nothing -> record<missingZones: list<string>, operations: table<clusterConditions: list, detail: string, endTime: string, error: record, location: string, name: string, nodepoolConditions: list, operationType: string, progress: record, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/operations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "parent": $parent} | compact), body: null}
}

# Gets the specified operation.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/operations/{operationId}
# operationId: container.projects.zones.operations.get
export def "v1beta1-projects-zones-operations get" [
  project_id: string
  zone: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project, location, operation id) of the operation to get. Specified in the format `projects/*/locations/*/operations/*`.
]: nothing -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), operation_id: (encode-path-segment $operation_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/operations/{operation_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "name": $name} | compact), body: null}
}

# Cancels the specified operation.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/operations/{operationId}:cancel
# operationId: container.projects.zones.operations.cancel
export def "v1beta1-projects-zones-operations cancel" [
  project_id: string
  zone: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project, location, operation id) of the operation to cancel. Specified in the format `projects/*/locations/*/operations/*`.
  --body-operation-id: string # Required. Deprecated. The server-assigned `name` of the operation. This field has been deprecated and replaced by the name field.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the operation resides. This field has been deprecated and replaced by the name field.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone), operation_id: (encode-path-segment $operation_id)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/operations/{operation_id}:cancel") $qp)
  let req_body = {"name": $name, "operationId": $body_operation_id, "projectId": $body_project_id, "zone": $body_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Returns configuration info about the Google Kubernetes Engine service.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/serverconfig
# operationId: container.projects.zones.getServerconfig
export def "v1beta1-projects-zones-serverconfig get" [
  project_id: string
  zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project and location) of the server config to get, specified in the format `projects/*/locations/*`.
]: nothing -> record<channels: table<availableVersions: list, channel: string, defaultVersion: string, validVersions: list>, defaultClusterVersion: string, defaultImageType: string, validImageTypes: list<string>, validMasterVersions: list<string>, validNodeVersions: list<string>, windowsVersionMaps: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($zone | is-empty) { error make --unspanned { msg: "path parameter 'zone' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), zone: (encode-path-segment $zone)} | format pattern "/v1beta1/projects/{project_id}/zones/{zone}/serverconfig") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "name": $name} | compact), body: null}
}

# Deletes a node pool from a cluster.
#
# DELETE /v1beta1/{name}
# operationId: container.projects.locations.clusters.nodePools.delete
export def "v1beta1 delete" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --node-pool-id: string # Required. Deprecated. The name of the node pool to delete. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: nothing -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clusterId" $cluster_id "scalar") (serialize-qp "nodePoolId" $node_pool_id "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "zone" $zone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clusterId": $cluster_id, "nodePoolId": $node_pool_id, "projectId": $project_id, "zone": $zone} | compact), body: null}
}

# Gets the specified operation.
#
# GET /v1beta1/{name}
# operationId: container.projects.locations.operations.get
export def "v1beta1 get" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --operation-id: string # Required. Deprecated. The server-assigned `name` of the operation. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: nothing -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "operationId" $operation_id "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "zone" $zone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "operationId": $operation_id, "projectId": $project_id, "zone": $zone} | compact), body: null}
}

# Updates the version and/or image type of a specific node pool.
#
# PUT /v1beta1/{name}
# operationId: container.projects.locations.clusters.nodePools.update
# --confidentialNodes shape: {enabled?: bool}
# --fastSocket shape: {enabled?: bool}
# --gcfsConfig shape: {enabled?: bool}
# --gvnic shape: {enabled?: bool}
# --kubeletConfig shape: {cpuCfsQuota?: bool, cpuCfsQuotaPeriod?: string, cpuManagerPolicy?: string, podPidsLimit?: string}
# --labels shape: {labels?: record}
# --linuxNodeConfig shape: {cgroupMode?: "CGROUP_MODE_UNSPECIFIED"|"CGROUP_MODE_V1"|"CGROUP_MODE_V2", sysctls?: record}
# --loggingConfig shape: {variantConfig?: record}
# --nodeNetworkConfig shape: {createPodRange?: bool, enablePrivateNodes?: bool, networkPerformanceConfig?: record, podCidrOverprovisionConfig?: record, podIpv4CidrBlock?: string, podRange?: string}
# --resourceLabels shape: {labels?: record}
# --tags shape: {tags?: list<string>}
# --taints shape: {taints?: list}
# --upgradeSettings shape: {blueGreenSettings?: record, maxSurge?: int, maxUnavailable?: int, strategy?: "NODE_POOL_UPDATE_STRATEGY_UNSPECIFIED"|"BLUE_GREEN"|"SURGE"}
# --windowsNodeConfig shape: {osVersion?: "OS_VERSION_UNSPECIFIED"|"OS_VERSION_LTSC2019"|"OS_VERSION_LTSC2022"}
# --workloadMetadataConfig shape: {mode?: "MODE_UNSPECIFIED"|"GCE_METADATA"|"GKE_METADATA", nodeMetadata?: "UNSPECIFIED"|"SECURE"|"EXPOSE"|"GKE_METADATA_SERVER"}
export def "v1beta1 update" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --confidential-nodes: record # ConfidentialNodes is configuration for the confidential nodes feature, which makes nodes run on confidential VMs. — shape: {enabled?: bool}
  --etag: string # The current etag of the node pool. If an etag is provided and does not match the current etag of the node pool, update will be blocked and an ABORTED error will be returned.
  --fast-socket: record # Configuration of Fast Socket feature. — shape: {enabled?: bool}
  --gcfs-config: record # GcfsConfig contains configurations of Google Container File System. — shape: {enabled?: bool}
  --gvnic: record # Configuration of gVNIC feature. — shape: {enabled?: bool}
  --image-type: string # Required. The desired image type for the node pool. Please see https://cloud.google.com/kubernetes-engine/docs/concepts/node-images for available image types.
  --kubelet-config: record # Node kubelet configs. — shape: {cpuCfsQuota?: bool, cpuCfsQuotaPeriod?: string, cpuManagerPolicy?: string, podPidsLimit?: string}
  --labels: record # Collection of node-level [Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels). — shape: {labels?: record}
  --linux-node-config: record # Parameters that can be configured on Linux nodes. — shape: {cgroupMode?: "CGROUP_MODE_UNSPECIFIED"|"CGROUP_MODE_V1"|"CGROUP_MODE_V2", sysctls?: record}
  --locations: list<string> # The desired list of Google Compute Engine [zones](https://cloud.google.com/compute/docs/zones#available) in which the node pool's nodes should be located. Changing the locations for a node pool will result in nodes being either created or removed from the node pool, depending on whether locations are being added or removed.
  --logging-config: record # NodePoolLoggingConfig specifies logging configuration for nodepools. — shape: {variantConfig?: record}
  --body-name: string # The name (project, location, cluster, node pool) of the node pool to update. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --node-network-config: record # Parameters for node pool-level network config. — shape: {createPodRange?: bool, enablePrivateNodes?: bool, networkPerformanceConfig?: record, podCidrOverprovisionConfig?: record, podIpv4CidrBlock?: string, podRange?: string}
  --node-pool-id: string # Required. Deprecated. The name of the node pool to upgrade. This field has been deprecated and replaced by the name field.
  --node-version: string # Required. The Kubernetes version to change the nodes to (typically an upgrade). Users may specify either explicit versions offered by Kubernetes Engine or version aliases, which have the following behavior: - "latest": picks the highest valid Kubernetes version - "1.X": picks the highest valid patch+gke.N patch in the 1.X version - "1.X.Y": picks the highest valid gke.N patch in the 1.X.Y version - "1.X.Y-gke.N": picks an explicit Kubernetes version - "-": picks the Kubernetes master version
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --resource-labels: record # Collection of [GCP labels](https://cloud.google.com/resource-manager/docs/creating-managing-labels). — shape: {labels?: record}
  --tags: record # Collection of Compute Engine network tags that can be applied to a node's underlying VM instance. (See `tags` field in [`NodeConfig`](/kubernetes-engine/docs/reference/rest/v1/NodeConfig)). — shape: {tags?: list<string>}
  --taints: record # Collection of Kubernetes [node taints](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration). — shape: {taints?: list}
  --upgrade-settings: record # These upgrade settings configure the upgrade strategy for the node pool. Use strategy to switch between the strategies applied to the node pool. If the strategy is SURGE, use max_surge and max_unavailable to control the level of parallelism and the level of disruption caused by upgrade. 1. maxSurge controls the number of additional nodes that can be added to the node pool temporarily for the time of the upgrade to increase the number of available nodes. 2. maxUnavailable controls the number of nodes that can be simultaneously unavailable. 3. (maxUnavailable + maxSurge) determines the level of parallelism (how many nodes are being upgraded at the same time). If the strategy is BLUE_GREEN, use blue_green_settings to configure the blue-green upgrade related settings. 1. standard_rollout_policy is the default policy. The policy is used to control the way blue pool gets drained. The draining is executed in the batch mode. The batch size could be specified as either percentage of the node pool size or the number of nodes. batch_soak_duration is the soak time after each batch gets drained. 2. node_pool_soak_duration is the soak time after all blue nodes are drained. After this period, the blue pool nodes will be deleted. — shape: {blueGreenSettings?: record, maxSurge?: int, maxUnavailable?: int, strategy?: "NODE_POOL_UPDATE_STRATEGY_UNSPECIFIED"|"BLUE_GREEN"|"SURGE"}
  --windows-node-config: record # Parameters that can be configured on Windows nodes. Windows Node Config that define the parameters that will be used to configure the Windows node pool settings — shape: {osVersion?: "OS_VERSION_UNSPECIFIED"|"OS_VERSION_LTSC2019"|"OS_VERSION_LTSC2022"}
  --workload-metadata-config: record # WorkloadMetadataConfig defines the metadata configuration to expose to workloads on the node pool. — shape: {mode?: "MODE_UNSPECIFIED"|"GCE_METADATA"|"GKE_METADATA", nodeMetadata?: "UNSPECIFIED"|"SECURE"|"EXPOSE"|"GKE_METADATA_SERVER"}
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}") $qp)
  let req_body = {"clusterId": $cluster_id, "confidentialNodes": $confidential_nodes, "etag": $etag, "fastSocket": $fast_socket, "gcfsConfig": $gcfs_config, "gvnic": $gvnic, "imageType": $image_type, "kubeletConfig": $kubelet_config, "labels": $labels, "linuxNodeConfig": $linux_node_config, "locations": $locations, "loggingConfig": $logging_config, "name": $body_name, "nodeNetworkConfig": $node_network_config, "nodePoolId": $node_pool_id, "nodeVersion": $node_version, "projectId": $project_id, "resourceLabels": $resource_labels, "tags": $tags, "taints": $taints, "upgradeSettings": $upgrade_settings, "windowsNodeConfig": $windows_node_config, "workloadMetadataConfig": $workload_metadata_config, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Returns configuration info about the Google Kubernetes Engine service.
#
# GET /v1beta1/{name}/serverConfig
# operationId: container.projects.locations.getServerConfig
export def "v1beta1-server-config get" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) to return operations for. This field has been deprecated and replaced by the name field.
]: nothing -> record<channels: table<availableVersions: list, channel: string, defaultVersion: string, validVersions: list>, defaultClusterVersion: string, defaultImageType: string, validImageTypes: list<string>, validMasterVersions: list<string>, validNodeVersions: list<string>, windowsVersionMaps: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "zone" $zone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}/serverConfig") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id, "zone": $zone} | compact), body: null}
}

# Cancels the specified operation.
#
# POST /v1beta1/{name}:cancel
# operationId: container.projects.locations.operations.cancel
export def "v1beta1 cancel" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-name: string # The name (project, location, operation id) of the operation to cancel. Specified in the format `projects/*/locations/*/operations/*`.
  --operation-id: string # Required. Deprecated. The server-assigned `name` of the operation. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the operation resides. This field has been deprecated and replaced by the name field.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:cancel") $qp)
  let req_body = {"name": $body_name, "operationId": $operation_id, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Completes master IP rotation.
#
# POST /v1beta1/{name}:completeIpRotation
# operationId: container.projects.locations.clusters.completeIpRotation
export def "v1beta1 complete-ip-rotation" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster name) of the cluster to complete IP rotation. Specified in the format `projects/*/locations/*/clusters/*`.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:completeIpRotation") $qp)
  let req_body = {"clusterId": $cluster_id, "name": $body_name, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# CompleteNodePoolUpgrade will signal an on-going node pool upgrade to complete.
#
# POST /v1beta1/{name}:completeUpgrade
# operationId: container.projects.locations.clusters.nodePools.completeUpgrade
export def "v1beta1 complete-upgrade" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:completeUpgrade") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Rolls back a previously Aborted or Failed NodePool upgrade. This makes no changes if the last upgrade successfully completed.
#
# POST /v1beta1/{name}:rollback
# operationId: container.projects.locations.clusters.nodePools.rollback
export def "v1beta1 create-rollback" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to rollback. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster, node pool id) of the node poll to rollback upgrade. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --node-pool-id: string # Required. Deprecated. The name of the node pool to rollback. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --respect-pdb: oneof<nothing, bool> # Option for rollback to ignore the PodDisruptionBudget. Default value is false.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:rollback") $qp)
  let req_body = {"clusterId": $cluster_id, "name": $body_name, "nodePoolId": $node_pool_id, "projectId": $project_id, "respectPdb": $respect_pdb, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the addons for a specific cluster.
#
# POST /v1beta1/{name}:setAddons
# operationId: container.projects.locations.clusters.setAddons
# --addonsConfig shape: {cloudRunConfig?: record, configConnectorConfig?: record, dnsCacheConfig?: record, gcePersistentDiskCsiDriverConfig?: record, gcpFilestoreCsiDriverConfig?: record, gkeBackupAgentConfig?: record, horizontalPodAutoscaling?: record, httpLoadBalancing?: record, istioConfig?: record, kalmConfig?: record, kubernetesDashboard?: record, networkPolicyConfig?: record}
export def "v1beta1 update-addons" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --addons-config: record # Configuration for the addons that can be automatically spun up in the cluster, enabling additional functionality. — shape: {cloudRunConfig?: record, configConnectorConfig?: record, dnsCacheConfig?: record, gcePersistentDiskCsiDriverConfig?: record, gcpFilestoreCsiDriverConfig?: record, gkeBackupAgentConfig?: record, horizontalPodAutoscaling?: record, httpLoadBalancing?: record, istioConfig?: record, kalmConfig?: record, kubernetesDashboard?: record, networkPolicyConfig?: record}
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster) of the cluster to set addons. Specified in the format `projects/*/locations/*/clusters/*`.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:setAddons") $qp)
  let req_body = {"addonsConfig": $addons_config, "clusterId": $cluster_id, "name": $body_name, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the autoscaling settings of a specific node pool.
#
# POST /v1beta1/{name}:setAutoscaling
# operationId: container.projects.locations.clusters.nodePools.setAutoscaling
# --autoscaling shape: {autoprovisioned?: bool, enabled?: bool, locationPolicy?: "LOCATION_POLICY_UNSPECIFIED"|"BALANCED"|"ANY", maxNodeCount?: int, minNodeCount?: int, totalMaxNodeCount?: int, totalMinNodeCount?: int}
export def "v1beta1 update-autoscaling" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --autoscaling: record # NodePoolAutoscaling contains information required by cluster autoscaler to adjust the size of the node pool to the current cluster usage. — shape: {autoprovisioned?: bool, enabled?: bool, locationPolicy?: "LOCATION_POLICY_UNSPECIFIED"|"BALANCED"|"ANY", maxNodeCount?: int, minNodeCount?: int, totalMaxNodeCount?: int, totalMinNodeCount?: int}
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster, node pool) of the node pool to set autoscaler settings. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --node-pool-id: string # Required. Deprecated. The name of the node pool to upgrade. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:setAutoscaling") $qp)
  let req_body = {"autoscaling": $autoscaling, "clusterId": $cluster_id, "name": $body_name, "nodePoolId": $node_pool_id, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Enables or disables the ABAC authorization mechanism on a cluster.
#
# POST /v1beta1/{name}:setLegacyAbac
# operationId: container.projects.locations.clusters.setLegacyAbac
export def "v1beta1 update-legacy-abac" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to update. This field has been deprecated and replaced by the name field.
  --enabled: oneof<nothing, bool> # Required. Whether ABAC authorization will be enabled in the cluster.
  --body-name: string # The name (project, location, cluster name) of the cluster to set legacy abac. Specified in the format `projects/*/locations/*/clusters/*`.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:setLegacyAbac") $qp)
  let req_body = {"clusterId": $cluster_id, "enabled": $enabled, "name": $body_name, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the locations for a specific cluster. Deprecated. Use [projects.locations.clusters.update](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1beta1/projects.locations.clusters/update) instead.
#
# POST /v1beta1/{name}:setLocations
# operationId: container.projects.locations.clusters.setLocations
export def "v1beta1 update-locations" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --locations: list<string> # Required. The desired list of Google Compute Engine [zones](https://cloud.google.com/compute/docs/zones#available) in which the cluster's nodes should be located. Changing the locations a cluster is in will result in nodes being either created or removed from the cluster, depending on whether locations are being added or removed. This list must always include the cluster's primary zone.
  --body-name: string # The name (project, location, cluster) of the cluster to set locations. Specified in the format `projects/*/locations/*/clusters/*`.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:setLocations") $qp)
  let req_body = {"clusterId": $cluster_id, "locations": $locations, "name": $body_name, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the logging service for a specific cluster.
#
# POST /v1beta1/{name}:setLogging
# operationId: container.projects.locations.clusters.setLogging
export def "v1beta1 update-logging" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --logging-service: string # Required. The logging service the cluster should use to write logs. Currently available options: * `logging.googleapis.com/kubernetes` - The Cloud Logging service with a Kubernetes-native resource model * `logging.googleapis.com` - The legacy Cloud Logging service (no longer available as of GKE 1.15). * `none` - no logs will be exported from the cluster. If left as an empty string,`logging.googleapis.com/kubernetes` will be used for GKE 1.14+ or `logging.googleapis.com` for earlier versions.
  --body-name: string # The name (project, location, cluster) of the cluster to set logging. Specified in the format `projects/*/locations/*/clusters/*`.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:setLogging") $qp)
  let req_body = {"clusterId": $cluster_id, "loggingService": $logging_service, "name": $body_name, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the maintenance policy for a cluster.
#
# POST /v1beta1/{name}:setMaintenancePolicy
# operationId: container.projects.locations.clusters.setMaintenancePolicy
# --maintenancePolicy shape: {resourceVersion?: string, window?: record}
export def "v1beta1 update-maintenance-policy" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. The name of the cluster to update.
  --maintenance-policy: record # MaintenancePolicy defines the maintenance policy to be used for the cluster. — shape: {resourceVersion?: string, window?: record}
  --body-name: string # The name (project, location, cluster name) of the cluster to set maintenance policy. Specified in the format `projects/*/locations/*/clusters/*`.
  --project-id: string # Required. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
  --zone: string # Required. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:setMaintenancePolicy") $qp)
  let req_body = {"clusterId": $cluster_id, "maintenancePolicy": $maintenance_policy, "name": $body_name, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the NodeManagement options for a node pool.
#
# POST /v1beta1/{name}:setManagement
# operationId: container.projects.locations.clusters.nodePools.setManagement
# --management shape: {autoRepair?: bool, autoUpgrade?: bool, upgradeOptions?: record}
export def "v1beta1 update-management" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to update. This field has been deprecated and replaced by the name field.
  --management: record # NodeManagement defines the set of node management services turned on for the node pool. — shape: {autoRepair?: bool, autoUpgrade?: bool, upgradeOptions?: record}
  --body-name: string # The name (project, location, cluster, node pool id) of the node pool to set management properties. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --node-pool-id: string # Required. Deprecated. The name of the node pool to update. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:setManagement") $qp)
  let req_body = {"clusterId": $cluster_id, "management": $management, "name": $body_name, "nodePoolId": $node_pool_id, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets master auth materials. Currently supports changing the admin password or a specific cluster, either via password generation or explicitly setting the password.
#
# POST /v1beta1/{name}:setMasterAuth
# operationId: container.projects.locations.clusters.setMasterAuth
# --update shape: {clientCertificate?: string, clientCertificateConfig?: record, clientKey?: string, clusterCaCertificate?: string, password?: string, username?: string}
export def "v1beta1 update-master-auth" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --action: string@action-completer # Required. The exact form of action to be taken on the master auth.
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster) of the cluster to set auth. Specified in the format `projects/*/locations/*/clusters/*`.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --update: record # The authentication information for accessing the master endpoint. Authentication can be done using HTTP basic auth or using client certificates. — shape: {clientCertificate?: string, clientCertificateConfig?: record, clientKey?: string, clusterCaCertificate?: string, password?: string, username?: string}
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:setMasterAuth") $qp)
  let req_body = {"action": $action, "clusterId": $cluster_id, "name": $body_name, "projectId": $project_id, "update": $update, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets the monitoring service for a specific cluster.
#
# POST /v1beta1/{name}:setMonitoring
# operationId: container.projects.locations.clusters.setMonitoring
export def "v1beta1 update-monitoring" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --monitoring-service: string # Required. The monitoring service the cluster should use to write metrics. Currently available options: * "monitoring.googleapis.com/kubernetes" - The Cloud Monitoring service with a Kubernetes-native resource model * `monitoring.googleapis.com` - The legacy Cloud Monitoring service (no longer available as of GKE 1.15). * `none` - No metrics will be exported from the cluster. If left as an empty string,`monitoring.googleapis.com/kubernetes` will be used for GKE 1.14+ or `monitoring.googleapis.com` for earlier versions.
  --body-name: string # The name (project, location, cluster) of the cluster to set monitoring. Specified in the format `projects/*/locations/*/clusters/*`.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:setMonitoring") $qp)
  let req_body = {"clusterId": $cluster_id, "monitoringService": $monitoring_service, "name": $body_name, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Enables or disables Network Policy for a cluster.
#
# POST /v1beta1/{name}:setNetworkPolicy
# operationId: container.projects.locations.clusters.setNetworkPolicy
# --networkPolicy shape: {enabled?: bool, provider?: "PROVIDER_UNSPECIFIED"|"CALICO"}
export def "v1beta1 update-network-policy" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster name) of the cluster to set networking policy. Specified in the format `projects/*/locations/*/clusters/*`.
  --network-policy: record # Configuration options for the NetworkPolicy feature. https://kubernetes.io/docs/concepts/services-networking/networkpolicies/ — shape: {enabled?: bool, provider?: "PROVIDER_UNSPECIFIED"|"CALICO"}
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:setNetworkPolicy") $qp)
  let req_body = {"clusterId": $cluster_id, "name": $body_name, "networkPolicy": $network_policy, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Sets labels on a cluster.
#
# POST /v1beta1/{name}:setResourceLabels
# operationId: container.projects.locations.clusters.setResourceLabels
export def "v1beta1 update-resource-labels" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --label-fingerprint: string # Required. The fingerprint of the previous set of labels for this resource, used to detect conflicts. The fingerprint is initially generated by Kubernetes Engine and changes after every request to modify or update labels. You must always provide an up-to-date fingerprint hash when updating or changing labels. Make a `get()` request to the resource to get the latest fingerprint.
  --body-name: string # The name (project, location, cluster name) of the cluster to set labels. Specified in the format `projects/*/locations/*/clusters/*`.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --resource-labels: record # Required. The labels to set for that cluster.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:setResourceLabels") $qp)
  let req_body = {"clusterId": $cluster_id, "labelFingerprint": $label_fingerprint, "name": $body_name, "projectId": $project_id, "resourceLabels": $resource_labels, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# SetNodePoolSizeRequest sets the size of a node pool. The new size will be used for all replicas, including future replicas created by modifying NodePool.locations.
#
# POST /v1beta1/{name}:setSize
# operationId: container.projects.locations.clusters.nodePools.setSize
export def "v1beta1 update-size" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to update. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster, node pool id) of the node pool to set size. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --node-count: int # Required. The desired node count for the pool. (format: int32)
  --node-pool-id: string # Required. Deprecated. The name of the node pool to update. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:setSize") $qp)
  let req_body = {"clusterId": $cluster_id, "name": $body_name, "nodeCount": $node_count, "nodePoolId": $node_pool_id, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Starts master IP rotation.
#
# POST /v1beta1/{name}:startIpRotation
# operationId: container.projects.locations.clusters.startIpRotation
export def "v1beta1 start-ip-rotation" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster name) of the cluster to start IP rotation. Specified in the format `projects/*/locations/*/clusters/*`.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --rotate-credentials: oneof<nothing, bool> # Whether to rotate credentials during IP rotation.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:startIpRotation") $qp)
  let req_body = {"clusterId": $cluster_id, "name": $body_name, "projectId": $project_id, "rotateCredentials": $rotate_credentials, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates the master for a specific cluster.
#
# POST /v1beta1/{name}:updateMaster
# operationId: container.projects.locations.clusters.updateMaster
export def "v1beta1 update-master" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --master-version: string # Required. The Kubernetes version to change the master to. Users may specify either explicit versions offered by Kubernetes Engine or version aliases, which have the following behavior: - "latest": picks the highest valid Kubernetes version - "1.X": picks the highest valid patch+gke.N patch in the 1.X version - "1.X.Y": picks the highest valid gke.N patch in the 1.X.Y version - "1.X.Y-gke.N": picks an explicit Kubernetes version - "-": picks the default Kubernetes version
  --body-name: string # The name (project, location, cluster) of the cluster to update. Specified in the format `projects/*/locations/*/clusters/*`.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:updateMaster") $qp)
  let req_body = {"clusterId": $cluster_id, "masterVersion": $master_version, "name": $body_name, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Gets the OIDC discovery document for the cluster. See the [OpenID Connect Discovery 1.0 specification](https://openid.net/specs/openid-connect-discovery-1_0.html) for details. This API is not yet intended for general use, and is not available for all clusters.
#
# GET /v1beta1/{parent}/.well-known/openid-configuration
# operationId: container.projects.locations.clusters.well-known.getOpenid-configuration
export def "v1beta1-well-known-openid-configuration get" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<cacheHeader: record<age: string, directive: string, expires: string>, claims_supported: list<string>, grant_types: list<string>, id_token_signing_alg_values_supported: list<string>, issuer: string, jwks_uri: string, response_types_supported: list<string>, subject_types_supported: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/.well-known/openid-configuration") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Lists subnetworks that can be used for creating clusters in a project.
#
# GET /v1beta1/{parent}/aggregated/usableSubnetworks
# operationId: container.projects.aggregated.usableSubnetworks.list
export def "v1beta1-aggregated-usable-subnetworks list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Filtering currently only supports equality on the networkProjectId and must be in the form: "networkProjectId=[PROJECTID]", where `networkProjectId` is the project which owns the listed subnetworks. This defaults to the parent project ID.
  --page-size: int # The max number of results per page that should be returned. If the number of available results is larger than `page_size`, a `next_page_token` is returned which can be used to get the next page of results in subsequent requests. Acceptable values are 0 to 500, inclusive. (Default: 500)
  --page-token: string # Specifies a page token to use. Set this to the nextPageToken returned by previous list requests to get the next page of results.
]: nothing -> record<nextPageToken: string, subnetworks: table<ipCidrRange: string, network: string, secondaryIpRanges: list, statusMessage: string, subnetwork: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/aggregated/usableSubnetworks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Lists all clusters owned by a project in either the specified zone or all zones.
#
# GET /v1beta1/{parent}/clusters
# operationId: container.projects.locations.clusters.list
export def "v1beta1-clusters list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides, or "-" for all zones. This field has been deprecated and replaced by the parent field.
]: nothing -> record<clusters: table<addonsConfig: record, authenticatorGroupsConfig: record, autopilot: record, autoscaling: record, binaryAuthorization: record, clusterIpv4Cidr: string, clusterTelemetry: record, conditions: list, confidentialNodes: record, costManagementConfig: record, createTime: string, currentMasterVersion: string, currentNodeCount: int, currentNodeVersion: string, databaseEncryption: record, defaultMaxPodsConstraint: record, description: string, enableKubernetesAlpha: bool, enableTpu: bool, endpoint: string, etag: string, expireTime: string, fleet: record, id: string, identityServiceConfig: record, initialClusterVersion: string, initialNodeCount: int, instanceGroupUrls: list, ipAllocationPolicy: record, labelFingerprint: string, legacyAbac: record, location: string, locations: list, loggingConfig: record, loggingService: string, maintenancePolicy: record, master: record, masterAuth: record, masterAuthorizedNetworksConfig: record, masterIpv4CidrBlock: string, meshCertificates: record, monitoringConfig: record, monitoringService: string, name: string, network: string, networkConfig: record, networkPolicy: record, nodeConfig: record, nodeIpv4CidrSize: int, nodePoolAutoConfig: record, nodePoolDefaults: record, nodePools: list, notificationConfig: record, podSecurityPolicyConfig: record, privateCluster: bool, privateClusterConfig: record, protectConfig: record, releaseChannel: record, resourceLabels: record, resourceUsageExportConfig: record, selfLink: string, servicesIpv4Cidr: string, shieldedNodes: record, status: string, statusMessage: string, subnetwork: string, tpuConfig: record, tpuIpv4CidrBlock: string, verticalPodAutoscaling: record, workloadAltsConfig: record, workloadCertificates: record, workloadIdentityConfig: record, zone: string>, missingZones: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "zone" $zone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/clusters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id, "zone": $zone} | compact), body: null}
}

# Creates a cluster, consisting of the specified number and type of Google Compute Engine instances. By default, the cluster is created in the project's [default network](https://cloud.google.com/compute/docs/networks-and-firewalls#networks). One firewall is added for the cluster. After cluster creation, the Kubelet creates routes for each node to allow the containers on that node to communicate with all other instances in the cluster. Finally, an entry is added to the project's global metadata indicating which CIDR range the cluster is using.
#
# POST /v1beta1/{parent}/clusters
# operationId: container.projects.locations.clusters.create
# --cluster shape: {addonsConfig?: record, authenticatorGroupsConfig?: record, autopilot?: record, autoscaling?: record, binaryAuthorization?: record, clusterIpv4Cidr?: string, clusterTelemetry?: record, conditions?: list, confidentialNodes?: record, costManagementConfig?: record, createTime?: string, currentMasterVersion?: string, currentNodeCount?: int, currentNodeVersion?: string, databaseEncryption?: record, defaultMaxPodsConstraint?: record, description?: string, enableKubernetesAlpha?: bool, enableTpu?: bool, ... (53 more fields)}
export def "v1beta1-clusters create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster: record # A Google Kubernetes Engine cluster. — shape: {addonsConfig?: record, authenticatorGroupsConfig?: record, autopilot?: record, autoscaling?: record, binaryAuthorization?: record, clusterIpv4Cidr?: string, clusterTelemetry?: record, conditions?: list, confidentialNodes?: record, costManagementConfig?: record, createTime?: string, currentMasterVersion?: string, currentNodeCount?: int, currentNodeVersion?: string, databaseEncryption?: record, defaultMaxPodsConstraint?: record, description?: string, enableKubernetesAlpha?: bool, enableTpu?: bool, ... (53 more fields)}
  --body-parent: string # The parent (project and location) where the cluster will be created. Specified in the format `projects/*/locations/*`.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the parent field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/clusters") $qp)
  let req_body = {"cluster": $cluster, "parent": $body_parent, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Gets the public component of the cluster signing keys in JSON Web Key format. This API is not yet intended for general use, and is not available for all clusters.
#
# GET /v1beta1/{parent}/jwks
# operationId: container.projects.locations.clusters.getJwks
export def "v1beta1-jwks get" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<cacheHeader: record<age: string, directive: string, expires: string>, keys: table<alg: string, crv: string, e: string, kid: string, kty: string, n: string, use: string, x: string, y: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/jwks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Fetches locations that offer Google Kubernetes Engine.
#
# GET /v1beta1/{parent}/locations
# operationId: container.projects.locations.list
export def "v1beta1-locations list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<locations: table<name: string, recommended: bool, type: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/locations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Lists the node pools for a cluster.
#
# GET /v1beta1/{parent}/nodePools
# operationId: container.projects.locations.clusters.nodePools.list
export def "v1beta1-node-pools list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the parent field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the parent field.
]: nothing -> record<nodePools: table<autoscaling: record, conditions: list, config: record, etag: string, initialNodeCount: int, instanceGroupUrls: list, locations: list, management: record, maxPodsConstraint: record, name: string, networkConfig: record, placementPolicy: record, podIpv4CidrSize: int, selfLink: string, status: string, statusMessage: string, updateInfo: record, upgradeSettings: record, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "clusterId" $cluster_id "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "zone" $zone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/nodePools") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "clusterId": $cluster_id, "projectId": $project_id, "zone": $zone} | compact), body: null}
}

# Creates a node pool for a cluster.
#
# POST /v1beta1/{parent}/nodePools
# operationId: container.projects.locations.clusters.nodePools.create
# --nodePool shape: {autoscaling?: record, conditions?: list, config?: record, etag?: string, initialNodeCount?: int, instanceGroupUrls?: list<string>, locations?: list<string>, management?: record, maxPodsConstraint?: record, name?: string, networkConfig?: record, placementPolicy?: record, podIpv4CidrSize?: int, selfLink?: string, status?: "STATUS_UNSPECIFIED"|"PROVISIONING"|"RUNNING"|"RUNNING_WITH_ERROR"|"RECONCILING"|"STOPPING"|"ERROR", statusMessage?: string, updateInfo?: record, upgradeSettings?: record, ... (1 more fields)}
export def "v1beta1-node-pools create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the parent field.
  --node-pool: record # NodePool contains the name and configuration for a cluster's node pool. Node pools are a set of nodes (i.e. VM's), with a common configuration and specification, under the control of the cluster master. They may have a set of Kubernetes labels applied to them, which may be used to reference them during pod scheduling. They may also be resized up or down, to accommodate the workload. These upgrade settings control the level of parallelism and the level of disruption caused by an upgrade. maxUnavailable controls the number of nodes that can be simultaneously unavailable. maxSurge controls the number of additional nodes that can be added to the node pool temporarily for the time of the upgrade to increase the number of available nodes. (maxUnavailable + maxSurge) determines the level of parallelism (how many nodes are being upgraded at the same time). Note: upgrades inevitably introduce some disruption since workloads need to be moved from old nodes to new, upgraded ones. Even if maxUnavailable=0, this holds true. (Disruption stays within the limits of PodDisruptionBudget, if it is configured.) Consider a hypothetical node pool with 5 nodes having maxSurge=2, maxUnavailable=1. This means the upgrade process upgrades 3 nodes simultaneously. It creates 2 additional (upgraded) nodes, then it brings down 3 old (not yet upgraded) nodes at the same time. This ensures that there are always at least 4 nodes available. — shape: {autoscaling?: record, conditions?: list, config?: record, etag?: string, initialNodeCount?: int, instanceGroupUrls?: list<string>, locations?: list<string>, management?: record, maxPodsConstraint?: record, name?: string, networkConfig?: record, placementPolicy?: record, podIpv4CidrSize?: int, selfLink?: string, status?: "STATUS_UNSPECIFIED"|"PROVISIONING"|"RUNNING"|"RUNNING_WITH_ERROR"|"RECONCILING"|"STOPPING"|"ERROR", statusMessage?: string, updateInfo?: record, upgradeSettings?: record, ... (1 more fields)}
  --body-parent: string # The parent (project, location, cluster name) where the node pool will be created. Specified in the format `projects/*/locations/*/clusters/*`.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the parent field.
]: any -> record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/nodePools") $qp)
  let req_body = {"clusterId": $cluster_id, "nodePool": $node_pool, "parent": $body_parent, "projectId": $project_id, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists all operations in a project in the specified zone or all zones.
#
# GET /v1beta1/{parent}/operations
# operationId: container.projects.locations.operations.list
export def "v1beta1-operations list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) to return operations for, or `-` for all zones. This field has been deprecated and replaced by the parent field.
]: nothing -> record<missingZones: list<string>, operations: table<clusterConditions: list, detail: string, endTime: string, error: record, location: string, name: string, nodepoolConditions: list, operationType: string, progress: record, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "zone" $zone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/operations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id, "zone": $zone} | compact), body: null}
}
