# Auto-generated client for Application Migration Service v2020-02-26
# Source: https://api.apis.guru/v2/specs/amazonaws.com/mgn/2020-02-26/openapi.json
# Auth: --token flag or $env.APPLICATION_MIGRATION_SERVICE_TOKEN

const BASE_URL = "http://mgn.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o APPLICATION_MIGRATION_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["http://mgn.us-east-1.amazonaws.com" "http://mgn.us-east-2.amazonaws.com" "http://mgn.us-west-1.amazonaws.com" "http://mgn.us-west-2.amazonaws.com" "http://mgn.us-gov-west-1.amazonaws.com" "http://mgn.us-gov-east-1.amazonaws.com" "http://mgn.ca-central-1.amazonaws.com" "http://mgn.eu-north-1.amazonaws.com" "http://mgn.eu-west-1.amazonaws.com" "http://mgn.eu-west-2.amazonaws.com" "http://mgn.eu-west-3.amazonaws.com" "http://mgn.eu-central-1.amazonaws.com" "http://mgn.eu-south-1.amazonaws.com" "http://mgn.af-south-1.amazonaws.com" "http://mgn.ap-northeast-1.amazonaws.com" "http://mgn.ap-northeast-2.amazonaws.com" "http://mgn.ap-northeast-3.amazonaws.com" "http://mgn.ap-southeast-1.amazonaws.com" "http://mgn.ap-southeast-2.amazonaws.com" "http://mgn.ap-east-1.amazonaws.com" "http://mgn.ap-south-1.amazonaws.com" "http://mgn.sa-east-1.amazonaws.com" "http://mgn.me-south-1.amazonaws.com" "https://mgn.us-east-1.amazonaws.com" "https://mgn.us-east-2.amazonaws.com" "https://mgn.us-west-1.amazonaws.com" "https://mgn.us-west-2.amazonaws.com" "https://mgn.us-gov-west-1.amazonaws.com" "https://mgn.us-gov-east-1.amazonaws.com" "https://mgn.ca-central-1.amazonaws.com" "https://mgn.eu-north-1.amazonaws.com" "https://mgn.eu-west-1.amazonaws.com" "https://mgn.eu-west-2.amazonaws.com" "https://mgn.eu-west-3.amazonaws.com" "https://mgn.eu-central-1.amazonaws.com" "https://mgn.eu-south-1.amazonaws.com" "https://mgn.af-south-1.amazonaws.com" "https://mgn.ap-northeast-1.amazonaws.com" "https://mgn.ap-northeast-2.amazonaws.com" "https://mgn.ap-northeast-3.amazonaws.com" "https://mgn.ap-southeast-1.amazonaws.com" "https://mgn.ap-southeast-2.amazonaws.com" "https://mgn.ap-east-1.amazonaws.com" "https://mgn.ap-south-1.amazonaws.com" "https://mgn.sa-east-1.amazonaws.com" "https://mgn.me-south-1.amazonaws.com" "http://mgn.cn-north-1.amazonaws.com.cn" "http://mgn.cn-northwest-1.amazonaws.com.cn" "https://mgn.cn-north-1.amazonaws.com.cn" "https://mgn.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def boot-mode-completer [] { ["LEGACY_BIOS" "UEFI"] }
def launch-disposition-completer [] { ["STARTED" "STOPPED"] }
def target-instance-type-right-sizing-method-completer [] { ["BASIC" "NONE"] }
def data-plane-routing-completer [] { ["PRIVATE_IP" "PUBLIC_IP"] }
def default-large-staging-disk-type-completer [] { ["GP2" "GP3" "ST1"] }
def ebs-encryption-completer [] { ["CUSTOM" "DEFAULT"] }
def category-completer [] { ["BACKUP" "CONFIGURATION" "DISASTER_RECOVERY" "LICENSE_AND_SUBSCRIPTION" "NETWORKING" "OBSERVABILITY" "OPERATING_SYSTEM" "OTHER" "SECURITY" "VALIDATION"] }
def replication-type-completer [] { ["AGENT_BASED" "SNAPSHOT_SHIPPING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "archive-application archive" } } | get name | first)
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

# Archive application.
#
# POST /ArchiveApplication
# operationId: ArchiveApplication
export def "archive-application archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_id: string # Application ID.
]: any -> record<applicationAggregatedStatus: record<healthStatus: record, lastUpdateDateTime: record, progressStatus: record, totalSourceServers: record>, applicationID: record, arn: record, creationDateTime: record, description: record, isArchived: record, lastModifiedDateTime: record, name: record, tags: record, waveID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ArchiveApplication")
  let req_body = {"applicationID": $application_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Archive wave.
#
# POST /ArchiveWave
# operationId: ArchiveWave
export def "archive-wave archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  wave_id: string # Wave ID.
]: any -> record<arn: record, creationDateTime: record, description: record, isArchived: record, lastModifiedDateTime: record, name: record, tags: record, waveAggregatedStatus: record<healthStatus: record, lastUpdateDateTime: record, progressStatus: record, replicationStartedDateTime: record, totalApplications: record>, waveID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ArchiveWave")
  let req_body = {"waveID": $wave_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Associate applications to wave.
#
# POST /AssociateApplications
# operationId: AssociateApplications
export def "associate-applications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_i_ds: list<string> # Application IDs list.
  wave_id: string # Wave ID.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/AssociateApplications")
  let req_body = {"applicationIDs": $application_i_ds, "waveID": $wave_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Associate source servers to application.
#
# POST /AssociateSourceServers
# operationId: AssociateSourceServers
export def "associate-source-servers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_id: string # Application ID.
  source_server_i_ds: list<string> # Source server IDs list.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/AssociateSourceServers")
  let req_body = {"applicationID": $application_id, "sourceServerIDs": $source_server_i_ds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Allows the user to set the SourceServer.LifeCycle.state property for specific Source Server IDs to one of the following: READY_FOR_TEST or READY_FOR_CUTOVER. This command only works if the Source Server is already launchable (dataReplicationInfo.lagDuration is not null.)
#
# POST /ChangeServerLifeCycleState
# operationId: ChangeServerLifeCycleState
# --lifeCycle shape: {state?: any}
export def "change-server-life-cycle-state create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  life_cycle: record # The request to change the source server migration lifecycle state. — shape: {state?: any}
  source_server_id: string # The request to change the source server migration lifecycle state by source server ID.
]: any -> record<applicationID: record, arn: record, dataReplicationInfo: record<dataReplicationError: record<error: record, rawError: record>, dataReplicationInitiation: record<nextAttemptDateTime: record, startDateTime: record, steps: record>, dataReplicationState: record, etaDateTime: record, lagDuration: record, lastSnapshotDateTime: record, replicatedDisks: record>, fqdnForActionFramework: record, isArchived: record, launchedInstance: record<ec2InstanceID: record, firstBoot: record, jobID: record>, lifeCycle: record<addedToServiceDateTime: record, elapsedReplicationDuration: record, firstByteDateTime: record, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: record, lastTest: record<finalized: record, initiated: record, reverted: record>, state: record>, replicationType: record, sourceProperties: record<cpus: record, disks: record, identificationHints: record<awsInstanceID: record, fqdn: record, hostname: record, vmPath: record, vmWareUuid: record>, lastUpdatedDateTime: record, networkInterfaces: record, os: record<fullString: record>, ramBytes: record, recommendedInstanceType: record>, sourceServerID: record, tags: record, userProvidedID: record, vcenterClientID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ChangeServerLifeCycleState")
  let req_body = {"lifeCycle": $life_cycle, "sourceServerID": $source_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create application.
#
# POST /CreateApplication
# operationId: CreateApplication
export def "create-application create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Application description.
  name: string # Application name.
  --tags: record # Application tags.
]: any -> record<applicationAggregatedStatus: record<healthStatus: record, lastUpdateDateTime: record, progressStatus: record, totalSourceServers: record>, applicationID: record, arn: record, creationDateTime: record, description: record, isArchived: record, lastModifiedDateTime: record, name: record, tags: record, waveID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CreateApplication")
  let req_body = {"description": $description, "name": $name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new Launch Configuration Template.
#
# POST /CreateLaunchConfigurationTemplate
# operationId: CreateLaunchConfigurationTemplate
# --largeVolumeConf shape: {iops?: any, throughput?: any, volumeType?: any}
# --licensing shape: {osByol?: any}
# --postLaunchActions shape: {cloudWatchLogGroupName?: any, deployment?: any, s3LogBucket?: any, s3OutputKeyPrefix?: any, ssmDocuments?: any}
# --smallVolumeConf shape: {iops?: any, throughput?: any, volumeType?: any}
export def "create-launch-configuration-template create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --associate-public-ip-address: oneof<nothing, bool> # Associate public Ip address.
  --boot-mode: string@boot-mode-completer # Launch configuration template boot mode.
  --copy-private-ip: oneof<nothing, bool> # Copy private Ip.
  --copy-tags: oneof<nothing, bool> # Copy tags.
  --enable-map-auto-tagging: oneof<nothing, bool> # Enable map auto tagging.
  --large-volume-conf: record # Launch template disk configuration. — shape: {iops?: any, throughput?: any, volumeType?: any}
  --launch-disposition: string@launch-disposition-completer # Launch disposition.
  --licensing: record # Configure Licensing. — shape: {osByol?: any}
  --map-auto-tagging-mpe-id: string # Launch configuration template map auto tagging MPE ID.
  --post-launch-actions: record # Post Launch Actions to executed on the Test or Cutover instance. — shape: {cloudWatchLogGroupName?: any, deployment?: any, s3LogBucket?: any, s3OutputKeyPrefix?: any, ssmDocuments?: any}
  --small-volume-conf: record # Launch template disk configuration. — shape: {iops?: any, throughput?: any, volumeType?: any}
  --small-volume-max-size: int # Small volume maximum size.
  --tags: record # Request to associate tags during creation of a Launch Configuration Template.
  --target-instance-type-right-sizing-method: string@target-instance-type-right-sizing-method-completer # Target instance type right-sizing method.
]: any -> record<arn: record, associatePublicIpAddress: record, bootMode: record, copyPrivateIp: record, copyTags: record, ec2LaunchTemplateID: record, enableMapAutoTagging: record, largeVolumeConf: record<iops: record, throughput: record, volumeType: record>, launchConfigurationTemplateID: record, launchDisposition: record, licensing: record<osByol: record>, mapAutoTaggingMpeID: record, postLaunchActions: record<cloudWatchLogGroupName: record, deployment: record, s3LogBucket: record, s3OutputKeyPrefix: record, ssmDocuments: record>, smallVolumeConf: record<iops: record, throughput: record, volumeType: record>, smallVolumeMaxSize: record, tags: record, targetInstanceTypeRightSizingMethod: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CreateLaunchConfigurationTemplate")
  let req_body = {"associatePublicIpAddress": $associate_public_ip_address, "bootMode": $boot_mode, "copyPrivateIp": $copy_private_ip, "copyTags": $copy_tags, "enableMapAutoTagging": $enable_map_auto_tagging, "largeVolumeConf": $large_volume_conf, "launchDisposition": $launch_disposition, "licensing": $licensing, "mapAutoTaggingMpeID": $map_auto_tagging_mpe_id, "postLaunchActions": $post_launch_actions, "smallVolumeConf": $small_volume_conf, "smallVolumeMaxSize": $small_volume_max_size, "tags": $tags, "targetInstanceTypeRightSizingMethod": $target_instance_type_right_sizing_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new ReplicationConfigurationTemplate.
#
# POST /CreateReplicationConfigurationTemplate
# operationId: CreateReplicationConfigurationTemplate
export def "create-replication-configuration-template create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --associate-default-security-group: oneof<nothing, bool> # Request to associate the default Application Migration Service Security group with the Replication Settings template.
  bandwidth_throttling: int # Request to configure bandwidth throttling during Replication Settings template creation.
  --create-public-ip: oneof<nothing, bool> # Request to create Public IP during Replication Settings template creation.
  data_plane_routing: string@data-plane-routing-completer # Request to configure data plane routing during Replication Settings template creation.
  default_large_staging_disk_type: string@default-large-staging-disk-type-completer # Request to configure the default large staging disk EBS volume type during Replication Settings template creation.
  ebs_encryption: string@ebs-encryption-completer # Request to configure EBS encryption during Replication Settings template creation.
  --ebs-encryption-key-arn: string # Request to configure an EBS encryption key during Replication Settings template creation.
  replication_server_instance_type: string # Request to configure the Replication Server instance type during Replication Settings template creation.
  replication_servers_security_groups_i_ds: list<string> # Request to configure the Replication Server Security group ID during Replication Settings template creation.
  staging_area_subnet_id: string # Request to configure the Staging Area subnet ID during Replication Settings template creation.
  staging_area_tags: record # Request to configure Staging Area tags during Replication Settings template creation.
  --tags: record # Request to configure tags during Replication Settings template creation.
  --use-dedicated-replication-server: oneof<nothing, bool> # Request to use Dedicated Replication Servers during Replication Settings template creation.
]: any -> record<arn: record, associateDefaultSecurityGroup: record, bandwidthThrottling: record, createPublicIP: record, dataPlaneRouting: record, defaultLargeStagingDiskType: record, ebsEncryption: record, ebsEncryptionKeyArn: record, replicationConfigurationTemplateID: record, replicationServerInstanceType: record, replicationServersSecurityGroupsIDs: record, stagingAreaSubnetId: record, stagingAreaTags: record, tags: record, useDedicatedReplicationServer: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CreateReplicationConfigurationTemplate")
  let req_body = {"associateDefaultSecurityGroup": $associate_default_security_group, "bandwidthThrottling": $bandwidth_throttling, "createPublicIP": $create_public_ip, "dataPlaneRouting": $data_plane_routing, "defaultLargeStagingDiskType": $default_large_staging_disk_type, "ebsEncryption": $ebs_encryption, "ebsEncryptionKeyArn": $ebs_encryption_key_arn, "replicationServerInstanceType": $replication_server_instance_type, "replicationServersSecurityGroupsIDs": $replication_servers_security_groups_i_ds, "stagingAreaSubnetId": $staging_area_subnet_id, "stagingAreaTags": $staging_area_tags, "tags": $tags, "useDedicatedReplicationServer": $use_dedicated_replication_server} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create wave.
#
# POST /CreateWave
# operationId: CreateWave
export def "create-wave create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Wave description.
  name: string # Wave name.
  --tags: record # Wave tags.
]: any -> record<arn: record, creationDateTime: record, description: record, isArchived: record, lastModifiedDateTime: record, name: record, tags: record, waveAggregatedStatus: record<healthStatus: record, lastUpdateDateTime: record, progressStatus: record, replicationStartedDateTime: record, totalApplications: record>, waveID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CreateWave")
  let req_body = {"description": $description, "name": $name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete application.
#
# POST /DeleteApplication
# operationId: DeleteApplication
export def "delete-application delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_id: string # Application ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/DeleteApplication")
  let req_body = {"applicationID": $application_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a single Job by ID.
#
# POST /DeleteJob
# operationId: DeleteJob
export def "delete-job delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  job_id: string # Request to delete Job from service by Job ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/DeleteJob")
  let req_body = {"jobID": $job_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a single Launch Configuration Template by ID.
#
# POST /DeleteLaunchConfigurationTemplate
# operationId: DeleteLaunchConfigurationTemplate
export def "delete-launch-configuration-template delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  launch_configuration_template_id: string # ID of resource to be deleted.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/DeleteLaunchConfigurationTemplate")
  let req_body = {"launchConfigurationTemplateID": $launch_configuration_template_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a single Replication Configuration Template by ID
#
# POST /DeleteReplicationConfigurationTemplate
# operationId: DeleteReplicationConfigurationTemplate
export def "delete-replication-configuration-template delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  replication_configuration_template_id: string # Request to delete Replication Configuration Template from service by Replication Configuration Template ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/DeleteReplicationConfigurationTemplate")
  let req_body = {"replicationConfigurationTemplateID": $replication_configuration_template_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a single source server by ID.
#
# POST /DeleteSourceServer
# operationId: DeleteSourceServer
export def "delete-source-server delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Request to delete Source Server from service by Server ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/DeleteSourceServer")
  let req_body = {"sourceServerID": $source_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a given vCenter client by ID.
#
# POST /DeleteVcenterClient
# operationId: DeleteVcenterClient
export def "delete-vcenter-client delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  vcenter_client_id: string # ID of resource to be deleted.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/DeleteVcenterClient")
  let req_body = {"vcenterClientID": $vcenter_client_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete wave.
#
# POST /DeleteWave
# operationId: DeleteWave
export def "delete-wave delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  wave_id: string # Wave ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/DeleteWave")
  let req_body = {"waveID": $wave_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves detailed job log items with paging.
#
# POST /DescribeJobLogItems
# operationId: DescribeJobLogItems
export def "describe-job-log-items get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  job_id: string # Request to describe Job log job ID.
  --max-results: int # Request to describe Job log item maximum results.
  --next-token: string # Request to describe Job log next token.
]: any -> record<items: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/DescribeJobLogItems" $qp)
  let req_body = {"jobID": $job_id, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of Jobs. Use the JobsID and fromDate and toData filters to limit which jobs are returned. The response is sorted by creationDataTime - latest date first. Jobs are normally created by the StartTest, StartCutover, and TerminateTargetInstances APIs. Jobs are also created by DiagnosticLaunch and TerminateDiagnosticInstances, which are APIs available only to *Support* and only used in response to relevant support tickets.
#
# POST /DescribeJobs
# operationId: DescribeJobs
# --filters shape: {fromDate?: any, jobIDs?: any, toDate?: any}
export def "describe-jobs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filters: record # Request to describe Job log filters. — shape: {fromDate?: any, jobIDs?: any, toDate?: any}
  --max-results: int # Request to describe job log items by max results.
  --next-token: string # Request to describe job log items by next token.
]: any -> record<items: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/DescribeJobs" $qp)
  let req_body = {"filters": $filters, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all Launch Configuration Templates, filtered by Launch Configuration Template IDs
#
# POST /DescribeLaunchConfigurationTemplates
# operationId: DescribeLaunchConfigurationTemplates
export def "describe-launch-configuration-templates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --launch-configuration-template-i-ds: list<string> # Request to filter Launch Configuration Templates list by Launch Configuration Template ID.
  --max-results: int # Maximum results to be returned in DescribeLaunchConfigurationTemplates.
  --next-token: string # Next pagination token returned from DescribeLaunchConfigurationTemplates.
]: any -> record<items: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/DescribeLaunchConfigurationTemplates" $qp)
  let req_body = {"launchConfigurationTemplateIDs": $launch_configuration_template_i_ds, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all ReplicationConfigurationTemplates, filtered by Source Server IDs.
#
# POST /DescribeReplicationConfigurationTemplates
# operationId: DescribeReplicationConfigurationTemplates
export def "describe-replication-configuration-templates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --max-results: int # Request to describe Replication Configuration template by max results.
  --next-token: string # Request to describe Replication Configuration template by next token.
  --replication-configuration-template-i-ds: list<string> # Request to describe Replication Configuration template by template IDs.
]: any -> record<items: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/DescribeReplicationConfigurationTemplates" $qp)
  let req_body = {"maxResults": $max_results, "nextToken": $next_token, "replicationConfigurationTemplateIDs": $replication_configuration_template_i_ds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves all SourceServers or multiple SourceServers by ID.
#
# POST /DescribeSourceServers
# operationId: DescribeSourceServers
# --filters shape: {applicationIDs?: any, isArchived?: any, lifeCycleStates?: any, replicationTypes?: any, sourceServerIDs?: any}
export def "describe-source-servers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filters: record # Request to filter Source Servers list. — shape: {applicationIDs?: any, isArchived?: any, lifeCycleStates?: any, replicationTypes?: any, sourceServerIDs?: any}
  --max-results: int # Request to filter Source Servers list by maximum results.
  --next-token: string # Request to filter Source Servers list by next token.
]: any -> record<items: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/DescribeSourceServers" $qp)
  let req_body = {"filters": $filters, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of the installed vCenter clients.
#
# GET /DescribeVcenterClients
# operationId: DescribeVcenterClients
export def "describe-vcenter-clients get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # Maximum results to be returned in DescribeVcenterClients.
  --next-token: string # Next pagination token to be provided for DescribeVcenterClients.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<items: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/DescribeVcenterClients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disassociate applications from wave.
#
# POST /DisassociateApplications
# operationId: DisassociateApplications
export def "disassociate-applications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_i_ds: list<string> # Application IDs list.
  wave_id: string # Wave ID.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/DisassociateApplications")
  let req_body = {"applicationIDs": $application_i_ds, "waveID": $wave_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disassociate source servers from application.
#
# POST /DisassociateSourceServers
# operationId: DisassociateSourceServers
export def "disassociate-source-servers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_id: string # Application ID.
  source_server_i_ds: list<string> # Source server IDs list.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/DisassociateSourceServers")
  let req_body = {"applicationID": $application_id, "sourceServerIDs": $source_server_i_ds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disconnects specific Source Servers from Application Migration Service. Data replication is stopped immediately. All AWS resources created by Application Migration Service for enabling the replication of these source servers will be terminated / deleted within 90 minutes. Launched Test or Cutover instances will NOT be terminated. If the agent on the source server has not been prevented from communicating with the Application Migration Service service, then it will receive a command to uninstall itself (within approximately 10 minutes). The following properties of the SourceServer will be changed immediately: dataReplicationInfo.dataReplicationState will be set to DISCONNECTED; The totalStorageBytes property for each of dataReplicationInfo.replicatedDisks will be set to zero; dataReplicationInfo.lagDuration and dataReplicationInfo.lagDuration will be nullified.
#
# POST /DisconnectFromService
# operationId: DisconnectFromService
export def "disconnect-from-service create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Request to disconnect Source Server from service by Server ID.
]: any -> record<applicationID: record, arn: record, dataReplicationInfo: record<dataReplicationError: record<error: record, rawError: record>, dataReplicationInitiation: record<nextAttemptDateTime: record, startDateTime: record, steps: record>, dataReplicationState: record, etaDateTime: record, lagDuration: record, lastSnapshotDateTime: record, replicatedDisks: record>, fqdnForActionFramework: record, isArchived: record, launchedInstance: record<ec2InstanceID: record, firstBoot: record, jobID: record>, lifeCycle: record<addedToServiceDateTime: record, elapsedReplicationDuration: record, firstByteDateTime: record, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: record, lastTest: record<finalized: record, initiated: record, reverted: record>, state: record>, replicationType: record, sourceProperties: record<cpus: record, disks: record, identificationHints: record<awsInstanceID: record, fqdn: record, hostname: record, vmPath: record, vmWareUuid: record>, lastUpdatedDateTime: record, networkInterfaces: record, os: record<fullString: record>, ramBytes: record, recommendedInstanceType: record>, sourceServerID: record, tags: record, userProvidedID: record, vcenterClientID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/DisconnectFromService")
  let req_body = {"sourceServerID": $source_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Finalizes the cutover immediately for specific Source Servers. All AWS resources created by Application Migration Service for enabling the replication of these source servers will be terminated / deleted within 90 minutes. Launched Test or Cutover instances will NOT be terminated. The AWS Replication Agent will receive a command to uninstall itself (within 10 minutes). The following properties of the SourceServer will be changed immediately: dataReplicationInfo.dataReplicationState will be changed to DISCONNECTED; The SourceServer.lifeCycle.state will be changed to CUTOVER; The totalStorageBytes property fo each of dataReplicationInfo.replicatedDisks will be set to zero; dataReplicationInfo.lagDuration and dataReplicationInfo.lagDuration will be nullified.
#
# POST /FinalizeCutover
# operationId: FinalizeCutover
export def "finalize-cutover finalize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Request to finalize Cutover by Source Server ID.
]: any -> record<applicationID: record, arn: record, dataReplicationInfo: record<dataReplicationError: record<error: record, rawError: record>, dataReplicationInitiation: record<nextAttemptDateTime: record, startDateTime: record, steps: record>, dataReplicationState: record, etaDateTime: record, lagDuration: record, lastSnapshotDateTime: record, replicatedDisks: record>, fqdnForActionFramework: record, isArchived: record, launchedInstance: record<ec2InstanceID: record, firstBoot: record, jobID: record>, lifeCycle: record<addedToServiceDateTime: record, elapsedReplicationDuration: record, firstByteDateTime: record, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: record, lastTest: record<finalized: record, initiated: record, reverted: record>, state: record>, replicationType: record, sourceProperties: record<cpus: record, disks: record, identificationHints: record<awsInstanceID: record, fqdn: record, hostname: record, vmPath: record, vmWareUuid: record>, lastUpdatedDateTime: record, networkInterfaces: record, os: record<fullString: record>, ramBytes: record, recommendedInstanceType: record>, sourceServerID: record, tags: record, userProvidedID: record, vcenterClientID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/FinalizeCutover")
  let req_body = {"sourceServerID": $source_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all LaunchConfigurations available, filtered by Source Server IDs.
#
# POST /GetLaunchConfiguration
# operationId: GetLaunchConfiguration
export def "get-launch-configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Request to get Launch Configuration information by Source Server ID.
]: any -> record<bootMode: record, copyPrivateIp: record, copyTags: record, ec2LaunchTemplateID: record, enableMapAutoTagging: record, launchDisposition: record, licensing: record<osByol: record>, mapAutoTaggingMpeID: record, name: record, postLaunchActions: record<cloudWatchLogGroupName: record, deployment: record, s3LogBucket: record, s3OutputKeyPrefix: record, ssmDocuments: record>, sourceServerID: record, targetInstanceTypeRightSizingMethod: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GetLaunchConfiguration")
  let req_body = {"sourceServerID": $source_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all ReplicationConfigurations, filtered by Source Server ID.
#
# POST /GetReplicationConfiguration
# operationId: GetReplicationConfiguration
export def "get-replication-configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Request to get Replication Configuration by Source Server ID.
]: any -> record<associateDefaultSecurityGroup: record, bandwidthThrottling: record, createPublicIP: record, dataPlaneRouting: record, defaultLargeStagingDiskType: record, ebsEncryption: record, ebsEncryptionKeyArn: record, name: record, replicatedDisks: record, replicationServerInstanceType: record, replicationServersSecurityGroupsIDs: record, sourceServerID: record, stagingAreaSubnetId: record, stagingAreaTags: record, useDedicatedReplicationServer: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GetReplicationConfiguration")
  let req_body = {"sourceServerID": $source_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Initialize Application Migration Service.
#
# POST /InitializeService
# operationId: InitializeService
export def "initialize-service create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
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
  let full_url = (build-url $base "/InitializeService")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all applications or multiple applications by ID.
#
# POST /ListApplications
# operationId: ListApplications
# --filters shape: {applicationIDs?: any, isArchived?: any, waveIDs?: any}
export def "list-applications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filters: record # Applications list filters. — shape: {applicationIDs?: any, isArchived?: any, waveIDs?: any}
  --max-results: int # Maximum results to return when listing applications.
  --next-token: string # Request next token.
]: any -> record<items: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ListApplications" $qp)
  let req_body = {"filters": $filters, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List export errors.
#
# POST /ListExportErrors
# operationId: ListExportErrors
export def "list-export-errors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  export_id: string # List export errors request export id.
  --max-results: int # List export errors request max results.
  --next-token: string # List export errors request next token.
]: any -> record<items: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ListExportErrors" $qp)
  let req_body = {"exportID": $export_id, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List exports.
#
# POST /ListExports
# operationId: ListExports
# --filters shape: {exportIDs?: any}
export def "list-exports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filters: record # List exports request filters. — shape: {exportIDs?: any}
  --max-results: int # List export request max results.
  --next-token: string # List export request next token.
]: any -> record<items: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ListExports" $qp)
  let req_body = {"filters": $filters, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List import errors.
#
# POST /ListImportErrors
# operationId: ListImportErrors
export def "list-import-errors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  import_id: string # List import errors request import id.
  --max-results: int # List import errors request max results.
  --next-token: string # List import errors request next token.
]: any -> record<items: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ListImportErrors" $qp)
  let req_body = {"importID": $import_id, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List imports.
#
# POST /ListImports
# operationId: ListImports
# --filters shape: {importIDs?: any}
export def "list-imports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filters: record # List imports request filters. — shape: {importIDs?: any}
  --max-results: int # List imports request max results.
  --next-token: string # List imports request next token.
]: any -> record<items: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ListImports" $qp)
  let req_body = {"filters": $filters, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List source server post migration custom actions.
#
# POST /ListSourceServerActions
# operationId: ListSourceServerActions
# --filters shape: {actionIDs?: any}
export def "list-source-server-actions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filters: record # Source server post migration custom action filters. — shape: {actionIDs?: any}
  --max-results: int # Maximum amount of items to return when listing source server post migration custom actions.
  --next-token: string # Next token to use when listing source server post migration custom actions.
  source_server_id: string # Source server ID.
]: any -> record<items: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ListSourceServerActions" $qp)
  let req_body = {"filters": $filters, "maxResults": $max_results, "nextToken": $next_token, "sourceServerID": $source_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all tags for your Application Migration Service resources.
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds or overwrites only the specified tags for the specified Application Migration Service resource or resources. When you specify an existing tag key, the value is overwritten with the new value. Each resource can have a maximum of 50 tags. Each tag consists of a key and optional value.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: record # Tag resource by Tags.
]: any -> any {
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List template post migration custom actions.
#
# POST /ListTemplateActions
# operationId: ListTemplateActions
# --filters shape: {actionIDs?: any}
export def "list-template-actions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filters: record # Template post migration custom action filters. — shape: {actionIDs?: any}
  launch_configuration_template_id: string # Launch configuration template ID.
  --max-results: int # Maximum amount of items to return when listing template post migration custom actions.
  --next-token: string # Next token to use when listing template post migration custom actions.
]: any -> record<items: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ListTemplateActions" $qp)
  let req_body = {"filters": $filters, "launchConfigurationTemplateID": $launch_configuration_template_id, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves all waves or multiple waves by ID.
#
# POST /ListWaves
# operationId: ListWaves
# --filters shape: {isArchived?: any, waveIDs?: any}
export def "list-waves list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filters: record # Waves list filters. — shape: {isArchived?: any, waveIDs?: any}
  --max-results: int # Maximum results to return when listing waves.
  --next-token: string # Request next token.
]: any -> record<items: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ListWaves" $qp)
  let req_body = {"filters": $filters, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Archives specific Source Servers by setting the SourceServer.isArchived property to true for specified SourceServers by ID. This command only works for SourceServers with a lifecycle. state which equals DISCONNECTED or CUTOVER.
#
# POST /MarkAsArchived
# operationId: MarkAsArchived
export def "mark-as-archived create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Mark as archived by Source Server ID.
]: any -> record<applicationID: record, arn: record, dataReplicationInfo: record<dataReplicationError: record<error: record, rawError: record>, dataReplicationInitiation: record<nextAttemptDateTime: record, startDateTime: record, steps: record>, dataReplicationState: record, etaDateTime: record, lagDuration: record, lastSnapshotDateTime: record, replicatedDisks: record>, fqdnForActionFramework: record, isArchived: record, launchedInstance: record<ec2InstanceID: record, firstBoot: record, jobID: record>, lifeCycle: record<addedToServiceDateTime: record, elapsedReplicationDuration: record, firstByteDateTime: record, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: record, lastTest: record<finalized: record, initiated: record, reverted: record>, state: record>, replicationType: record, sourceProperties: record<cpus: record, disks: record, identificationHints: record<awsInstanceID: record, fqdn: record, hostname: record, vmPath: record, vmWareUuid: record>, lastUpdatedDateTime: record, networkInterfaces: record, os: record<fullString: record>, ramBytes: record, recommendedInstanceType: record>, sourceServerID: record, tags: record, userProvidedID: record, vcenterClientID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/MarkAsArchived")
  let req_body = {"sourceServerID": $source_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Put source server post migration custom action.
#
# POST /PutSourceServerAction
# operationId: PutSourceServerAction
export def "put-source-server-action update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  action_id: string # Source server post migration custom action ID.
  action_name: string # Source server post migration custom action name.
  --active: oneof<nothing, bool> # Source server post migration custom action active status.
  --category: string@category-completer # Source server post migration custom action category.
  --description: string # Source server post migration custom action description.
  document_identifier: string # Source server post migration custom action document identifier.
  --document-version: string # Source server post migration custom action document version.
  --external-parameters: record # Source server post migration custom action external parameters.
  --must-succeed-for-cutover: oneof<nothing, bool> # Source server post migration custom action must succeed for cutover.
  order: int # Source server post migration custom action order.
  --parameters: record # Source server post migration custom action parameters.
  source_server_id: string # Source server ID.
  --timeout-seconds: int # Source server post migration custom action timeout in seconds.
]: any -> record<actionID: record, actionName: record, active: record, category: record, description: record, documentIdentifier: record, documentVersion: record, externalParameters: record, mustSucceedForCutover: record, order: record, parameters: record, timeoutSeconds: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/PutSourceServerAction")
  let req_body = {"actionID": $action_id, "actionName": $action_name, "active": $active, "category": $category, "description": $description, "documentIdentifier": $document_identifier, "documentVersion": $document_version, "externalParameters": $external_parameters, "mustSucceedForCutover": $must_succeed_for_cutover, "order": $order, "parameters": $parameters, "sourceServerID": $source_server_id, "timeoutSeconds": $timeout_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Put template post migration custom action.
#
# POST /PutTemplateAction
# operationId: PutTemplateAction
export def "put-template-action update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  action_id: string # Template post migration custom action ID.
  action_name: string # Template post migration custom action name.
  --active: oneof<nothing, bool> # Template post migration custom action active status.
  --category: string@category-completer # Template post migration custom action category.
  --description: string # Template post migration custom action description.
  document_identifier: string # Template post migration custom action document identifier.
  --document-version: string # Template post migration custom action document version.
  --external-parameters: record # Template post migration custom action external parameters.
  launch_configuration_template_id: string # Launch configuration template ID.
  --must-succeed-for-cutover: oneof<nothing, bool> # Template post migration custom action must succeed for cutover.
  --operating-system: string # Operating system eligible for this template post migration custom action.
  order: int # Template post migration custom action order.
  --parameters: record # Template post migration custom action parameters.
  --timeout-seconds: int # Template post migration custom action timeout in seconds.
]: any -> record<actionID: record, actionName: record, active: record, category: record, description: record, documentIdentifier: record, documentVersion: record, externalParameters: record, mustSucceedForCutover: record, operatingSystem: record, order: record, parameters: record, timeoutSeconds: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/PutTemplateAction")
  let req_body = {"actionID": $action_id, "actionName": $action_name, "active": $active, "category": $category, "description": $description, "documentIdentifier": $document_identifier, "documentVersion": $document_version, "externalParameters": $external_parameters, "launchConfigurationTemplateID": $launch_configuration_template_id, "mustSucceedForCutover": $must_succeed_for_cutover, "operatingSystem": $operating_system, "order": $order, "parameters": $parameters, "timeoutSeconds": $timeout_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove source server post migration custom action.
#
# POST /RemoveSourceServerAction
# operationId: RemoveSourceServerAction
export def "remove-source-server-action delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  action_id: string # Source server post migration custom action ID to remove.
  source_server_id: string # Source server ID of the post migration custom action to remove.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/RemoveSourceServerAction")
  let req_body = {"actionID": $action_id, "sourceServerID": $source_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove template post migration custom action.
#
# POST /RemoveTemplateAction
# operationId: RemoveTemplateAction
export def "remove-template-action delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  action_id: string # Template post migration custom action ID to remove.
  launch_configuration_template_id: string # Launch configuration template ID of the post migration custom action to remove.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/RemoveTemplateAction")
  let req_body = {"actionID": $action_id, "launchConfigurationTemplateID": $launch_configuration_template_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Causes the data replication initiation sequence to begin immediately upon next Handshake for specified SourceServer IDs, regardless of when the previous initiation started. This command will not work if the SourceServer is not stalled or is in a DISCONNECTED or STOPPED state.
#
# POST /RetryDataReplication
# operationId: RetryDataReplication
export def "retry-data-replication create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Retry data replication for Source Server ID.
]: any -> record<applicationID: record, arn: record, dataReplicationInfo: record<dataReplicationError: record<error: record, rawError: record>, dataReplicationInitiation: record<nextAttemptDateTime: record, startDateTime: record, steps: record>, dataReplicationState: record, etaDateTime: record, lagDuration: record, lastSnapshotDateTime: record, replicatedDisks: record>, fqdnForActionFramework: record, isArchived: record, launchedInstance: record<ec2InstanceID: record, firstBoot: record, jobID: record>, lifeCycle: record<addedToServiceDateTime: record, elapsedReplicationDuration: record, firstByteDateTime: record, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: record, lastTest: record<finalized: record, initiated: record, reverted: record>, state: record>, replicationType: record, sourceProperties: record<cpus: record, disks: record, identificationHints: record<awsInstanceID: record, fqdn: record, hostname: record, vmPath: record, vmWareUuid: record>, lastUpdatedDateTime: record, networkInterfaces: record, os: record<fullString: record>, ramBytes: record, recommendedInstanceType: record>, sourceServerID: record, tags: record, userProvidedID: record, vcenterClientID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/RetryDataReplication")
  let req_body = {"sourceServerID": $source_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Launches a Cutover Instance for specific Source Servers. This command starts a LAUNCH job whose initiatedBy property is StartCutover and changes the SourceServer.lifeCycle.state property to CUTTING_OVER.
#
# POST /StartCutover
# operationId: StartCutover
export def "start-cutover start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_i_ds: list<string> # Start Cutover by Source Server IDs.
  --tags: record # Start Cutover by Tags.
]: any -> record<job: record<arn: record, creationDateTime: record, endDateTime: record, initiatedBy: record, jobID: record, participatingServers: record, status: record, tags: record, type: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/StartCutover")
  let req_body = {"sourceServerIDs": $source_server_i_ds, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Start export.
#
# POST /StartExport
# operationId: StartExport
export def "start-export start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  s3_bucket: string # Start export request s3 bucket.
  --s3-bucket-owner: string # Start export request s3 bucket owner.
  s3_key: string # Start export request s3key.
]: any -> record<exportTask: record<creationDateTime: record, endDateTime: record, exportID: record, progressPercentage: record, s3Bucket: record, s3BucketOwner: record, s3Key: record, status: record, summary: record<applicationsCount: record, serversCount: record, wavesCount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/StartExport")
  let req_body = {"s3Bucket": $s3_bucket, "s3BucketOwner": $s3_bucket_owner, "s3Key": $s3_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Start import.
#
# POST /StartImport
# operationId: StartImport
# --s3BucketSource shape: {s3Bucket?: any, s3BucketOwner?: any, s3Key?: any}
export def "start-import start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Start import request client token.
  s3_bucket_source: record # S3 bucket source. — shape: {s3Bucket?: any, s3BucketOwner?: any, s3Key?: any}
]: any -> record<importTask: record<creationDateTime: record, endDateTime: record, importID: record, progressPercentage: record, s3BucketSource: record<s3Bucket: record, s3BucketOwner: record, s3Key: record>, status: record, summary: record<applications: record, servers: record, waves: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/StartImport")
  let req_body = {"clientToken": $client_token, "s3BucketSource": $s3_bucket_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts replication for SNAPSHOT_SHIPPING agents.
#
# POST /StartReplication
# operationId: StartReplication
export def "start-replication start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # ID of source server on which to start replication.
]: any -> record<applicationID: record, arn: record, dataReplicationInfo: record<dataReplicationError: record<error: record, rawError: record>, dataReplicationInitiation: record<nextAttemptDateTime: record, startDateTime: record, steps: record>, dataReplicationState: record, etaDateTime: record, lagDuration: record, lastSnapshotDateTime: record, replicatedDisks: record>, fqdnForActionFramework: record, isArchived: record, launchedInstance: record<ec2InstanceID: record, firstBoot: record, jobID: record>, lifeCycle: record<addedToServiceDateTime: record, elapsedReplicationDuration: record, firstByteDateTime: record, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: record, lastTest: record<finalized: record, initiated: record, reverted: record>, state: record>, replicationType: record, sourceProperties: record<cpus: record, disks: record, identificationHints: record<awsInstanceID: record, fqdn: record, hostname: record, vmPath: record, vmWareUuid: record>, lastUpdatedDateTime: record, networkInterfaces: record, os: record<fullString: record>, ramBytes: record, recommendedInstanceType: record>, sourceServerID: record, tags: record, userProvidedID: record, vcenterClientID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/StartReplication")
  let req_body = {"sourceServerID": $source_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Launches a Test Instance for specific Source Servers. This command starts a LAUNCH job whose initiatedBy property is StartTest and changes the SourceServer.lifeCycle.state property to TESTING.
#
# POST /StartTest
# operationId: StartTest
export def "start-test start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_i_ds: list<string> # Start Test for Source Server IDs.
  --tags: record # Start Test by Tags.
]: any -> record<job: record<arn: record, creationDateTime: record, endDateTime: record, initiatedBy: record, jobID: record, participatingServers: record, status: record, tags: record, type: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/StartTest")
  let req_body = {"sourceServerIDs": $source_server_i_ds, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a job that terminates specific launched EC2 Test and Cutover instances. This command will not work for any Source Server with a lifecycle.state of TESTING, CUTTING_OVER, or CUTOVER.
#
# POST /TerminateTargetInstances
# operationId: TerminateTargetInstances
export def "terminate-target-instances create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_i_ds: list<string> # Terminate Target instance by Source Server IDs.
  --tags: record # Terminate Target instance by Tags.
]: any -> record<job: record<arn: record, creationDateTime: record, endDateTime: record, initiatedBy: record, jobID: record, participatingServers: record, status: record, tags: record, type: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/TerminateTargetInstances")
  let req_body = {"sourceServerIDs": $source_server_i_ds, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Unarchive application.
#
# POST /UnarchiveApplication
# operationId: UnarchiveApplication
export def "unarchive-application unarchive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_id: string # Application ID.
]: any -> record<applicationAggregatedStatus: record<healthStatus: record, lastUpdateDateTime: record, progressStatus: record, totalSourceServers: record>, applicationID: record, arn: record, creationDateTime: record, description: record, isArchived: record, lastModifiedDateTime: record, name: record, tags: record, waveID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/UnarchiveApplication")
  let req_body = {"applicationID": $application_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Unarchive wave.
#
# POST /UnarchiveWave
# operationId: UnarchiveWave
export def "unarchive-wave unarchive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  wave_id: string # Wave ID.
]: any -> record<arn: record, creationDateTime: record, description: record, isArchived: record, lastModifiedDateTime: record, name: record, tags: record, waveAggregatedStatus: record<healthStatus: record, lastUpdateDateTime: record, progressStatus: record, replicationStartedDateTime: record, totalApplications: record>, waveID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/UnarchiveWave")
  let req_body = {"waveID": $wave_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the specified set of tags from the specified set of Application Migration Service resources.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # Untag resource by Keys.
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
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}#tagKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update application.
#
# POST /UpdateApplication
# operationId: UpdateApplication
export def "update-application update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_id: string # Application ID.
  --description: string # Application description.
  --name: string # Application name.
]: any -> record<applicationAggregatedStatus: record<healthStatus: record, lastUpdateDateTime: record, progressStatus: record, totalSourceServers: record>, applicationID: record, arn: record, creationDateTime: record, description: record, isArchived: record, lastModifiedDateTime: record, name: record, tags: record, waveID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/UpdateApplication")
  let req_body = {"applicationID": $application_id, "description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates multiple LaunchConfigurations by Source Server ID.
#
# POST /UpdateLaunchConfiguration
# operationId: UpdateLaunchConfiguration
# --licensing shape: {osByol?: any}
# --postLaunchActions shape: {cloudWatchLogGroupName?: any, deployment?: any, s3LogBucket?: any, s3OutputKeyPrefix?: any, ssmDocuments?: any}
export def "update-launch-configuration update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --boot-mode: string@boot-mode-completer # Update Launch configuration boot mode request.
  --copy-private-ip: oneof<nothing, bool> # Update Launch configuration copy Private IP request.
  --copy-tags: oneof<nothing, bool> # Update Launch configuration copy Tags request.
  --enable-map-auto-tagging: oneof<nothing, bool> # Enable map auto tagging.
  --launch-disposition: string@launch-disposition-completer # Update Launch configuration launch disposition request.
  --licensing: record # Configure Licensing. — shape: {osByol?: any}
  --map-auto-tagging-mpe-id: string # Launch configuration map auto tagging MPE ID.
  --name: string # Update Launch configuration name request.
  --post-launch-actions: record # Post Launch Actions to executed on the Test or Cutover instance. — shape: {cloudWatchLogGroupName?: any, deployment?: any, s3LogBucket?: any, s3OutputKeyPrefix?: any, ssmDocuments?: any}
  source_server_id: string # Update Launch configuration by Source Server ID request.
  --target-instance-type-right-sizing-method: string@target-instance-type-right-sizing-method-completer # Update Launch configuration Target instance right sizing request.
]: any -> record<bootMode: record, copyPrivateIp: record, copyTags: record, ec2LaunchTemplateID: record, enableMapAutoTagging: record, launchDisposition: record, licensing: record<osByol: record>, mapAutoTaggingMpeID: record, name: record, postLaunchActions: record<cloudWatchLogGroupName: record, deployment: record, s3LogBucket: record, s3OutputKeyPrefix: record, ssmDocuments: record>, sourceServerID: record, targetInstanceTypeRightSizingMethod: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/UpdateLaunchConfiguration")
  let req_body = {"bootMode": $boot_mode, "copyPrivateIp": $copy_private_ip, "copyTags": $copy_tags, "enableMapAutoTagging": $enable_map_auto_tagging, "launchDisposition": $launch_disposition, "licensing": $licensing, "mapAutoTaggingMpeID": $map_auto_tagging_mpe_id, "name": $name, "postLaunchActions": $post_launch_actions, "sourceServerID": $source_server_id, "targetInstanceTypeRightSizingMethod": $target_instance_type_right_sizing_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates an existing Launch Configuration Template by ID.
#
# POST /UpdateLaunchConfigurationTemplate
# operationId: UpdateLaunchConfigurationTemplate
# --largeVolumeConf shape: {iops?: any, throughput?: any, volumeType?: any}
# --licensing shape: {osByol?: any}
# --postLaunchActions shape: {cloudWatchLogGroupName?: any, deployment?: any, s3LogBucket?: any, s3OutputKeyPrefix?: any, ssmDocuments?: any}
# --smallVolumeConf shape: {iops?: any, throughput?: any, volumeType?: any}
export def "update-launch-configuration-template update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --associate-public-ip-address: oneof<nothing, bool> # Associate public Ip address.
  --boot-mode: string@boot-mode-completer # Launch configuration template boot mode.
  --copy-private-ip: oneof<nothing, bool> # Copy private Ip.
  --copy-tags: oneof<nothing, bool> # Copy tags.
  --enable-map-auto-tagging: oneof<nothing, bool> # Enable map auto tagging.
  --large-volume-conf: record # Launch template disk configuration. — shape: {iops?: any, throughput?: any, volumeType?: any}
  launch_configuration_template_id: string # Launch Configuration Template ID.
  --launch-disposition: string@launch-disposition-completer # Launch disposition.
  --licensing: record # Configure Licensing. — shape: {osByol?: any}
  --map-auto-tagging-mpe-id: string # Launch configuration template map auto tagging MPE ID.
  --post-launch-actions: record # Post Launch Actions to executed on the Test or Cutover instance. — shape: {cloudWatchLogGroupName?: any, deployment?: any, s3LogBucket?: any, s3OutputKeyPrefix?: any, ssmDocuments?: any}
  --small-volume-conf: record # Launch template disk configuration. — shape: {iops?: any, throughput?: any, volumeType?: any}
  --small-volume-max-size: int # Small volume maximum size.
  --target-instance-type-right-sizing-method: string@target-instance-type-right-sizing-method-completer # Target instance type right-sizing method.
]: any -> record<arn: record, associatePublicIpAddress: record, bootMode: record, copyPrivateIp: record, copyTags: record, ec2LaunchTemplateID: record, enableMapAutoTagging: record, largeVolumeConf: record<iops: record, throughput: record, volumeType: record>, launchConfigurationTemplateID: record, launchDisposition: record, licensing: record<osByol: record>, mapAutoTaggingMpeID: record, postLaunchActions: record<cloudWatchLogGroupName: record, deployment: record, s3LogBucket: record, s3OutputKeyPrefix: record, ssmDocuments: record>, smallVolumeConf: record<iops: record, throughput: record, volumeType: record>, smallVolumeMaxSize: record, tags: record, targetInstanceTypeRightSizingMethod: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/UpdateLaunchConfigurationTemplate")
  let req_body = {"associatePublicIpAddress": $associate_public_ip_address, "bootMode": $boot_mode, "copyPrivateIp": $copy_private_ip, "copyTags": $copy_tags, "enableMapAutoTagging": $enable_map_auto_tagging, "largeVolumeConf": $large_volume_conf, "launchConfigurationTemplateID": $launch_configuration_template_id, "launchDisposition": $launch_disposition, "licensing": $licensing, "mapAutoTaggingMpeID": $map_auto_tagging_mpe_id, "postLaunchActions": $post_launch_actions, "smallVolumeConf": $small_volume_conf, "smallVolumeMaxSize": $small_volume_max_size, "targetInstanceTypeRightSizingMethod": $target_instance_type_right_sizing_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Allows you to update multiple ReplicationConfigurations by Source Server ID.
#
# POST /UpdateReplicationConfiguration
# operationId: UpdateReplicationConfiguration
# --replicatedDisks item shape: {deviceName?: any, iops?: any, isBootDisk?: any, stagingDiskType?: any, throughput?: any}
export def "update-replication-configuration update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --associate-default-security-group: oneof<nothing, bool> # Update replication configuration associate default Application Migration Service Security group request.
  --bandwidth-throttling: int # Update replication configuration bandwidth throttling request.
  --create-public-ip: oneof<nothing, bool> # Update replication configuration create Public IP request.
  --data-plane-routing: string@data-plane-routing-completer # Update replication configuration data plane routing request.
  --default-large-staging-disk-type: string@default-large-staging-disk-type-completer # Update replication configuration use default large Staging Disk type request.
  --ebs-encryption: string@ebs-encryption-completer # Update replication configuration EBS encryption request.
  --ebs-encryption-key-arn: string # Update replication configuration EBS encryption key ARN request.
  --name: string # Update replication configuration name request.
  --replicated-disks: list # Update replication configuration replicated disks request. — item shape: {deviceName?: any, iops?: any, isBootDisk?: any, stagingDiskType?: any, throughput?: any}
  --replication-server-instance-type: string # Update replication configuration Replication Server instance type request.
  --replication-servers-security-groups-i-ds: list<string> # Update replication configuration Replication Server Security Groups IDs request.
  source_server_id: string # Update replication configuration Source Server ID request.
  --staging-area-subnet-id: string # Update replication configuration Staging Area subnet request.
  --staging-area-tags: record # Update replication configuration Staging Area Tags request.
  --use-dedicated-replication-server: oneof<nothing, bool> # Update replication configuration use dedicated Replication Server request.
]: any -> record<associateDefaultSecurityGroup: record, bandwidthThrottling: record, createPublicIP: record, dataPlaneRouting: record, defaultLargeStagingDiskType: record, ebsEncryption: record, ebsEncryptionKeyArn: record, name: record, replicatedDisks: record, replicationServerInstanceType: record, replicationServersSecurityGroupsIDs: record, sourceServerID: record, stagingAreaSubnetId: record, stagingAreaTags: record, useDedicatedReplicationServer: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/UpdateReplicationConfiguration")
  let req_body = {"associateDefaultSecurityGroup": $associate_default_security_group, "bandwidthThrottling": $bandwidth_throttling, "createPublicIP": $create_public_ip, "dataPlaneRouting": $data_plane_routing, "defaultLargeStagingDiskType": $default_large_staging_disk_type, "ebsEncryption": $ebs_encryption, "ebsEncryptionKeyArn": $ebs_encryption_key_arn, "name": $name, "replicatedDisks": $replicated_disks, "replicationServerInstanceType": $replication_server_instance_type, "replicationServersSecurityGroupsIDs": $replication_servers_security_groups_i_ds, "sourceServerID": $source_server_id, "stagingAreaSubnetId": $staging_area_subnet_id, "stagingAreaTags": $staging_area_tags, "useDedicatedReplicationServer": $use_dedicated_replication_server} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates multiple ReplicationConfigurationTemplates by ID.
#
# POST /UpdateReplicationConfigurationTemplate
# operationId: UpdateReplicationConfigurationTemplate
export def "update-replication-configuration-template update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --arn: string # Update replication configuration template ARN request.
  --associate-default-security-group: oneof<nothing, bool> # Update replication configuration template associate default Application Migration Service Security group request.
  --bandwidth-throttling: int # Update replication configuration template bandwidth throttling request.
  --create-public-ip: oneof<nothing, bool> # Update replication configuration template create Public IP request.
  --data-plane-routing: string@data-plane-routing-completer # Update replication configuration template data plane routing request.
  --default-large-staging-disk-type: string@default-large-staging-disk-type-completer # Update replication configuration template use default large Staging Disk type request.
  --ebs-encryption: string@ebs-encryption-completer # Update replication configuration template EBS encryption request.
  --ebs-encryption-key-arn: string # Update replication configuration template EBS encryption key ARN request.
  replication_configuration_template_id: string # Update replication configuration template template ID request.
  --replication-server-instance-type: string # Update replication configuration template Replication Server instance type request.
  --replication-servers-security-groups-i-ds: list<string> # Update replication configuration template Replication Server Security groups IDs request.
  --staging-area-subnet-id: string # Update replication configuration template Staging Area subnet ID request.
  --staging-area-tags: record # Update replication configuration template Staging Area Tags request.
  --use-dedicated-replication-server: oneof<nothing, bool> # Update replication configuration template use dedicated Replication Server request.
]: any -> record<arn: record, associateDefaultSecurityGroup: record, bandwidthThrottling: record, createPublicIP: record, dataPlaneRouting: record, defaultLargeStagingDiskType: record, ebsEncryption: record, ebsEncryptionKeyArn: record, replicationConfigurationTemplateID: record, replicationServerInstanceType: record, replicationServersSecurityGroupsIDs: record, stagingAreaSubnetId: record, stagingAreaTags: record, tags: record, useDedicatedReplicationServer: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/UpdateReplicationConfigurationTemplate")
  let req_body = {"arn": $arn, "associateDefaultSecurityGroup": $associate_default_security_group, "bandwidthThrottling": $bandwidth_throttling, "createPublicIP": $create_public_ip, "dataPlaneRouting": $data_plane_routing, "defaultLargeStagingDiskType": $default_large_staging_disk_type, "ebsEncryption": $ebs_encryption, "ebsEncryptionKeyArn": $ebs_encryption_key_arn, "replicationConfigurationTemplateID": $replication_configuration_template_id, "replicationServerInstanceType": $replication_server_instance_type, "replicationServersSecurityGroupsIDs": $replication_servers_security_groups_i_ds, "stagingAreaSubnetId": $staging_area_subnet_id, "stagingAreaTags": $staging_area_tags, "useDedicatedReplicationServer": $use_dedicated_replication_server} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Allows you to change between the AGENT_BASED replication type and the SNAPSHOT_SHIPPING replication type.
#
# POST /UpdateSourceServerReplicationType
# operationId: UpdateSourceServerReplicationType
export def "update-source-server-replication-type update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  replication_type: string@replication-type-completer # Replication type to which to update source server.
  source_server_id: string # ID of source server on which to update replication type.
]: any -> record<applicationID: record, arn: record, dataReplicationInfo: record<dataReplicationError: record<error: record, rawError: record>, dataReplicationInitiation: record<nextAttemptDateTime: record, startDateTime: record, steps: record>, dataReplicationState: record, etaDateTime: record, lagDuration: record, lastSnapshotDateTime: record, replicatedDisks: record>, fqdnForActionFramework: record, isArchived: record, launchedInstance: record<ec2InstanceID: record, firstBoot: record, jobID: record>, lifeCycle: record<addedToServiceDateTime: record, elapsedReplicationDuration: record, firstByteDateTime: record, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: record, lastTest: record<finalized: record, initiated: record, reverted: record>, state: record>, replicationType: record, sourceProperties: record<cpus: record, disks: record, identificationHints: record<awsInstanceID: record, fqdn: record, hostname: record, vmPath: record, vmWareUuid: record>, lastUpdatedDateTime: record, networkInterfaces: record, os: record<fullString: record>, ramBytes: record, recommendedInstanceType: record>, sourceServerID: record, tags: record, userProvidedID: record, vcenterClientID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/UpdateSourceServerReplicationType")
  let req_body = {"replicationType": $replication_type, "sourceServerID": $source_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update wave.
#
# POST /UpdateWave
# operationId: UpdateWave
export def "update-wave update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Wave description.
  --name: string # Wave name.
  wave_id: string # Wave ID.
]: any -> record<arn: record, creationDateTime: record, description: record, isArchived: record, lastModifiedDateTime: record, name: record, tags: record, waveAggregatedStatus: record<healthStatus: record, lastUpdateDateTime: record, progressStatus: record, replicationStartedDateTime: record, totalApplications: record>, waveID: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/UpdateWave")
  let req_body = {"description": $description, "name": $name, "waveID": $wave_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
