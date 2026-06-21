# Auto-generated client for Cloud SQL Admin API vv1beta4
# Source: https://api.apis.guru/v2/specs/googleapis.com/sql/v1beta4/openapi.json
# Auth: --token flag or $env.CLOUD_SQL_ADMIN_API_TOKEN

const BASE_URL = "https://sqladmin.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUD_SQL_ADMIN_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://sqladmin.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def backend-type-completer [] { ["EXTERNAL" "FIRST_GEN" "SECOND_GEN" "SQL_BACKEND_TYPE_UNSPECIFIED"] }
def database-version-completer [] { ["MYSQL_5_1" "MYSQL_5_5" "MYSQL_5_6" "MYSQL_5_7" "MYSQL_8_0" "MYSQL_8_0_18" "MYSQL_8_0_26" "MYSQL_8_0_27" "MYSQL_8_0_28" "MYSQL_8_0_29" "MYSQL_8_0_30" "MYSQL_8_0_31" "MYSQL_8_0_32" "MYSQL_8_0_33" "MYSQL_8_0_34" "MYSQL_8_0_35" "MYSQL_8_0_36" "POSTGRES_10" "POSTGRES_11" "POSTGRES_12" "POSTGRES_13" "POSTGRES_14" "POSTGRES_9_6" "SQLSERVER_2017_ENTERPRISE" "SQLSERVER_2017_EXPRESS" "SQLSERVER_2017_STANDARD" "SQLSERVER_2017_WEB" "SQLSERVER_2019_ENTERPRISE" "SQLSERVER_2019_EXPRESS" "SQLSERVER_2019_STANDARD" "SQLSERVER_2019_WEB" "SQL_DATABASE_VERSION_UNSPECIFIED"] }
def instance-type-completer [] { ["CLOUD_SQL_INSTANCE" "ON_PREMISES_INSTANCE" "READ_REPLICA_INSTANCE" "SQL_INSTANCE_TYPE_UNSPECIFIED"] }
def state-completer [] { ["FAILED" "MAINTENANCE" "ONLINE_MAINTENANCE" "PENDING_CREATE" "PENDING_DELETE" "RUNNABLE" "SQL_INSTANCE_STATE_UNSPECIFIED" "SUSPENDED"] }
def backup-kind-completer [] { ["PHYSICAL" "SNAPSHOT" "SQL_BACKUP_KIND_UNSPECIFIED"] }
def status-completer [] { ["DELETED" "DELETION_FAILED" "DELETION_PENDING" "ENQUEUED" "FAILED" "OVERDUE" "RUNNING" "SKIPPED" "SQL_BACKUP_RUN_STATUS_UNSPECIFIED" "SUCCESSFUL"] }
def type-completer [] { ["AUTOMATED" "ON_DEMAND" "SQL_BACKUP_RUN_TYPE_UNSPECIFIED"] }
def sync-mode-completer [] { ["EXTERNAL_SYNC_MODE_UNSPECIFIED" "OFFLINE" "ONLINE"] }
def dual-password-type-completer [] { ["DUAL_PASSWORD" "DUAL_PASSWORD_TYPE_UNSPECIFIED" "NO_DUAL_PASSWORD" "NO_MODIFY_DUAL_PASSWORD"] }
def type-completer-1 [] { ["BUILT_IN" "CLOUD_IAM_SERVICE_ACCOUNT" "CLOUD_IAM_USER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "sql-v1beta4-flags list" } } | get name | first)
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

# Lists all available database flags for Cloud SQL instances.
#
# GET /sql/v1beta4/flags
# operationId: sql.flags.list
export def "sql-v1beta4-flags list" [
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
  --database-version: string # Database type and version you want to retrieve flags for. By default, this method returns flags for all database types and versions.
]: nothing -> record<items: table<allowedIntValues: list, allowedStringValues: list, appliesTo: list, inBeta: bool, kind: string, maxValue: string, minValue: string, name: string, requiresRestart: bool, type: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "databaseVersion" $database_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sql/v1beta4/flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "databaseVersion": $database_version} | compact), body: null}
}

# Lists instances under a given project.
#
# GET /sql/v1beta4/projects/{project}/instances
# operationId: sql.instances.list
export def "sql-v1beta4-projects-instances list" [
  project: string
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
  --filter: string # A filter expression that filters resources listed in the response. The expression is in the form of field:value. For example, 'instanceType:CLOUD_SQL_INSTANCE'. Fields can be nested as needed as per their JSON representation, such as 'settings.userLabels.auto_start:true'. Multiple filter queries are space-separated. For example. 'state:RUNNABLE instanceType:CLOUD_SQL_INSTANCE'. By default, each expression is an AND expression. However, you can include AND and OR expressions explicitly.
  --max-results: int # The maximum number of instances to return. The service may return fewer than this value. If unspecified, at most 500 instances are returned. The maximum value is 1000; values above 1000 are coerced to 1000.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
]: nothing -> record<items: table<availableMaintenanceVersions: list, backendType: string, connectionName: string, createTime: string, currentDiskSize: string, databaseInstalledVersion: string, databaseVersion: string, diskEncryptionConfiguration: record, diskEncryptionStatus: record, etag: string, failoverReplica: record, gceZone: string, instanceType: string, ipAddresses: list, ipv6Address: string, kind: string, maintenanceVersion: string, masterInstanceName: string, maxDiskSize: string, name: string, onPremisesConfiguration: record, outOfDiskReport: record, project: string, region: string, replicaConfiguration: record, replicaNames: list, rootPassword: string, satisfiesPzs: bool, scheduledMaintenance: record, secondaryGceZone: string, selfLink: string, serverCaCert: record, serviceAccountEmailAddress: string, settings: record, state: string, suspensionReason: list>, kind: string, nextPageToken: string, warnings: table<code: string, message: string, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project)} | format pattern "/sql/v1beta4/projects/{project}/instances") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Creates a new Cloud SQL instance.
#
# POST /sql/v1beta4/projects/{project}/instances
# operationId: sql.instances.insert
# --diskEncryptionConfiguration shape: {kind?: string, kmsKeyName?: string}
# --diskEncryptionStatus shape: {kind?: string, kmsKeyVersionName?: string}
# --failoverReplica shape: {available?: bool, name?: string}
# --ipAddresses item shape: {ipAddress?: string, timeToRetire?: string, type?: "SQL_IP_ADDRESS_TYPE_UNSPECIFIED"|"PRIMARY"|"OUTGOING"|"PRIVATE"|"MIGRATED_1ST_GEN"}
# --onPremisesConfiguration shape: {caCertificate?: string, clientCertificate?: string, clientKey?: string, dumpFilePath?: string, hostPort?: string, kind?: string, password?: string, sourceInstance?: record, username?: string}
# --outOfDiskReport shape: {sqlMinRecommendedIncreaseSizeGb?: int, sqlOutOfDiskState?: "SQL_OUT_OF_DISK_STATE_UNSPECIFIED"|"NORMAL"|"SOFT_SHUTDOWN"}
# --replicaConfiguration shape: {failoverTarget?: bool, kind?: string, mysqlReplicaConfiguration?: record}
# --scheduledMaintenance shape: {canDefer?: bool, canReschedule?: bool, scheduleDeadlineTime?: string, startTime?: string}
# --serverCaCert shape: {cert?: string, certSerialNumber?: string, commonName?: string, createTime?: string, expirationTime?: string, instance?: string, kind?: string, selfLink?: string, sha1Fingerprint?: string}
# --settings shape: {activationPolicy?: "SQL_ACTIVATION_POLICY_UNSPECIFIED"|"ALWAYS"|"NEVER"|"ON_DEMAND", activeDirectoryConfig?: record, advancedMachineFeatures?: record, authorizedGaeApplications?: list<string>, availabilityType?: "SQL_AVAILABILITY_TYPE_UNSPECIFIED"|"ZONAL"|"REGIONAL", backupConfiguration?: record, collation?: string, connectorEnforcement?: "CONNECTOR_ENFORCEMENT_UNSPECIFIED"|"NOT_REQUIRED"|"REQUIRED", crashSafeReplicationEnabled?: bool, dataDiskSizeGb?: string, ... (20 more fields)}
export def "sql-v1beta4-projects-instances create" [
  project: string
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
  --backend-type: string@backend-type-completer # The backend type. `SECOND_GEN`: Cloud SQL database instance. `EXTERNAL`: A database server that is not managed by Google. This property is read-only; use the `tier` property in the `settings` object to determine the database type.
  --connection-name: string # Connection name of the Cloud SQL instance used in connection strings.
  --current-disk-size: string # The current disk usage of the instance in bytes. This property has been deprecated. Use the "cloudsql.googleapis.com/database/disk/bytes_used" metric in Cloud Monitoring API instead. Please see [this announcement](https://groups.google.com/d/msg/google-cloud-sql-announce/I_7-F9EBhT0/BtvFtdFeAgAJ) for details. (format: int64)
  --database-version: string@database-version-completer # The database engine type and version. The `databaseVersion` field cannot be changed after instance creation.
  --disk-encryption-configuration: record # Disk encryption configuration for an instance. — shape: {kind?: string, kmsKeyName?: string}
  --disk-encryption-status: record # Disk encryption status for an instance. — shape: {kind?: string, kmsKeyVersionName?: string}
  --etag: string # This field is deprecated and will be removed from a future version of the API. Use the `settings.settingsVersion` field instead.
  --failover-replica: record # The name and status of the failover replica. — shape: {available?: bool, name?: string}
  --gce-zone: string # The Compute Engine zone that the instance is currently serving from. This value could be different from the zone that was specified when the instance was created if the instance has failed over to its secondary zone. WARNING: Changing this might restart the instance.
  --instance-type: string@instance-type-completer # The instance type.
  --ip-addresses: list # The assigned IP addresses for the instance. — item shape: {ipAddress?: string, timeToRetire?: string, type?: "SQL_IP_ADDRESS_TYPE_UNSPECIFIED"|"PRIMARY"|"OUTGOING"|"PRIVATE"|"MIGRATED_1ST_GEN"}
  --ipv6-address: string # The IPv6 address assigned to the instance. (Deprecated) This property was applicable only to First Generation instances.
  --kind: string # This is always `sql#instance`.
  --maintenance-version: string # The current software version on the instance.
  --master-instance-name: string # The name of the instance which will act as primary in the replication setup.
  --max-disk-size: string # The maximum disk size of the instance in bytes. (format: int64)
  --name: string # Name of the Cloud SQL instance. This does not include the project ID.
  --on-premises-configuration: record # On-premises instance configuration. — shape: {caCertificate?: string, clientCertificate?: string, clientKey?: string, dumpFilePath?: string, hostPort?: string, kind?: string, password?: string, sourceInstance?: record, username?: string}
  --out-of-disk-report: record # This message wraps up the information written by out-of-disk detection job. — shape: {sqlMinRecommendedIncreaseSizeGb?: int, sqlOutOfDiskState?: "SQL_OUT_OF_DISK_STATE_UNSPECIFIED"|"NORMAL"|"SOFT_SHUTDOWN"}
  --body-project: string # The project ID of the project containing the Cloud SQL instance. The Google apps domain is prefixed if applicable.
  --region: string # The geographical region. Can be: * `us-central` (`FIRST_GEN` instances only) * `us-central1` (`SECOND_GEN` instances only) * `asia-east1` or `europe-west1`. Defaults to `us-central` or `us-central1` depending on the instance type. The region cannot be changed after instance creation.
  --replica-configuration: record # Read-replica configuration for connecting to the primary instance. — shape: {failoverTarget?: bool, kind?: string, mysqlReplicaConfiguration?: record}
  --replica-names: list<string> # The replicas of the instance.
  --root-password: string # Initial root password. Use only on creation. You must set root passwords before you can connect to PostgreSQL instances.
  --satisfies-pzs: oneof<nothing, bool> # The status indicating if instance satisfiesPzs. Reserved for future use.
  --scheduled-maintenance: record # Any scheduled maintenance for this instance. — shape: {canDefer?: bool, canReschedule?: bool, scheduleDeadlineTime?: string, startTime?: string}
  --secondary-gce-zone: string # The Compute Engine zone that the failover instance is currently serving from for a regional instance. This value could be different from the zone that was specified when the instance was created if the instance has failed over to its secondary/failover zone.
  --self-link: string # The URI of this resource.
  --server-ca-cert: record # SslCerts Resource — shape: {cert?: string, certSerialNumber?: string, commonName?: string, createTime?: string, expirationTime?: string, instance?: string, kind?: string, selfLink?: string, sha1Fingerprint?: string}
  --service-account-email-address: string # The service account email address assigned to the instance. \This property is read-only.
  --settings: record # Database instance settings. — shape: {activationPolicy?: "SQL_ACTIVATION_POLICY_UNSPECIFIED"|"ALWAYS"|"NEVER"|"ON_DEMAND", activeDirectoryConfig?: record, advancedMachineFeatures?: record, authorizedGaeApplications?: list<string>, availabilityType?: "SQL_AVAILABILITY_TYPE_UNSPECIFIED"|"ZONAL"|"REGIONAL", backupConfiguration?: record, collation?: string, connectorEnforcement?: "CONNECTOR_ENFORCEMENT_UNSPECIFIED"|"NOT_REQUIRED"|"REQUIRED", crashSafeReplicationEnabled?: bool, dataDiskSizeGb?: string, ... (20 more fields)}
  --state: string@state-completer # The current serving state of the Cloud SQL instance.
  --suspension-reason: list<string> # If the instance state is SUSPENDED, the reason for the suspension.
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project)} | format pattern "/sql/v1beta4/projects/{project}/instances") $qp)
  let req_body = {"backendType": $backend_type, "connectionName": $connection_name, "currentDiskSize": $current_disk_size, "databaseVersion": $database_version, "diskEncryptionConfiguration": $disk_encryption_configuration, "diskEncryptionStatus": $disk_encryption_status, "etag": $etag, "failoverReplica": $failover_replica, "gceZone": $gce_zone, "instanceType": $instance_type, "ipAddresses": $ip_addresses, "ipv6Address": $ipv6_address, "kind": $kind, "maintenanceVersion": $maintenance_version, "masterInstanceName": $master_instance_name, "maxDiskSize": $max_disk_size, "name": $name, "onPremisesConfiguration": $on_premises_configuration, "outOfDiskReport": $out_of_disk_report, "project": $body_project, "region": $region, "replicaConfiguration": $replica_configuration, "replicaNames": $replica_names, "rootPassword": $root_password, "satisfiesPzs": $satisfies_pzs, "scheduledMaintenance": $scheduled_maintenance, "secondaryGceZone": $secondary_gce_zone, "selfLink": $self_link, "serverCaCert": $server_ca_cert, "serviceAccountEmailAddress": $service_account_email_address, "settings": $settings, "state": $state, "suspensionReason": $suspension_reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes a Cloud SQL instance.
#
# DELETE /sql/v1beta4/projects/{project}/instances/{instance}
# operationId: sql.instances.delete
export def "sql-v1beta4-projects-instances delete" [
  project: string
  instance: string
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
]: nothing -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a resource containing information about a Cloud SQL instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}
# operationId: sql.instances.get
export def "sql-v1beta4-projects-instances get" [
  project: string
  instance: string
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
]: nothing -> record<availableMaintenanceVersions: list<string>, backendType: string, connectionName: string, createTime: string, currentDiskSize: string, databaseInstalledVersion: string, databaseVersion: string, diskEncryptionConfiguration: record<kind: string, kmsKeyName: string>, diskEncryptionStatus: record<kind: string, kmsKeyVersionName: string>, etag: string, failoverReplica: record<available: bool, name: string>, gceZone: string, instanceType: string, ipAddresses: table<ipAddress: string, timeToRetire: string, type: string>, ipv6Address: string, kind: string, maintenanceVersion: string, masterInstanceName: string, maxDiskSize: string, name: string, onPremisesConfiguration: record<caCertificate: string, clientCertificate: string, clientKey: string, dumpFilePath: string, hostPort: string, kind: string, password: string, sourceInstance: record<name: string, project: string, region: string>, username: string>, outOfDiskReport: record<sqlMinRecommendedIncreaseSizeGb: int, sqlOutOfDiskState: string>, project: string, region: string, replicaConfiguration: record<failoverTarget: bool, kind: string, mysqlReplicaConfiguration: record<caCertificate: string, clientCertificate: string, clientKey: string, connectRetryInterval: int, dumpFilePath: string, kind: string, masterHeartbeatPeriod: string, password: string, sslCipher: string, username: string, verifyServerCertificate: bool>>, replicaNames: list<string>, rootPassword: string, satisfiesPzs: bool, scheduledMaintenance: record<canDefer: bool, canReschedule: bool, scheduleDeadlineTime: string, startTime: string>, secondaryGceZone: string, selfLink: string, serverCaCert: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>, serviceAccountEmailAddress: string, settings: record<activationPolicy: string, activeDirectoryConfig: record<domain: string, kind: string>, advancedMachineFeatures: record<threadsPerCore: int>, authorizedGaeApplications: list<string>, availabilityType: string, backupConfiguration: record<backupRetentionSettings: record, binaryLogEnabled: bool, enabled: bool, kind: string, location: string, pointInTimeRecoveryEnabled: bool, replicationLogArchivingEnabled: bool, startTime: string, transactionLogRetentionDays: int>, collation: string, connectorEnforcement: string, crashSafeReplicationEnabled: bool, dataDiskSizeGb: string, dataDiskType: string, databaseFlags: list<record>, databaseReplicationEnabled: bool, deletionProtectionEnabled: bool, denyMaintenancePeriods: list<record>, insightsConfig: record<queryInsightsEnabled: bool, queryPlansPerMinute: int, queryStringLength: int, recordApplicationTags: bool, recordClientAddress: bool>, ipConfiguration: record<allocatedIpRange: string, authorizedNetworks: list, enablePrivatePathForGoogleCloudServices: bool, ipv4Enabled: bool, privateNetwork: string, requireSsl: bool>, kind: string, locationPreference: record<followGaeApplication: string, kind: string, secondaryZone: string, zone: string>, maintenanceWindow: record<day: int, hour: int, kind: string, updateTrack: string>, passwordValidationPolicy: record<complexity: string, disallowUsernameSubstring: bool, enablePasswordPolicy: bool, minLength: int, passwordChangeInterval: string, reuseInterval: int>, pricingPlan: string, replicationType: string, settingsVersion: string, sqlServerAuditConfig: record<bucket: string, kind: string, retentionInterval: string, uploadInterval: string>, storageAutoResize: bool, storageAutoResizeLimit: string, tier: string, timeZone: string, userLabels: record>, state: string, suspensionReason: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Partially updates settings of a Cloud SQL instance by merging the request with the current configuration. This method supports patch semantics.
#
# PATCH /sql/v1beta4/projects/{project}/instances/{instance}
# operationId: sql.instances.patch
# --diskEncryptionConfiguration shape: {kind?: string, kmsKeyName?: string}
# --diskEncryptionStatus shape: {kind?: string, kmsKeyVersionName?: string}
# --failoverReplica shape: {available?: bool, name?: string}
# --ipAddresses item shape: {ipAddress?: string, timeToRetire?: string, type?: "SQL_IP_ADDRESS_TYPE_UNSPECIFIED"|"PRIMARY"|"OUTGOING"|"PRIVATE"|"MIGRATED_1ST_GEN"}
# --onPremisesConfiguration shape: {caCertificate?: string, clientCertificate?: string, clientKey?: string, dumpFilePath?: string, hostPort?: string, kind?: string, password?: string, sourceInstance?: record, username?: string}
# --outOfDiskReport shape: {sqlMinRecommendedIncreaseSizeGb?: int, sqlOutOfDiskState?: "SQL_OUT_OF_DISK_STATE_UNSPECIFIED"|"NORMAL"|"SOFT_SHUTDOWN"}
# --replicaConfiguration shape: {failoverTarget?: bool, kind?: string, mysqlReplicaConfiguration?: record}
# --scheduledMaintenance shape: {canDefer?: bool, canReschedule?: bool, scheduleDeadlineTime?: string, startTime?: string}
# --serverCaCert shape: {cert?: string, certSerialNumber?: string, commonName?: string, createTime?: string, expirationTime?: string, instance?: string, kind?: string, selfLink?: string, sha1Fingerprint?: string}
# --settings shape: {activationPolicy?: "SQL_ACTIVATION_POLICY_UNSPECIFIED"|"ALWAYS"|"NEVER"|"ON_DEMAND", activeDirectoryConfig?: record, advancedMachineFeatures?: record, authorizedGaeApplications?: list<string>, availabilityType?: "SQL_AVAILABILITY_TYPE_UNSPECIFIED"|"ZONAL"|"REGIONAL", backupConfiguration?: record, collation?: string, connectorEnforcement?: "CONNECTOR_ENFORCEMENT_UNSPECIFIED"|"NOT_REQUIRED"|"REQUIRED", crashSafeReplicationEnabled?: bool, dataDiskSizeGb?: string, ... (20 more fields)}
export def "sql-v1beta4-projects-instances update-by-project-instance" [
  project: string
  instance: string
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
  --backend-type: string@backend-type-completer # The backend type. `SECOND_GEN`: Cloud SQL database instance. `EXTERNAL`: A database server that is not managed by Google. This property is read-only; use the `tier` property in the `settings` object to determine the database type.
  --connection-name: string # Connection name of the Cloud SQL instance used in connection strings.
  --current-disk-size: string # The current disk usage of the instance in bytes. This property has been deprecated. Use the "cloudsql.googleapis.com/database/disk/bytes_used" metric in Cloud Monitoring API instead. Please see [this announcement](https://groups.google.com/d/msg/google-cloud-sql-announce/I_7-F9EBhT0/BtvFtdFeAgAJ) for details. (format: int64)
  --database-version: string@database-version-completer # The database engine type and version. The `databaseVersion` field cannot be changed after instance creation.
  --disk-encryption-configuration: record # Disk encryption configuration for an instance. — shape: {kind?: string, kmsKeyName?: string}
  --disk-encryption-status: record # Disk encryption status for an instance. — shape: {kind?: string, kmsKeyVersionName?: string}
  --etag: string # This field is deprecated and will be removed from a future version of the API. Use the `settings.settingsVersion` field instead.
  --failover-replica: record # The name and status of the failover replica. — shape: {available?: bool, name?: string}
  --gce-zone: string # The Compute Engine zone that the instance is currently serving from. This value could be different from the zone that was specified when the instance was created if the instance has failed over to its secondary zone. WARNING: Changing this might restart the instance.
  --instance-type: string@instance-type-completer # The instance type.
  --ip-addresses: list # The assigned IP addresses for the instance. — item shape: {ipAddress?: string, timeToRetire?: string, type?: "SQL_IP_ADDRESS_TYPE_UNSPECIFIED"|"PRIMARY"|"OUTGOING"|"PRIVATE"|"MIGRATED_1ST_GEN"}
  --ipv6-address: string # The IPv6 address assigned to the instance. (Deprecated) This property was applicable only to First Generation instances.
  --kind: string # This is always `sql#instance`.
  --maintenance-version: string # The current software version on the instance.
  --master-instance-name: string # The name of the instance which will act as primary in the replication setup.
  --max-disk-size: string # The maximum disk size of the instance in bytes. (format: int64)
  --name: string # Name of the Cloud SQL instance. This does not include the project ID.
  --on-premises-configuration: record # On-premises instance configuration. — shape: {caCertificate?: string, clientCertificate?: string, clientKey?: string, dumpFilePath?: string, hostPort?: string, kind?: string, password?: string, sourceInstance?: record, username?: string}
  --out-of-disk-report: record # This message wraps up the information written by out-of-disk detection job. — shape: {sqlMinRecommendedIncreaseSizeGb?: int, sqlOutOfDiskState?: "SQL_OUT_OF_DISK_STATE_UNSPECIFIED"|"NORMAL"|"SOFT_SHUTDOWN"}
  --body-project: string # The project ID of the project containing the Cloud SQL instance. The Google apps domain is prefixed if applicable.
  --region: string # The geographical region. Can be: * `us-central` (`FIRST_GEN` instances only) * `us-central1` (`SECOND_GEN` instances only) * `asia-east1` or `europe-west1`. Defaults to `us-central` or `us-central1` depending on the instance type. The region cannot be changed after instance creation.
  --replica-configuration: record # Read-replica configuration for connecting to the primary instance. — shape: {failoverTarget?: bool, kind?: string, mysqlReplicaConfiguration?: record}
  --replica-names: list<string> # The replicas of the instance.
  --root-password: string # Initial root password. Use only on creation. You must set root passwords before you can connect to PostgreSQL instances.
  --satisfies-pzs: oneof<nothing, bool> # The status indicating if instance satisfiesPzs. Reserved for future use.
  --scheduled-maintenance: record # Any scheduled maintenance for this instance. — shape: {canDefer?: bool, canReschedule?: bool, scheduleDeadlineTime?: string, startTime?: string}
  --secondary-gce-zone: string # The Compute Engine zone that the failover instance is currently serving from for a regional instance. This value could be different from the zone that was specified when the instance was created if the instance has failed over to its secondary/failover zone.
  --self-link: string # The URI of this resource.
  --server-ca-cert: record # SslCerts Resource — shape: {cert?: string, certSerialNumber?: string, commonName?: string, createTime?: string, expirationTime?: string, instance?: string, kind?: string, selfLink?: string, sha1Fingerprint?: string}
  --service-account-email-address: string # The service account email address assigned to the instance. \This property is read-only.
  --settings: record # Database instance settings. — shape: {activationPolicy?: "SQL_ACTIVATION_POLICY_UNSPECIFIED"|"ALWAYS"|"NEVER"|"ON_DEMAND", activeDirectoryConfig?: record, advancedMachineFeatures?: record, authorizedGaeApplications?: list<string>, availabilityType?: "SQL_AVAILABILITY_TYPE_UNSPECIFIED"|"ZONAL"|"REGIONAL", backupConfiguration?: record, collation?: string, connectorEnforcement?: "CONNECTOR_ENFORCEMENT_UNSPECIFIED"|"NOT_REQUIRED"|"REQUIRED", crashSafeReplicationEnabled?: bool, dataDiskSizeGb?: string, ... (20 more fields)}
  --state: string@state-completer # The current serving state of the Cloud SQL instance.
  --suspension-reason: list<string> # If the instance state is SUSPENDED, the reason for the suspension.
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}") $qp)
  let req_body = {"backendType": $backend_type, "connectionName": $connection_name, "currentDiskSize": $current_disk_size, "databaseVersion": $database_version, "diskEncryptionConfiguration": $disk_encryption_configuration, "diskEncryptionStatus": $disk_encryption_status, "etag": $etag, "failoverReplica": $failover_replica, "gceZone": $gce_zone, "instanceType": $instance_type, "ipAddresses": $ip_addresses, "ipv6Address": $ipv6_address, "kind": $kind, "maintenanceVersion": $maintenance_version, "masterInstanceName": $master_instance_name, "maxDiskSize": $max_disk_size, "name": $name, "onPremisesConfiguration": $on_premises_configuration, "outOfDiskReport": $out_of_disk_report, "project": $body_project, "region": $region, "replicaConfiguration": $replica_configuration, "replicaNames": $replica_names, "rootPassword": $root_password, "satisfiesPzs": $satisfies_pzs, "scheduledMaintenance": $scheduled_maintenance, "secondaryGceZone": $secondary_gce_zone, "selfLink": $self_link, "serverCaCert": $server_ca_cert, "serviceAccountEmailAddress": $service_account_email_address, "settings": $settings, "state": $state, "suspensionReason": $suspension_reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates settings of a Cloud SQL instance. Using this operation might cause your instance to restart.
#
# PUT /sql/v1beta4/projects/{project}/instances/{instance}
# operationId: sql.instances.update
# --diskEncryptionConfiguration shape: {kind?: string, kmsKeyName?: string}
# --diskEncryptionStatus shape: {kind?: string, kmsKeyVersionName?: string}
# --failoverReplica shape: {available?: bool, name?: string}
# --ipAddresses item shape: {ipAddress?: string, timeToRetire?: string, type?: "SQL_IP_ADDRESS_TYPE_UNSPECIFIED"|"PRIMARY"|"OUTGOING"|"PRIVATE"|"MIGRATED_1ST_GEN"}
# --onPremisesConfiguration shape: {caCertificate?: string, clientCertificate?: string, clientKey?: string, dumpFilePath?: string, hostPort?: string, kind?: string, password?: string, sourceInstance?: record, username?: string}
# --outOfDiskReport shape: {sqlMinRecommendedIncreaseSizeGb?: int, sqlOutOfDiskState?: "SQL_OUT_OF_DISK_STATE_UNSPECIFIED"|"NORMAL"|"SOFT_SHUTDOWN"}
# --replicaConfiguration shape: {failoverTarget?: bool, kind?: string, mysqlReplicaConfiguration?: record}
# --scheduledMaintenance shape: {canDefer?: bool, canReschedule?: bool, scheduleDeadlineTime?: string, startTime?: string}
# --serverCaCert shape: {cert?: string, certSerialNumber?: string, commonName?: string, createTime?: string, expirationTime?: string, instance?: string, kind?: string, selfLink?: string, sha1Fingerprint?: string}
# --settings shape: {activationPolicy?: "SQL_ACTIVATION_POLICY_UNSPECIFIED"|"ALWAYS"|"NEVER"|"ON_DEMAND", activeDirectoryConfig?: record, advancedMachineFeatures?: record, authorizedGaeApplications?: list<string>, availabilityType?: "SQL_AVAILABILITY_TYPE_UNSPECIFIED"|"ZONAL"|"REGIONAL", backupConfiguration?: record, collation?: string, connectorEnforcement?: "CONNECTOR_ENFORCEMENT_UNSPECIFIED"|"NOT_REQUIRED"|"REQUIRED", crashSafeReplicationEnabled?: bool, dataDiskSizeGb?: string, ... (20 more fields)}
export def "sql-v1beta4-projects-instances update-by-project-instance-1" [
  project: string
  instance: string
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
  --backend-type: string@backend-type-completer # The backend type. `SECOND_GEN`: Cloud SQL database instance. `EXTERNAL`: A database server that is not managed by Google. This property is read-only; use the `tier` property in the `settings` object to determine the database type.
  --connection-name: string # Connection name of the Cloud SQL instance used in connection strings.
  --current-disk-size: string # The current disk usage of the instance in bytes. This property has been deprecated. Use the "cloudsql.googleapis.com/database/disk/bytes_used" metric in Cloud Monitoring API instead. Please see [this announcement](https://groups.google.com/d/msg/google-cloud-sql-announce/I_7-F9EBhT0/BtvFtdFeAgAJ) for details. (format: int64)
  --database-version: string@database-version-completer # The database engine type and version. The `databaseVersion` field cannot be changed after instance creation.
  --disk-encryption-configuration: record # Disk encryption configuration for an instance. — shape: {kind?: string, kmsKeyName?: string}
  --disk-encryption-status: record # Disk encryption status for an instance. — shape: {kind?: string, kmsKeyVersionName?: string}
  --etag: string # This field is deprecated and will be removed from a future version of the API. Use the `settings.settingsVersion` field instead.
  --failover-replica: record # The name and status of the failover replica. — shape: {available?: bool, name?: string}
  --gce-zone: string # The Compute Engine zone that the instance is currently serving from. This value could be different from the zone that was specified when the instance was created if the instance has failed over to its secondary zone. WARNING: Changing this might restart the instance.
  --instance-type: string@instance-type-completer # The instance type.
  --ip-addresses: list # The assigned IP addresses for the instance. — item shape: {ipAddress?: string, timeToRetire?: string, type?: "SQL_IP_ADDRESS_TYPE_UNSPECIFIED"|"PRIMARY"|"OUTGOING"|"PRIVATE"|"MIGRATED_1ST_GEN"}
  --ipv6-address: string # The IPv6 address assigned to the instance. (Deprecated) This property was applicable only to First Generation instances.
  --kind: string # This is always `sql#instance`.
  --maintenance-version: string # The current software version on the instance.
  --master-instance-name: string # The name of the instance which will act as primary in the replication setup.
  --max-disk-size: string # The maximum disk size of the instance in bytes. (format: int64)
  --name: string # Name of the Cloud SQL instance. This does not include the project ID.
  --on-premises-configuration: record # On-premises instance configuration. — shape: {caCertificate?: string, clientCertificate?: string, clientKey?: string, dumpFilePath?: string, hostPort?: string, kind?: string, password?: string, sourceInstance?: record, username?: string}
  --out-of-disk-report: record # This message wraps up the information written by out-of-disk detection job. — shape: {sqlMinRecommendedIncreaseSizeGb?: int, sqlOutOfDiskState?: "SQL_OUT_OF_DISK_STATE_UNSPECIFIED"|"NORMAL"|"SOFT_SHUTDOWN"}
  --body-project: string # The project ID of the project containing the Cloud SQL instance. The Google apps domain is prefixed if applicable.
  --region: string # The geographical region. Can be: * `us-central` (`FIRST_GEN` instances only) * `us-central1` (`SECOND_GEN` instances only) * `asia-east1` or `europe-west1`. Defaults to `us-central` or `us-central1` depending on the instance type. The region cannot be changed after instance creation.
  --replica-configuration: record # Read-replica configuration for connecting to the primary instance. — shape: {failoverTarget?: bool, kind?: string, mysqlReplicaConfiguration?: record}
  --replica-names: list<string> # The replicas of the instance.
  --root-password: string # Initial root password. Use only on creation. You must set root passwords before you can connect to PostgreSQL instances.
  --satisfies-pzs: oneof<nothing, bool> # The status indicating if instance satisfiesPzs. Reserved for future use.
  --scheduled-maintenance: record # Any scheduled maintenance for this instance. — shape: {canDefer?: bool, canReschedule?: bool, scheduleDeadlineTime?: string, startTime?: string}
  --secondary-gce-zone: string # The Compute Engine zone that the failover instance is currently serving from for a regional instance. This value could be different from the zone that was specified when the instance was created if the instance has failed over to its secondary/failover zone.
  --self-link: string # The URI of this resource.
  --server-ca-cert: record # SslCerts Resource — shape: {cert?: string, certSerialNumber?: string, commonName?: string, createTime?: string, expirationTime?: string, instance?: string, kind?: string, selfLink?: string, sha1Fingerprint?: string}
  --service-account-email-address: string # The service account email address assigned to the instance. \This property is read-only.
  --settings: record # Database instance settings. — shape: {activationPolicy?: "SQL_ACTIVATION_POLICY_UNSPECIFIED"|"ALWAYS"|"NEVER"|"ON_DEMAND", activeDirectoryConfig?: record, advancedMachineFeatures?: record, authorizedGaeApplications?: list<string>, availabilityType?: "SQL_AVAILABILITY_TYPE_UNSPECIFIED"|"ZONAL"|"REGIONAL", backupConfiguration?: record, collation?: string, connectorEnforcement?: "CONNECTOR_ENFORCEMENT_UNSPECIFIED"|"NOT_REQUIRED"|"REQUIRED", crashSafeReplicationEnabled?: bool, dataDiskSizeGb?: string, ... (20 more fields)}
  --state: string@state-completer # The current serving state of the Cloud SQL instance.
  --suspension-reason: list<string> # If the instance state is SUSPENDED, the reason for the suspension.
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}") $qp)
  let req_body = {"backendType": $backend_type, "connectionName": $connection_name, "currentDiskSize": $current_disk_size, "databaseVersion": $database_version, "diskEncryptionConfiguration": $disk_encryption_configuration, "diskEncryptionStatus": $disk_encryption_status, "etag": $etag, "failoverReplica": $failover_replica, "gceZone": $gce_zone, "instanceType": $instance_type, "ipAddresses": $ip_addresses, "ipv6Address": $ipv6_address, "kind": $kind, "maintenanceVersion": $maintenance_version, "masterInstanceName": $master_instance_name, "maxDiskSize": $max_disk_size, "name": $name, "onPremisesConfiguration": $on_premises_configuration, "outOfDiskReport": $out_of_disk_report, "project": $body_project, "region": $region, "replicaConfiguration": $replica_configuration, "replicaNames": $replica_names, "rootPassword": $root_password, "satisfiesPzs": $satisfies_pzs, "scheduledMaintenance": $scheduled_maintenance, "secondaryGceZone": $secondary_gce_zone, "selfLink": $self_link, "serverCaCert": $server_ca_cert, "serviceAccountEmailAddress": $service_account_email_address, "settings": $settings, "state": $state, "suspensionReason": $suspension_reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Add a new trusted Certificate Authority (CA) version for the specified instance. Required to prepare for a certificate rotation. If a CA version was previously added but never used in a certificate rotation, this operation replaces that version. There cannot be more than one CA version waiting to be rotated in.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/addServerCa
# operationId: sql.instances.addServerCa
export def "sql-v1beta4-projects-instances-add-server-ca create" [
  project: string
  instance: string
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
]: nothing -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/addServerCa") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Lists all backup runs associated with the project or a given instance and configuration in the reverse chronological order of the backup initiation time.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/backupRuns
# operationId: sql.backupRuns.list
export def "sql-v1beta4-projects-instances-backup-runs list" [
  project: string
  instance: string
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
  --max-results: int # Maximum number of backup runs per response.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
]: nothing -> record<items: table<backupKind: string, description: string, diskEncryptionConfiguration: record, diskEncryptionStatus: record, endTime: string, enqueuedTime: string, error: record, id: string, instance: string, kind: string, location: string, selfLink: string, startTime: string, status: string, timeZone: string, type: string, windowStartTime: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/backupRuns") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Creates a new backup run on demand.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/backupRuns
# operationId: sql.backupRuns.insert
# --diskEncryptionConfiguration shape: {kind?: string, kmsKeyName?: string}
# --diskEncryptionStatus shape: {kind?: string, kmsKeyVersionName?: string}
# --error shape: {code?: string, kind?: string, message?: string}
export def "sql-v1beta4-projects-instances-backup-runs create" [
  project: string
  instance: string
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
  --backup-kind: string@backup-kind-completer # Specifies the kind of backup, PHYSICAL or DEFAULT_SNAPSHOT.
  --description: string # The description of this run, only applicable to on-demand backups.
  --disk-encryption-configuration: record # Disk encryption configuration for an instance. — shape: {kind?: string, kmsKeyName?: string}
  --disk-encryption-status: record # Disk encryption status for an instance. — shape: {kind?: string, kmsKeyVersionName?: string}
  --end-time: string # The time the backup operation completed in UTC timezone in [RFC 3339](https://tools.ietf.org/html/rfc3339) format, for example `2012-11-15T16:19:00.094Z`. (format: google-datetime)
  --enqueued-time: string # The time the run was enqueued in UTC timezone in [RFC 3339](https://tools.ietf.org/html/rfc3339) format, for example `2012-11-15T16:19:00.094Z`. (format: google-datetime)
  --body-error: record # Database instance operation error. — shape: {code?: string, kind?: string, message?: string}
  --id: string # The identifier for this backup run. Unique only for a specific Cloud SQL instance. (format: int64)
  --body-instance: string # Name of the database instance.
  --kind: string # This is always `sql#backupRun`.
  --location: string # Location of the backups.
  --self-link: string # The URI of this resource.
  --start-time: string # The time the backup operation actually started in UTC timezone in [RFC 3339](https://tools.ietf.org/html/rfc3339) format, for example `2012-11-15T16:19:00.094Z`. (format: google-datetime)
  --status: string@status-completer # The status of this run.
  --time-zone: string # Backup time zone to prevent restores to an instance with a different time zone. Now relevant only for SQL Server.
  --type: string@type-completer # The type of this run; can be either "AUTOMATED" or "ON_DEMAND" or "FINAL". This field defaults to "ON_DEMAND" and is ignored, when specified for insert requests.
  --window-start-time: string # The start time of the backup window during which this the backup was attempted in [RFC 3339](https://tools.ietf.org/html/rfc3339) format, for example `2012-11-15T16:19:00.094Z`. (format: google-datetime)
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/backupRuns") $qp)
  let req_body = {"backupKind": $backup_kind, "description": $description, "diskEncryptionConfiguration": $disk_encryption_configuration, "diskEncryptionStatus": $disk_encryption_status, "endTime": $end_time, "enqueuedTime": $enqueued_time, "error": $body_error, "id": $id, "instance": $body_instance, "kind": $kind, "location": $location, "selfLink": $self_link, "startTime": $start_time, "status": $status, "timeZone": $time_zone, "type": $type, "windowStartTime": $window_start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes the backup taken by a backup run.
#
# DELETE /sql/v1beta4/projects/{project}/instances/{instance}/backupRuns/{id}
# operationId: sql.backupRuns.delete
export def "sql-v1beta4-projects-instances-backup-runs delete" [
  project: string
  instance: string
  id: string
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
]: nothing -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance), id: (encode-path-segment $id)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/backupRuns/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a resource containing information about a backup run.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/backupRuns/{id}
# operationId: sql.backupRuns.get
export def "sql-v1beta4-projects-instances-backup-runs get" [
  project: string
  instance: string
  id: string
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
]: nothing -> record<backupKind: string, description: string, diskEncryptionConfiguration: record<kind: string, kmsKeyName: string>, diskEncryptionStatus: record<kind: string, kmsKeyVersionName: string>, endTime: string, enqueuedTime: string, error: record<code: string, kind: string, message: string>, id: string, instance: string, kind: string, location: string, selfLink: string, startTime: string, status: string, timeZone: string, type: string, windowStartTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance), id: (encode-path-segment $id)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/backupRuns/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Creates a Cloud SQL instance as a clone of the source instance. Using this operation might cause your instance to restart.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/clone
# operationId: sql.instances.clone
# --cloneContext shape: {allocatedIpRange?: string, binLogCoordinates?: record, databaseNames?: list<string>, destinationInstanceName?: string, kind?: string, pitrTimestampMs?: string, pointInTime?: string}
export def "sql-v1beta4-projects-instances-clone clone" [
  project: string
  instance: string
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
  --clone-context: record # Database instance clone context. — shape: {allocatedIpRange?: string, binLogCoordinates?: record, databaseNames?: list<string>, destinationInstanceName?: string, kind?: string, pitrTimestampMs?: string, pointInTime?: string}
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/clone") $qp)
  let req_body = {"cloneContext": $clone_context} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Retrieves connect settings about a Cloud SQL instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/connectSettings
# operationId: sql.connect.get
export def "sql-v1beta4-projects-instances-connect-settings get" [
  project: string
  instance: string
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
  --read-time: string # Optional. Optional snapshot read timestamp to trade freshness for performance.
]: nothing -> record<backendType: string, databaseVersion: string, ipAddresses: table<ipAddress: string, timeToRetire: string, type: string>, kind: string, region: string, serverCaCert: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "readTime" $read_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/connectSettings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "readTime": $read_time} | compact), body: null}
}

# Generates a short-lived X509 certificate containing the provided public key and signed by a private key specific to the target instance. Users may use the certificate to authenticate as themselves when connecting to the database.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/createEphemeral
# operationId: sql.sslCerts.createEphemeral
export def "sql-v1beta4-projects-instances-create-ephemeral create" [
  project: string
  instance: string
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
  --access-token-body: string # Access token to include in the signed certificate. (body field)
  --public-key: string # PEM encoded public key to include in the signed certificate.
]: any -> record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/createEphemeral") $qp)
  let req_body = {"access_token": $access_token_body, "public_key": $public_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists databases in the specified Cloud SQL instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/databases
# operationId: sql.databases.list
export def "sql-v1beta4-projects-instances-databases list" [
  project: string
  instance: string
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
]: nothing -> record<items: table<charset: string, collation: string, etag: string, instance: string, kind: string, name: string, project: string, selfLink: string, sqlserverDatabaseDetails: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/databases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Inserts a resource containing information about a database inside a Cloud SQL instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/databases
# operationId: sql.databases.insert
# --sqlserverDatabaseDetails shape: {compatibilityLevel?: int, recoveryModel?: string}
export def "sql-v1beta4-projects-instances-databases create" [
  project: string
  instance: string
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
  --charset: string # The Cloud SQL charset value.
  --collation: string # The Cloud SQL collation value.
  --etag: string # This field is deprecated and will be removed from a future version of the API.
  --body-instance: string # The name of the Cloud SQL instance. This does not include the project ID.
  --kind: string # This is always `sql#database`.
  --name: string # The name of the database in the Cloud SQL instance. This does not include the project ID or instance name.
  --body-project: string # The project ID of the project containing the Cloud SQL database. The Google apps domain is prefixed if applicable.
  --self-link: string # The URI of this resource.
  --sqlserver-database-details: record # Represents a Sql Server database on the Cloud SQL instance. — shape: {compatibilityLevel?: int, recoveryModel?: string}
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/databases") $qp)
  let req_body = {"charset": $charset, "collation": $collation, "etag": $etag, "instance": $body_instance, "kind": $kind, "name": $name, "project": $body_project, "selfLink": $self_link, "sqlserverDatabaseDetails": $sqlserver_database_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes a database from a Cloud SQL instance.
#
# DELETE /sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}
# operationId: sql.databases.delete
export def "sql-v1beta4-projects-instances-databases delete" [
  project: string
  instance: string
  database: string
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
]: nothing -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance), database: (encode-path-segment $database)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a resource containing information about a database inside a Cloud SQL instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}
# operationId: sql.databases.get
export def "sql-v1beta4-projects-instances-databases get" [
  project: string
  instance: string
  database: string
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
]: nothing -> record<charset: string, collation: string, etag: string, instance: string, kind: string, name: string, project: string, selfLink: string, sqlserverDatabaseDetails: record<compatibilityLevel: int, recoveryModel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance), database: (encode-path-segment $database)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Partially updates a resource containing information about a database inside a Cloud SQL instance. This method supports patch semantics.
#
# PATCH /sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}
# operationId: sql.databases.patch
# --sqlserverDatabaseDetails shape: {compatibilityLevel?: int, recoveryModel?: string}
export def "sql-v1beta4-projects-instances-databases update-by-project-instance-database" [
  project: string
  instance: string
  database: string
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
  --charset: string # The Cloud SQL charset value.
  --collation: string # The Cloud SQL collation value.
  --etag: string # This field is deprecated and will be removed from a future version of the API.
  --body-instance: string # The name of the Cloud SQL instance. This does not include the project ID.
  --kind: string # This is always `sql#database`.
  --name: string # The name of the database in the Cloud SQL instance. This does not include the project ID or instance name.
  --body-project: string # The project ID of the project containing the Cloud SQL database. The Google apps domain is prefixed if applicable.
  --self-link: string # The URI of this resource.
  --sqlserver-database-details: record # Represents a Sql Server database on the Cloud SQL instance. — shape: {compatibilityLevel?: int, recoveryModel?: string}
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance), database: (encode-path-segment $database)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}") $qp)
  let req_body = {"charset": $charset, "collation": $collation, "etag": $etag, "instance": $body_instance, "kind": $kind, "name": $name, "project": $body_project, "selfLink": $self_link, "sqlserverDatabaseDetails": $sqlserver_database_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates a resource containing information about a database inside a Cloud SQL instance.
#
# PUT /sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}
# operationId: sql.databases.update
# --sqlserverDatabaseDetails shape: {compatibilityLevel?: int, recoveryModel?: string}
export def "sql-v1beta4-projects-instances-databases update-by-project-instance-database-1" [
  project: string
  instance: string
  database: string
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
  --charset: string # The Cloud SQL charset value.
  --collation: string # The Cloud SQL collation value.
  --etag: string # This field is deprecated and will be removed from a future version of the API.
  --body-instance: string # The name of the Cloud SQL instance. This does not include the project ID.
  --kind: string # This is always `sql#database`.
  --name: string # The name of the database in the Cloud SQL instance. This does not include the project ID or instance name.
  --body-project: string # The project ID of the project containing the Cloud SQL database. The Google apps domain is prefixed if applicable.
  --self-link: string # The URI of this resource.
  --sqlserver-database-details: record # Represents a Sql Server database on the Cloud SQL instance. — shape: {compatibilityLevel?: int, recoveryModel?: string}
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  if ($database | is-empty) { error make --unspanned { msg: "path parameter 'database' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance), database: (encode-path-segment $database)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/databases/{database}") $qp)
  let req_body = {"charset": $charset, "collation": $collation, "etag": $etag, "instance": $body_instance, "kind": $kind, "name": $name, "project": $body_project, "selfLink": $self_link, "sqlserverDatabaseDetails": $sqlserver_database_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Demotes the stand-alone instance to be a Cloud SQL read replica for an external database server.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/demoteMaster
# operationId: sql.instances.demoteMaster
# --demoteMasterContext shape: {kind?: string, masterInstanceName?: string, replicaConfiguration?: record, skipReplicationSetup?: bool, verifyGtidConsistency?: bool}
export def "sql-v1beta4-projects-instances-demote-master create" [
  project: string
  instance: string
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
  --demote-master-context: record # Database instance demote primary instance context. — shape: {kind?: string, masterInstanceName?: string, replicaConfiguration?: record, skipReplicationSetup?: bool, verifyGtidConsistency?: bool}
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/demoteMaster") $qp)
  let req_body = {"demoteMasterContext": $demote_master_context} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Exports data from a Cloud SQL instance to a Cloud Storage bucket as a SQL dump or CSV file.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/export
# operationId: sql.instances.export
# --exportContext shape: {bakExportOptions?: record, csvExportOptions?: record, databases?: list<string>, fileType?: "SQL_FILE_TYPE_UNSPECIFIED"|"SQL"|"CSV"|"BAK", kind?: string, offload?: bool, sqlExportOptions?: record, uri?: string}
export def "sql-v1beta4-projects-instances-export export" [
  project: string
  instance: string
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
  --export-context: record # Database instance export context. — shape: {bakExportOptions?: record, csvExportOptions?: record, databases?: list<string>, fileType?: "SQL_FILE_TYPE_UNSPECIFIED"|"SQL"|"CSV"|"BAK", kind?: string, offload?: bool, sqlExportOptions?: record, uri?: string}
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/export") $qp)
  let req_body = {"exportContext": $export_context} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Initiates a manual failover of a high availability (HA) primary instance to a standby instance, which becomes the primary instance. Users are then rerouted to the new primary. For more information, see the [Overview of high availability](https://cloud.google.com/sql/docs/mysql/high-availability) page in the Cloud SQL documentation. If using Legacy HA (MySQL only), this causes the instance to failover to its failover replica instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/failover
# operationId: sql.instances.failover
# --failoverContext shape: {kind?: string, settingsVersion?: string}
export def "sql-v1beta4-projects-instances-failover create" [
  project: string
  instance: string
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
  --failover-context: record # Database instance failover context. — shape: {kind?: string, settingsVersion?: string}
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/failover") $qp)
  let req_body = {"failoverContext": $failover_context} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Get Disk Shrink Config for a given instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/getDiskShrinkConfig
# operationId: sql.projects.instances.getDiskShrinkConfig
export def "sql-v1beta4-projects-instances-get-disk-shrink-config get" [
  project: string
  instance: string
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
]: nothing -> record<kind: string, minimalTargetSizeGb: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/getDiskShrinkConfig") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Imports data into a Cloud SQL instance from a SQL dump or CSV file in Cloud Storage.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/import
# operationId: sql.instances.import
# --importContext shape: {bakImportOptions?: record, csvImportOptions?: record, database?: string, fileType?: "SQL_FILE_TYPE_UNSPECIFIED"|"SQL"|"CSV"|"BAK", importUser?: string, kind?: string, uri?: string}
export def "sql-v1beta4-projects-instances-import import" [
  project: string
  instance: string
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
  --import-context: record # Database instance import context. — shape: {bakImportOptions?: record, csvImportOptions?: record, database?: string, fileType?: "SQL_FILE_TYPE_UNSPECIFIED"|"SQL"|"CSV"|"BAK", importUser?: string, kind?: string, uri?: string}
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/import") $qp)
  let req_body = {"importContext": $import_context} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists all of the trusted Certificate Authorities (CAs) for the specified instance. There can be up to three CAs listed: the CA that was used to sign the certificate that is currently in use, a CA that has been added but not yet used to sign a certificate, and a CA used to sign a certificate that has previously rotated out.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/listServerCas
# operationId: sql.instances.listServerCas
export def "sql-v1beta4-projects-instances-list-server-cas list" [
  project: string
  instance: string
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
]: nothing -> record<activeVersion: string, certs: table<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/listServerCas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Perform Disk Shrink on primary instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/performDiskShrink
# operationId: sql.projects.instances.performDiskShrink
export def "sql-v1beta4-projects-instances-perform-disk-shrink create" [
  project: string
  instance: string
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
  --target-size-gb: string # The target disk shrink size in GigaBytes. (format: int64)
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/performDiskShrink") $qp)
  let req_body = {"targetSizeGb": $target_size_gb} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Promotes the read replica instance to be a stand-alone Cloud SQL instance. Using this operation might cause your instance to restart.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/promoteReplica
# operationId: sql.instances.promoteReplica
export def "sql-v1beta4-projects-instances-promote-replica create" [
  project: string
  instance: string
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
]: nothing -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/promoteReplica") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Reschedules the maintenance on the given instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/rescheduleMaintenance
# operationId: sql.projects.instances.rescheduleMaintenance
# --reschedule shape: {rescheduleType?: "RESCHEDULE_TYPE_UNSPECIFIED"|"IMMEDIATE"|"NEXT_AVAILABLE_WINDOW"|"SPECIFIC_TIME", scheduleTime?: string}
export def "sql-v1beta4-projects-instances-reschedule-maintenance create" [
  project: string
  instance: string
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
  --reschedule: record # shape: {rescheduleType?: "RESCHEDULE_TYPE_UNSPECIFIED"|"IMMEDIATE"|"NEXT_AVAILABLE_WINDOW"|"SPECIFIC_TIME", scheduleTime?: string}
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/rescheduleMaintenance") $qp)
  let req_body = {"reschedule": $reschedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Reset Replica Size to primary instance disk size.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/resetReplicaSize
# operationId: sql.projects.instances.resetReplicaSize
export def "sql-v1beta4-projects-instances-reset-replica-size reset" [
  project: string
  instance: string
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
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/resetReplicaSize") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes all client certificates and generates a new server SSL certificate for the instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/resetSslConfig
# operationId: sql.instances.resetSslConfig
export def "sql-v1beta4-projects-instances-reset-ssl-config reset" [
  project: string
  instance: string
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
]: nothing -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/resetSslConfig") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Restarts a Cloud SQL instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/restart
# operationId: sql.instances.restart
export def "sql-v1beta4-projects-instances-restart restart" [
  project: string
  instance: string
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
]: nothing -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/restart") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Restores a backup of a Cloud SQL instance. Using this operation might cause your instance to restart.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/restoreBackup
# operationId: sql.instances.restoreBackup
# --restoreBackupContext shape: {backupRunId?: string, instanceId?: string, kind?: string, project?: string}
export def "sql-v1beta4-projects-instances-restore-backup create" [
  project: string
  instance: string
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
  --restore-backup-context: record # Database instance restore from backup context. Backup context contains source instance id and project id. — shape: {backupRunId?: string, instanceId?: string, kind?: string, project?: string}
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/restoreBackup") $qp)
  let req_body = {"restoreBackupContext": $restore_backup_context} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Rotates the server certificate to one signed by the Certificate Authority (CA) version previously added with the addServerCA method.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/rotateServerCa
# operationId: sql.instances.rotateServerCa
# --rotateServerCaContext shape: {kind?: string, nextVersion?: string}
export def "sql-v1beta4-projects-instances-rotate-server-ca create" [
  project: string
  instance: string
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
  --rotate-server-ca-context: record # Instance rotate server CA context. — shape: {kind?: string, nextVersion?: string}
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/rotateServerCa") $qp)
  let req_body = {"rotateServerCaContext": $rotate_server_ca_context} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists all of the current SSL certificates for the instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/sslCerts
# operationId: sql.sslCerts.list
export def "sql-v1beta4-projects-instances-ssl-certs list" [
  project: string
  instance: string
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
]: nothing -> record<items: table<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/sslCerts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Creates an SSL certificate and returns it along with the private key and server certificate authority. The new certificate will not be usable until the instance is restarted.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/sslCerts
# operationId: sql.sslCerts.insert
export def "sql-v1beta4-projects-instances-ssl-certs create" [
  project: string
  instance: string
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
  --common-name: string # User supplied name. Must be a distinct name from the other certificates for this instance.
]: any -> record<clientCert: record<certInfo: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>, certPrivateKey: string>, kind: string, operation: record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list, kind: string>, exportContext: record<bakExportOptions: record, csvExportOptions: record, databases: list, fileType: string, kind: string, offload: bool, sqlExportOptions: record, uri: string>, importContext: record<bakImportOptions: record, csvImportOptions: record, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>, serverCaCert: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/sslCerts") $qp)
  let req_body = {"commonName": $common_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes the SSL certificate. For First Generation instances, the certificate remains valid until the instance is restarted.
#
# DELETE /sql/v1beta4/projects/{project}/instances/{instance}/sslCerts/{sha1Fingerprint}
# operationId: sql.sslCerts.delete
export def "sql-v1beta4-projects-instances-ssl-certs delete" [
  project: string
  instance: string
  sha1_fingerprint: string
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
]: nothing -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  if ($sha1_fingerprint | is-empty) { error make --unspanned { msg: "path parameter 'sha1Fingerprint' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance), sha1_fingerprint: (encode-path-segment $sha1_fingerprint)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/sslCerts/{sha1_fingerprint}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a particular SSL certificate. Does not include the private key (required for usage). The private key must be saved from the response to initial creation.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/sslCerts/{sha1Fingerprint}
# operationId: sql.sslCerts.get
export def "sql-v1beta4-projects-instances-ssl-certs get" [
  project: string
  instance: string
  sha1_fingerprint: string
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
]: nothing -> record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  if ($sha1_fingerprint | is-empty) { error make --unspanned { msg: "path parameter 'sha1Fingerprint' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance), sha1_fingerprint: (encode-path-segment $sha1_fingerprint)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/sslCerts/{sha1_fingerprint}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Start External primary instance migration.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/startExternalSync
# operationId: sql.projects.instances.startExternalSync
# --mysqlSyncConfig shape: {initialSyncFlags?: list}
export def "sql-v1beta4-projects-instances-start-external-sync start" [
  project: string
  instance: string
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
  --mysql-sync-config: record # MySQL-specific external server sync settings. — shape: {initialSyncFlags?: list}
  --skip-verification: oneof<nothing, bool> # Whether to skip the verification step (VESS).
  --sync-mode: string@sync-mode-completer # External sync mode.
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/startExternalSync") $qp)
  let req_body = {"mysqlSyncConfig": $mysql_sync_config, "skipVerification": $skip_verification, "syncMode": $sync_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Starts the replication in the read replica instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/startReplica
# operationId: sql.instances.startReplica
export def "sql-v1beta4-projects-instances-start-replica start" [
  project: string
  instance: string
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
]: nothing -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/startReplica") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Stops the replication in the read replica instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/stopReplica
# operationId: sql.instances.stopReplica
export def "sql-v1beta4-projects-instances-stop-replica stop" [
  project: string
  instance: string
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
]: nothing -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/stopReplica") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Truncate MySQL general and slow query log tables MySQL only.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/truncateLog
# operationId: sql.instances.truncateLog
# --truncateLogContext shape: {kind?: string, logType?: string}
export def "sql-v1beta4-projects-instances-truncate-log create" [
  project: string
  instance: string
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
  --truncate-log-context: record # Database Instance truncate log context. — shape: {kind?: string, logType?: string}
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/truncateLog") $qp)
  let req_body = {"truncateLogContext": $truncate_log_context} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes a user from a Cloud SQL instance.
#
# DELETE /sql/v1beta4/projects/{project}/instances/{instance}/users
# operationId: sql.users.delete
export def "sql-v1beta4-projects-instances-users delete" [
  project: string
  instance: string
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
  --host: string # Host of the user in the instance.
  --name: string # Name of the user in the instance.
]: nothing -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "host": $host, "name": $name} | compact), body: null}
}

# Lists users in the specified Cloud SQL instance.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/users
# operationId: sql.users.list
export def "sql-v1beta4-projects-instances-users list" [
  project: string
  instance: string
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
]: nothing -> record<items: table<dualPasswordType: string, etag: string, host: string, instance: string, kind: string, name: string, password: string, passwordPolicy: record, project: string, sqlserverUserDetails: record, type: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Creates a new user in a Cloud SQL instance.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/users
# operationId: sql.users.insert
# --passwordPolicy shape: {allowedFailedAttempts?: int, enableFailedAttemptsCheck?: bool, enablePasswordVerification?: bool, passwordExpirationDuration?: string, status?: record}
# --sqlserverUserDetails shape: {disabled?: bool, serverRoles?: list<string>}
export def "sql-v1beta4-projects-instances-users create" [
  project: string
  instance: string
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
  --dual-password-type: string@dual-password-type-completer # Dual password status for the user.
  --etag: string # This field is deprecated and will be removed from a future version of the API.
  --host: string # Optional. The host from which the user can connect. For `insert` operations, host defaults to an empty string. For `update` operations, host is specified as part of the request URL. The host name cannot be updated after insertion. For a MySQL instance, it's required; for a PostgreSQL or SQL Server instance, it's optional.
  --body-instance: string # The name of the Cloud SQL instance. This does not include the project ID. Can be omitted for *update* because it is already specified on the URL.
  --kind: string # This is always `sql#user`.
  --name: string # The name of the user in the Cloud SQL instance. Can be omitted for `update` because it is already specified in the URL.
  --password: string # The password for the user.
  --password-policy: record # User level password validation policy. — shape: {allowedFailedAttempts?: int, enableFailedAttemptsCheck?: bool, enablePasswordVerification?: bool, passwordExpirationDuration?: string, status?: record}
  --body-project: string # The project ID of the project containing the Cloud SQL database. The Google apps domain is prefixed if applicable. Can be omitted for *update* because it is already specified on the URL.
  --sqlserver-user-details: record # Represents a Sql Server user on the Cloud SQL instance. — shape: {disabled?: bool, serverRoles?: list<string>}
  --type: string@type-completer-1 # The user type. It determines the method to authenticate the user during login. The default is the database's built-in user type.
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/users") $qp)
  let req_body = {"dualPasswordType": $dual_password_type, "etag": $etag, "host": $host, "instance": $body_instance, "kind": $kind, "name": $name, "password": $password, "passwordPolicy": $password_policy, "project": $body_project, "sqlserverUserDetails": $sqlserver_user_details, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates an existing user in a Cloud SQL instance.
#
# PUT /sql/v1beta4/projects/{project}/instances/{instance}/users
# operationId: sql.users.update
# --passwordPolicy shape: {allowedFailedAttempts?: int, enableFailedAttemptsCheck?: bool, enablePasswordVerification?: bool, passwordExpirationDuration?: string, status?: record}
# --sqlserverUserDetails shape: {disabled?: bool, serverRoles?: list<string>}
export def "sql-v1beta4-projects-instances-users update" [
  project: string
  instance: string
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
  --host: string # Optional. Host of the user in the instance.
  --name: string # Name of the user in the instance.
  --dual-password-type: string@dual-password-type-completer # Dual password status for the user.
  --etag: string # This field is deprecated and will be removed from a future version of the API.
  --host-body: string # Optional. The host from which the user can connect. For `insert` operations, host defaults to an empty string. For `update` operations, host is specified as part of the request URL. The host name cannot be updated after insertion. For a MySQL instance, it's required; for a PostgreSQL or SQL Server instance, it's optional. (body field)
  --body-instance: string # The name of the Cloud SQL instance. This does not include the project ID. Can be omitted for *update* because it is already specified on the URL.
  --kind: string # This is always `sql#user`.
  --name-body: string # The name of the user in the Cloud SQL instance. Can be omitted for `update` because it is already specified in the URL. (body field)
  --password: string # The password for the user.
  --password-policy: record # User level password validation policy. — shape: {allowedFailedAttempts?: int, enableFailedAttemptsCheck?: bool, enablePasswordVerification?: bool, passwordExpirationDuration?: string, status?: record}
  --body-project: string # The project ID of the project containing the Cloud SQL database. The Google apps domain is prefixed if applicable. Can be omitted for *update* because it is already specified on the URL.
  --sqlserver-user-details: record # Represents a Sql Server user on the Cloud SQL instance. — shape: {disabled?: bool, serverRoles?: list<string>}
  --type: string@type-completer-1 # The user type. It determines the method to authenticate the user during login. The default is the database's built-in user type.
]: any -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/users") $qp)
  let req_body = {"dualPasswordType": $dual_password_type, "etag": $etag, "host": $host_body, "instance": $body_instance, "kind": $kind, "name": $name_body, "password": $password, "passwordPolicy": $password_policy, "project": $body_project, "sqlserverUserDetails": $sqlserver_user_details, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "host": $host, "name": $name} | compact), body: $req_body}
}

# Retrieves a resource containing information about a user.
#
# GET /sql/v1beta4/projects/{project}/instances/{instance}/users/{name}
# operationId: sql.users.get
export def "sql-v1beta4-projects-instances-users get" [
  project: string
  instance: string
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
  --host: string # Host of a user of the instance.
]: nothing -> record<dualPasswordType: string, etag: string, host: string, instance: string, kind: string, name: string, password: string, passwordPolicy: record<allowedFailedAttempts: int, enableFailedAttemptsCheck: bool, enablePasswordVerification: bool, passwordExpirationDuration: string, status: record<locked: bool, passwordExpirationTime: string>>, project: string, sqlserverUserDetails: record<disabled: bool, serverRoles: list<string>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "host" $host "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance), name: (encode-path-segment $name)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/users/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "host": $host} | compact), body: null}
}

# Verify External primary instance external sync settings.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}/verifyExternalSyncSettings
# operationId: sql.projects.instances.verifyExternalSyncSettings
# --mysqlSyncConfig shape: {initialSyncFlags?: list}
export def "sql-v1beta4-projects-instances-verify-external-sync-settings verify" [
  project: string
  instance: string
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
  --mysql-sync-config: record # MySQL-specific external server sync settings. — shape: {initialSyncFlags?: list}
  --sync-mode: string@sync-mode-completer # External sync mode
  --verify-connection-only: oneof<nothing, bool> # Flag to enable verifying connection only
  --verify-replication-only: oneof<nothing, bool> # Optional. Flag to verify settings required by replication setup only
]: any -> record<errors: table<detail: string, kind: string, type: string>, kind: string, warnings: table<detail: string, kind: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}/verifyExternalSyncSettings") $qp)
  let req_body = {"mysqlSyncConfig": $mysql_sync_config, "syncMode": $sync_mode, "verifyConnectionOnly": $verify_connection_only, "verifyReplicationOnly": $verify_replication_only} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Generates a short-lived X509 certificate containing the provided public key and signed by a private key specific to the target instance. Users may use the certificate to authenticate as themselves when connecting to the database.
#
# POST /sql/v1beta4/projects/{project}/instances/{instance}:generateEphemeralCert
# operationId: sql.connect.generateEphemeral
export def "sql-v1beta4-projects-instances generate-ephemeral" [
  project: string
  instance: string
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
  --access-token-body: string # Optional. Access token to include in the signed certificate. (body field)
  --public-key: string # PEM encoded public key to include in the signed certificate.
  --read-time: string # Optional. Optional snapshot read timestamp to trade freshness for performance. (format: google-datetime)
  --valid-duration: string # Optional. If set, it will contain the cert valid duration. (format: google-duration)
]: any -> record<ephemeralCert: record<cert: string, certSerialNumber: string, commonName: string, createTime: string, expirationTime: string, instance: string, kind: string, selfLink: string, sha1Fingerprint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($instance | is-empty) { error make --unspanned { msg: "path parameter 'instance' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), instance: (encode-path-segment $instance)} | format pattern "/sql/v1beta4/projects/{project}/instances/{instance}:generateEphemeralCert") $qp)
  let req_body = {"access_token": $access_token_body, "public_key": $public_key, "readTime": $read_time, "validDuration": $valid_duration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists all instance operations that have been performed on the given Cloud SQL instance in the reverse chronological order of the start time.
#
# GET /sql/v1beta4/projects/{project}/operations
# operationId: sql.operations.list
export def "sql-v1beta4-projects-operations list" [
  project: string
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
  --instance: string # Cloud SQL instance ID. This does not include the project ID.
  --max-results: int # Maximum number of operations per response.
  --page-token: string # A previously-returned page token representing part of the larger set of results to view.
]: nothing -> record<items: table<backupContext: record, endTime: string, error: record, exportContext: record, importContext: record, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "instance" $instance "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project)} | format pattern "/sql/v1beta4/projects/{project}/operations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "instance": $instance, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Retrieves an instance operation that has been performed on an instance.
#
# GET /sql/v1beta4/projects/{project}/operations/{operation}
# operationId: sql.operations.get
export def "sql-v1beta4-projects-operations get" [
  project: string
  operation: string
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
]: nothing -> record<backupContext: record<backupId: string, kind: string>, endTime: string, error: record<errors: list<record>, kind: string>, exportContext: record<bakExportOptions: record<stripeCount: int, striped: bool>, csvExportOptions: record<escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, selectQuery: string>, databases: list<string>, fileType: string, kind: string, offload: bool, sqlExportOptions: record<mysqlExportOptions: record, schemaOnly: bool, tables: list>, uri: string>, importContext: record<bakImportOptions: record<encryptionOptions: record, striped: bool>, csvImportOptions: record<columns: list, escapeCharacter: string, fieldsTerminatedBy: string, linesTerminatedBy: string, quoteCharacter: string, table: string>, database: string, fileType: string, importUser: string, kind: string, uri: string>, insertTime: string, kind: string, name: string, operationType: string, selfLink: string, startTime: string, status: string, targetId: string, targetLink: string, targetProject: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($operation | is-empty) { error make --unspanned { msg: "path parameter 'operation' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project), operation: (encode-path-segment $operation)} | format pattern "/sql/v1beta4/projects/{project}/operations/{operation}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Lists all available machine types (tiers) for Cloud SQL, for example, `db-custom-1-3840`. For related information, see [Pricing](/sql/pricing).
#
# GET /sql/v1beta4/projects/{project}/tiers
# operationId: sql.tiers.list
export def "sql-v1beta4-projects-tiers list" [
  project: string
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
]: nothing -> record<items: table<DiskQuota: string, RAM: string, kind: string, region: list, tier: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project: (encode-path-segment $project)} | format pattern "/sql/v1beta4/projects/{project}/tiers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}
