# Auto-generated client for Amazon Import/Export Snowball v2016-06-30
# Source: https://api.apis.guru/v2/specs/amazonaws.com/snowball/2016-06-30/openapi.json
# Auth: --token flag or $env.AMAZON_IMPORT_EXPORT_SNOWBALL_TOKEN

const BASE_URL = "http://snowball.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_IMPORT_EXPORT_SNOWBALL_TOKEN | default "" }
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

def base-url-completer [] { ["http://snowball.us-east-1.amazonaws.com" "http://snowball.us-east-2.amazonaws.com" "http://snowball.us-west-1.amazonaws.com" "http://snowball.us-west-2.amazonaws.com" "http://snowball.us-gov-west-1.amazonaws.com" "http://snowball.us-gov-east-1.amazonaws.com" "http://snowball.ca-central-1.amazonaws.com" "http://snowball.eu-north-1.amazonaws.com" "http://snowball.eu-west-1.amazonaws.com" "http://snowball.eu-west-2.amazonaws.com" "http://snowball.eu-west-3.amazonaws.com" "http://snowball.eu-central-1.amazonaws.com" "http://snowball.eu-south-1.amazonaws.com" "http://snowball.af-south-1.amazonaws.com" "http://snowball.ap-northeast-1.amazonaws.com" "http://snowball.ap-northeast-2.amazonaws.com" "http://snowball.ap-northeast-3.amazonaws.com" "http://snowball.ap-southeast-1.amazonaws.com" "http://snowball.ap-southeast-2.amazonaws.com" "http://snowball.ap-east-1.amazonaws.com" "http://snowball.ap-south-1.amazonaws.com" "http://snowball.sa-east-1.amazonaws.com" "http://snowball.me-south-1.amazonaws.com" "https://snowball.us-east-1.amazonaws.com" "https://snowball.us-east-2.amazonaws.com" "https://snowball.us-west-1.amazonaws.com" "https://snowball.us-west-2.amazonaws.com" "https://snowball.us-gov-west-1.amazonaws.com" "https://snowball.us-gov-east-1.amazonaws.com" "https://snowball.ca-central-1.amazonaws.com" "https://snowball.eu-north-1.amazonaws.com" "https://snowball.eu-west-1.amazonaws.com" "https://snowball.eu-west-2.amazonaws.com" "https://snowball.eu-west-3.amazonaws.com" "https://snowball.eu-central-1.amazonaws.com" "https://snowball.eu-south-1.amazonaws.com" "https://snowball.af-south-1.amazonaws.com" "https://snowball.ap-northeast-1.amazonaws.com" "https://snowball.ap-northeast-2.amazonaws.com" "https://snowball.ap-northeast-3.amazonaws.com" "https://snowball.ap-southeast-1.amazonaws.com" "https://snowball.ap-southeast-2.amazonaws.com" "https://snowball.ap-east-1.amazonaws.com" "https://snowball.ap-south-1.amazonaws.com" "https://snowball.sa-east-1.amazonaws.com" "https://snowball.me-south-1.amazonaws.com" "http://snowball.cn-north-1.amazonaws.com.cn" "http://snowball.cn-northwest-1.amazonaws.com.cn" "https://snowball.cn-north-1.amazonaws.com.cn" "https://snowball.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSIESnowballJobManagementService.CancelCluster"] }
def x-amz-target-completer-1 [] { ["AWSIESnowballJobManagementService.CancelJob"] }
def x-amz-target-completer-2 [] { ["AWSIESnowballJobManagementService.CreateAddress"] }
def job-type-completer [] { ["EXPORT" "IMPORT" "LOCAL_USE"] }
def snowball-type-completer [] { ["EDGE" "EDGE_C" "EDGE_CG" "EDGE_S" "SNC1_HDD" "SNC1_SSD" "STANDARD" "V3_5C" "V3_5S"] }
def shipping-option-completer [] { ["EXPRESS" "NEXT_DAY" "SECOND_DAY" "STANDARD"] }
def remote-management-completer [] { ["INSTALLED_AUTOSTART" "INSTALLED_ONLY"] }
def snowball-capacity-preference-completer [] { ["NoPreference" "T100" "T14" "T240" "T32" "T42" "T50" "T8" "T80" "T98"] }
def x-amz-target-completer-3 [] { ["AWSIESnowballJobManagementService.CreateCluster"] }
def x-amz-target-completer-4 [] { ["AWSIESnowballJobManagementService.CreateJob"] }
def long-term-pricing-type-completer [] { ["OneMonth" "OneYear" "ThreeYear"] }
def x-amz-target-completer-5 [] { ["AWSIESnowballJobManagementService.CreateLongTermPricing"] }
def x-amz-target-completer-6 [] { ["AWSIESnowballJobManagementService.CreateReturnShippingLabel"] }
def x-amz-target-completer-7 [] { ["AWSIESnowballJobManagementService.DescribeAddress"] }
def x-amz-target-completer-8 [] { ["AWSIESnowballJobManagementService.DescribeAddresses"] }
def x-amz-target-completer-9 [] { ["AWSIESnowballJobManagementService.DescribeCluster"] }
def x-amz-target-completer-10 [] { ["AWSIESnowballJobManagementService.DescribeJob"] }
def x-amz-target-completer-11 [] { ["AWSIESnowballJobManagementService.DescribeReturnShippingLabel"] }
def x-amz-target-completer-12 [] { ["AWSIESnowballJobManagementService.GetJobManifest"] }
def x-amz-target-completer-13 [] { ["AWSIESnowballJobManagementService.GetJobUnlockCode"] }
def x-amz-target-completer-14 [] { ["AWSIESnowballJobManagementService.GetSnowballUsage"] }
def x-amz-target-completer-15 [] { ["AWSIESnowballJobManagementService.GetSoftwareUpdates"] }
def x-amz-target-completer-16 [] { ["AWSIESnowballJobManagementService.ListClusterJobs"] }
def x-amz-target-completer-17 [] { ["AWSIESnowballJobManagementService.ListClusters"] }
def x-amz-target-completer-18 [] { ["AWSIESnowballJobManagementService.ListCompatibleImages"] }
def x-amz-target-completer-19 [] { ["AWSIESnowballJobManagementService.ListJobs"] }
def x-amz-target-completer-20 [] { ["AWSIESnowballJobManagementService.ListLongTermPricing"] }
def service-name-completer [] { ["EKS_ANYWHERE" "KUBERNETES"] }
def x-amz-target-completer-21 [] { ["AWSIESnowballJobManagementService.ListServiceVersions"] }
def x-amz-target-completer-22 [] { ["AWSIESnowballJobManagementService.UpdateCluster"] }
def x-amz-target-completer-23 [] { ["AWSIESnowballJobManagementService.UpdateJob"] }
def shipment-state-completer [] { ["RECEIVED" "RETURNED"] }
def x-amz-target-completer-24 [] { ["AWSIESnowballJobManagementService.UpdateJobShipmentState"] }
def x-amz-target-completer-25 [] { ["AWSIESnowballJobManagementService.UpdateLongTermPricing"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cancel-cluster" } } | get name | first)
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

# Cancels a cluster job. You can only cancel a cluster job while it's in the AwaitingQuorum status. You'll have at least an hour after creating a cluster job to cancel it.
#
# POST /
# operationId: CancelCluster
export def "cancel-cluster" [
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
  cluster_id: string # The 39-character ID for the cluster that you want to cancel, for example CID123e4567-e89b-12d3-a456-426655440000.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.CancelCluster")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClusterId": $cluster_id} | compact
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

# Cancels the specified job. You can only cancel a job before its JobState value changes to PreparingAppliance. Requesting the ListJobs or DescribeJob action returns a job's JobState as part of the response element data returned.
#
# POST /
# operationId: CancelJob
export def "cancel-job" [
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
  job_id: string # The 39-character job ID for the job that you want to cancel, for example JID123e4567-e89b-12d3-a456-426655440000.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.CancelJob")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"JobId": $job_id} | compact
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

# Creates an address for a Snow device to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
#
# POST /
# operationId: CreateAddress
# --Address shape: {AddressId?: string, Name?: string, Company?: string, Street1?: string, Street2?: string, Street3?: string, City?: string, StateOrProvince?: string, PrefectureOrDistrict?: string, Landmark?: string, Country?: string, PostalCode?: string, PhoneNumber?: string, IsRestricted?: bool}
export def "create-address" [
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
  address: record # The address that you want the Snow device(s) associated with a specific job to be shipped to. Addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. Although no individual elements of the Address are required, if the address is invalid or unsupported, then an exception is thrown. — shape: {AddressId?: string, Name?: string, Company?: string, Street1?: string, Street2?: string, Street3?: string, City?: string, StateOrProvince?: string, PrefectureOrDistrict?: string, Landmark?: string, Country?: string, PostalCode?: string, PhoneNumber?: string, IsRestricted?: bool}
]: any -> record<AddressId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.CreateAddress")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Address": $address} | compact
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

# Creates an empty cluster. Each cluster supports five nodes. You use the CreateJob action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
#
# POST /
# operationId: CreateCluster
# --Resources shape: {S3Resources?: list, LambdaResources?: list, Ec2AmiResources?: list}
# --OnDeviceServiceConfiguration shape: {NFSOnDeviceService?: record, TGWOnDeviceService?: record, EKSOnDeviceService?: record, S3OnDeviceService?: record}
# --Notification shape: {SnsTopicARN?: string, JobStatesToNotify?: list<string>, NotifyAll?: bool}
# --TaxDocuments shape: {IND?: record}
export def "create-cluster" [
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
  job_type: string@job-type-completer # The type of job for this cluster. Currently, the only job type supported for clusters is LOCAL_USE. For more information, see "https://docs.aws.amazon.com/snowball/latest/snowcone-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide or "https://docs.aws.amazon.com/snowball/latest/developer-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide.
  --resources: record # Contains an array of Amazon Web Services resource objects. Each object represents an Amazon S3 bucket, an Lambda function, or an Amazon Machine Image (AMI) based on Amazon EC2 that is associated with a particular job. — shape: {S3Resources?: list, LambdaResources?: list, Ec2AmiResources?: list}
  --on-device-service-configuration: record # An object that represents the metadata and configuration settings for services on an Amazon Web Services Snow Family device. — shape: {NFSOnDeviceService?: record, TGWOnDeviceService?: record, EKSOnDeviceService?: record, S3OnDeviceService?: record}
  --description: string # An optional description of this specific cluster, for example Environmental Data Cluster-01.
  address_id: string # The ID for the address that you want the cluster shipped to.
  --kms-key-arn: string # The KmsKeyARN value that you want to associate with this cluster. KmsKeyARN values are created by using the CreateKey (https://docs.aws.amazon.com/kms/latest/APIReference/API_CreateKey.html) API action in Key Management Service (KMS).
  --role-arn: string # The RoleARN that you want to associate with this cluster. RoleArn values are created by using the CreateRole (https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateRole.html) API action in Identity and Access Management (IAM).
  snowball_type: string@snowball-type-completer # The type of Snow Family devices to use for this cluster. For cluster jobs, Amazon Web Services Snow Family currently supports only the EDGE device type. For more information, see "https://docs.aws.amazon.com/snowball/latest/snowcone-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide or "https://docs.aws.amazon.com/snowball/latest/developer-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide.
  shipping_option: string@shipping-option-completer # The shipping speed for each node in this cluster. This speed doesn't dictate how soon you'll get each Snowball Edge device, rather it represents how quickly each device moves to its destination while in transit. Regional shipping speeds are as follows: In Australia, you have access to express shipping. Typically, Snow devices shipped express are delivered in about a day. In the European Union (EU), you have access to express shipping. Typically, Snow devices shipped express are delivered in about a day. In addition, most countries in the EU have access to standard shipping, which typically takes less than a week, one way. In India, Snow devices are delivered in one to seven days. In the United States of America (US), you have access to one-day shipping and two-day shipping. In Australia, you have access to express shipping. Typically, devices shipped express are delivered in about a day. In the European Union (EU), you have access to express shipping. Typically, Snow devices shipped express are delivered in about a day. In addition, most countries in the EU have access to standard shipping, which typically takes less than a week, one way. In India, Snow devices are delivered in one to seven days. In the US, you have access to one-day shipping and two-day shipping.
  --notification: record # The Amazon Simple Notification Service (Amazon SNS) notification settings associated with a specific job. The Notification object is returned as a part of the response syntax of the DescribeJob action in the JobMetadata data type. When the notification settings are defined during job creation, you can choose to notify based on a specific set of job states using the JobStatesToNotify array of strings, or you can specify that you want to have Amazon SNS notifications sent out for all job states with NotifyAll set to true. — shape: {SnsTopicARN?: string, JobStatesToNotify?: list<string>, NotifyAll?: bool}
  --forwarding-address-id: string # The forwarding address ID for a cluster. This field is not supported in most regions.
  --tax-documents: record # The tax documents required in your Amazon Web Services Region. — shape: {IND?: record}
  --remote-management: string@remote-management-completer # Allows you to securely operate and manage Snow devices in a cluster remotely from outside of your internal network. When set to INSTALLED_AUTOSTART, remote management will automatically be available when the device arrives at your location. Otherwise, you need to use the Snowball Client to manage the device.
  --initial-cluster-size: int # If provided, each job will be automatically created and associated with the new cluster. If not provided, will be treated as 0.
  --force-create-jobs: oneof<nothing, bool> # Force to create cluster when user attempts to overprovision or underprovision a cluster. A cluster is overprovisioned or underprovisioned if the initial size of the cluster is more (overprovisioned) or less (underprovisioned) than what needed to meet capacity requirement specified with OnDeviceServiceConfiguration.
  --long-term-pricing-ids: list<string> # Lists long-term pricing id that will be used to associate with jobs automatically created for the new cluster.
  --snowball-capacity-preference: string@snowball-capacity-preference-completer # If your job is being created in one of the US regions, you have the option of specifying what size Snow device you'd like for this job. In all other regions, Snowballs come with 80 TB in storage capacity. For more information, see "https://docs.aws.amazon.com/snowball/latest/snowcone-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide or "https://docs.aws.amazon.com/snowball/latest/developer-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide.
]: any -> record<ClusterId: string, JobListEntries: table<JobId: string, JobState: string, IsMaster: bool, JobType: string, SnowballType: string, CreationDate: string, Description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.CreateCluster")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"JobType": $job_type, "Resources": $resources, "OnDeviceServiceConfiguration": $on_device_service_configuration, "Description": $description, "AddressId": $address_id, "KmsKeyARN": $kms_key_arn, "RoleARN": $role_arn, "SnowballType": $snowball_type, "ShippingOption": $shipping_option, "Notification": $notification, "ForwardingAddressId": $forwarding_address_id, "TaxDocuments": $tax_documents, "RemoteManagement": $remote_management, "InitialClusterSize": $initial_cluster_size, "ForceCreateJobs": $force_create_jobs, "LongTermPricingIds": $long_term_pricing_ids, "SnowballCapacityPreference": $snowball_capacity_preference} | compact
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

# Creates a job to import or export data between Amazon S3 and your on-premises data center. Your Amazon Web Services account must have the right trust policies and permissions in place to create a job for a Snow device. If you're creating a job for a node in a cluster, you only need to provide the clusterId value; the other job attributes are inherited from the cluster. Only the Snowball; Edge device type is supported when ordering clustered jobs. The device capacity is optional. Availability of device types differ by Amazon Web Services Region. For more information about Region availability, see Amazon Web Services Regional Services (https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/?p=ngi&loc=4). Snow Family devices and their capacities. Device type: SNC1_SSD Capacity: T14 Description: Snowcone Device type: SNC1_HDD Capacity: T8 Description: Snowcone Device type: EDGE_S Capacity: T98 Description: Snowball Edge Storage Optimized for data transfer only Device type: EDGE_CG Capacity: T42 Description: Snowball Edge Compute Optimized with GPU Device type: EDGE_C Capacity: T42 Description: Snowball Edge Compute Optimized without GPU Device type: EDGE Capacity: T100 Description: Snowball Edge Storage Optimized with EC2 Compute Device type: STANDARD Capacity: T50 Description: Original Snowball device This device is only available in the Ningxia, Beijing, and Singapore Amazon Web Services Region Device type: STANDARD Capacity: T80 Description: Original Snowball device This device is only available in the Ningxia, Beijing, and Singapore Amazon Web Services Region. Device type: V3_5C Capacity: T32 Description: Snowball Edge Compute Optimized without GPU Device type: V3_5S Capacity: T240 Description: Snowball Edge Storage Optimized 210TB
#
# POST /
# operationId: CreateJob
# --Resources shape: {S3Resources?: list, LambdaResources?: list, Ec2AmiResources?: list}
# --OnDeviceServiceConfiguration shape: {NFSOnDeviceService?: record, TGWOnDeviceService?: record, EKSOnDeviceService?: record, S3OnDeviceService?: record}
# --Notification shape: {SnsTopicARN?: string, JobStatesToNotify?: list<string>, NotifyAll?: bool}
# --TaxDocuments shape: {IND?: record}
# --DeviceConfiguration shape: {SnowconeDeviceConfiguration?: record}
export def "create-job" [
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
  --job-type: string@job-type-completer # Defines the type of job that you're creating.
  --resources: record # Contains an array of Amazon Web Services resource objects. Each object represents an Amazon S3 bucket, an Lambda function, or an Amazon Machine Image (AMI) based on Amazon EC2 that is associated with a particular job. — shape: {S3Resources?: list, LambdaResources?: list, Ec2AmiResources?: list}
  --on-device-service-configuration: record # An object that represents the metadata and configuration settings for services on an Amazon Web Services Snow Family device. — shape: {NFSOnDeviceService?: record, TGWOnDeviceService?: record, EKSOnDeviceService?: record, S3OnDeviceService?: record}
  --description: string # Defines an optional description of this specific job, for example Important Photos 2016-08-11.
  --address-id: string # The ID for the address that you want the Snow device shipped to.
  --kms-key-arn: string # The KmsKeyARN that you want to associate with this job. KmsKeyARNs are created using the CreateKey (https://docs.aws.amazon.com/kms/latest/APIReference/API_CreateKey.html) Key Management Service (KMS) API action.
  --role-arn: string # The RoleARN that you want to associate with this job. RoleArns are created using the CreateRole (https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateRole.html) Identity and Access Management (IAM) API action.
  --snowball-capacity-preference: string@snowball-capacity-preference-completer # If your job is being created in one of the US regions, you have the option of specifying what size Snow device you'd like for this job. In all other regions, Snowballs come with 80 TB in storage capacity. For more information, see "https://docs.aws.amazon.com/snowball/latest/snowcone-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide or "https://docs.aws.amazon.com/snowball/latest/developer-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide.
  --shipping-option: string@shipping-option-completer # The shipping speed for this job. This speed doesn't dictate how soon you'll get the Snow device, rather it represents how quickly the Snow device moves to its destination while in transit. Regional shipping speeds are as follows: In Australia, you have access to express shipping. Typically, Snow devices shipped express are delivered in about a day. In the European Union (EU), you have access to express shipping. Typically, Snow devices shipped express are delivered in about a day. In addition, most countries in the EU have access to standard shipping, which typically takes less than a week, one way. In India, Snow devices are delivered in one to seven days. In the US, you have access to one-day shipping and two-day shipping.
  --notification: record # The Amazon Simple Notification Service (Amazon SNS) notification settings associated with a specific job. The Notification object is returned as a part of the response syntax of the DescribeJob action in the JobMetadata data type. When the notification settings are defined during job creation, you can choose to notify based on a specific set of job states using the JobStatesToNotify array of strings, or you can specify that you want to have Amazon SNS notifications sent out for all job states with NotifyAll set to true. — shape: {SnsTopicARN?: string, JobStatesToNotify?: list<string>, NotifyAll?: bool}
  --cluster-id: string # The ID of a cluster. If you're creating a job for a node in a cluster, you need to provide only this clusterId value. The other job attributes are inherited from the cluster.
  --snowball-type: string@snowball-type-completer # The type of Snow Family devices to use for this job. For cluster jobs, Amazon Web Services Snow Family currently supports only the EDGE device type. The type of Amazon Web Services Snow device to use for this job. Currently, the only supported device type for cluster jobs is EDGE. For more information, see Snowball Edge Device Options (https://docs.aws.amazon.com/snowball/latest/developer-guide/device-differences.html) in the Snowball Edge Developer Guide. For more information, see "https://docs.aws.amazon.com/snowball/latest/snowcone-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide or "https://docs.aws.amazon.com/snowball/latest/developer-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide.
  --forwarding-address-id: string # The forwarding address ID for a job. This field is not supported in most Regions.
  --tax-documents: record # The tax documents required in your Amazon Web Services Region. — shape: {IND?: record}
  --device-configuration: record # The container for SnowconeDeviceConfiguration. — shape: {SnowconeDeviceConfiguration?: record}
  --remote-management: string@remote-management-completer # Allows you to securely operate and manage Snowcone devices remotely from outside of your internal network. When set to INSTALLED_AUTOSTART, remote management will automatically be available when the device arrives at your location. Otherwise, you need to use the Snowball Client to manage the device.
  --long-term-pricing-id: string # The ID of the long-term pricing type for the device.
]: any -> record<JobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.CreateJob")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"JobType": $job_type, "Resources": $resources, "OnDeviceServiceConfiguration": $on_device_service_configuration, "Description": $description, "AddressId": $address_id, "KmsKeyARN": $kms_key_arn, "RoleARN": $role_arn, "SnowballCapacityPreference": $snowball_capacity_preference, "ShippingOption": $shipping_option, "Notification": $notification, "ClusterId": $cluster_id, "SnowballType": $snowball_type, "ForwardingAddressId": $forwarding_address_id, "TaxDocuments": $tax_documents, "DeviceConfiguration": $device_configuration, "RemoteManagement": $remote_management, "LongTermPricingId": $long_term_pricing_id} | compact
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

# Creates a job with the long-term usage option for a device. The long-term usage is a 1-year or 3-year long-term pricing type for the device. You are billed upfront, and Amazon Web Services provides discounts for long-term pricing.
#
# POST /
# operationId: CreateLongTermPricing
export def "create-long-term-pricing" [
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
  long_term_pricing_type: string@long-term-pricing-type-completer # The type of long-term pricing option you want for the device, either 1-year or 3-year long-term pricing.
  --is-long-term-pricing-auto-renew: oneof<nothing, bool> # Specifies whether the current long-term pricing type for the device should be renewed.
  --snowball-type: string@snowball-type-completer # The type of Snow Family devices to use for the long-term pricing job.
]: any -> record<LongTermPricingId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.CreateLongTermPricing")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LongTermPricingType": $long_term_pricing_type, "IsLongTermPricingAutoRenew": $is_long_term_pricing_auto_renew, "SnowballType": $snowball_type} | compact
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

# Creates a shipping label that will be used to return the Snow device to Amazon Web Services.
#
# POST /
# operationId: CreateReturnShippingLabel
export def "create-return-shipping-label" [
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
  job_id: string # The ID for a job that you want to create the return shipping label for; for example, JID123e4567-e89b-12d3-a456-426655440000.
  --shipping-option: string@shipping-option-completer # The shipping speed for a particular job. This speed doesn't dictate how soon the device is returned to Amazon Web Services. This speed represents how quickly it moves to its destination while in transit. Regional shipping speeds are as follows:
]: any -> record<Status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.CreateReturnShippingLabel")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"JobId": $job_id, "ShippingOption": $shipping_option} | compact
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

# Takes an AddressId and returns specific details about that address in the form of an Address object.
#
# POST /
# operationId: DescribeAddress
export def "describe-address" [
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
  address_id: string # The automatically generated ID for a specific address.
]: any -> record<Address: record<AddressId: string, Name: string, Company: string, Street1: string, Street2: string, Street3: string, City: string, StateOrProvince: string, PrefectureOrDistrict: string, Landmark: string, Country: string, PostalCode: string, PhoneNumber: string, IsRestricted: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.DescribeAddress")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AddressId": $address_id} | compact
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

# Returns a specified number of ADDRESS objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
#
# POST /
# operationId: DescribeAddresses
export def "describe-addresses" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  --max-results-body: int # The number of ADDRESS objects to return. (body field)
  --next-token-body: string # HTTP requests are stateless. To identify what object comes "next" in the list of ADDRESS objects, you have the option of specifying a value for NextToken as the starting point for your list of returned addresses. (body field)
]: any -> record<Addresses: table<AddressId: string, Name: string, Company: string, Street1: string, Street2: string, Street3: string, City: string, StateOrProvince: string, PrefectureOrDistrict: string, Landmark: string, Country: string, PostalCode: string, PhoneNumber: string, IsRestricted: bool>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.DescribeAddresses")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
#
# POST /
# operationId: DescribeCluster
export def "describe-cluster" [
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
  cluster_id: string # The automatically generated ID for a cluster.
]: any -> record<ClusterMetadata: record<ClusterId: string, Description: string, KmsKeyARN: string, RoleARN: string, ClusterState: string, JobType: string, SnowballType: string, CreationDate: string, Resources: record<S3Resources: list, LambdaResources: list, Ec2AmiResources: list>, AddressId: string, ShippingOption: string, Notification: record<SnsTopicARN: string, JobStatesToNotify: list, NotifyAll: bool>, ForwardingAddressId: string, TaxDocuments: record<IND: record>, OnDeviceServiceConfiguration: record<NFSOnDeviceService: record, TGWOnDeviceService: record, EKSOnDeviceService: record, S3OnDeviceService: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.DescribeCluster")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClusterId": $cluster_id} | compact
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

# Returns information about a specific job including shipping information, job status, and other important metadata.
#
# POST /
# operationId: DescribeJob
export def "describe-job" [
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
  job_id: string # The automatically generated ID for a job, for example JID123e4567-e89b-12d3-a456-426655440000.
]: any -> record<JobMetadata: record<JobId: string, JobState: string, JobType: string, SnowballType: string, CreationDate: string, Resources: record<S3Resources: list, LambdaResources: list, Ec2AmiResources: list>, Description: string, KmsKeyARN: string, RoleARN: string, AddressId: string, ShippingDetails: record<ShippingOption: string, InboundShipment: record, OutboundShipment: record>, SnowballCapacityPreference: string, Notification: record<SnsTopicARN: string, JobStatesToNotify: list, NotifyAll: bool>, DataTransferProgress: record<BytesTransferred: int, ObjectsTransferred: int, TotalBytes: int, TotalObjects: int>, JobLogInfo: record<JobCompletionReportURI: string, JobSuccessLogURI: string, JobFailureLogURI: string>, ClusterId: string, ForwardingAddressId: string, TaxDocuments: record<IND: record>, DeviceConfiguration: record<SnowconeDeviceConfiguration: record>, RemoteManagement: string, LongTermPricingId: string, OnDeviceServiceConfiguration: record<NFSOnDeviceService: record, TGWOnDeviceService: record, EKSOnDeviceService: record, S3OnDeviceService: record>>, SubJobMetadata: table<JobId: string, JobState: string, JobType: string, SnowballType: string, CreationDate: string, Resources: record, Description: string, KmsKeyARN: string, RoleARN: string, AddressId: string, ShippingDetails: record, SnowballCapacityPreference: string, Notification: record, DataTransferProgress: record, JobLogInfo: record, ClusterId: string, ForwardingAddressId: string, TaxDocuments: record, DeviceConfiguration: record, RemoteManagement: string, LongTermPricingId: string, OnDeviceServiceConfiguration: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.DescribeJob")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"JobId": $job_id} | compact
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

# Information on the shipping label of a Snow device that is being returned to Amazon Web Services.
#
# POST /
# operationId: DescribeReturnShippingLabel
export def "describe-return-shipping-label" [
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
  job_id: string # The automatically generated ID for a job, for example JID123e4567-e89b-12d3-a456-426655440000.
]: any -> record<Status: string, ExpirationDate: string, ReturnShippingLabelURI: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.DescribeReturnShippingLabel")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"JobId": $job_id} | compact
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

# Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified JobId value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the GetJobManifest action. The manifest is an encrypted file that you can download after your job enters the WithCustomer status. This is the only valid status for calling this API as the manifest and UnlockCode code value are used for securing your device and should only be used when you have the device. The manifest is decrypted by using the UnlockCode code value, when you pass both values to the Snow device through the Snowball client when the client is started for the first time. As a best practice, we recommend that you don't save a copy of an UnlockCode value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snow device associated with that job. The credentials of a given job, including its manifest file and unlock code, expire 360 days after the job is created.
#
# POST /
# operationId: GetJobManifest
export def "get-job-manifest" [
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
  job_id: string # The ID for a job that you want to get the manifest file for, for example JID123e4567-e89b-12d3-a456-426655440000.
]: any -> record<ManifestURI: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.GetJobManifest")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"JobId": $job_id} | compact
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

# Returns the UnlockCode code value for the specified job. A particular UnlockCode value can be accessed for up to 360 days after the associated job has been created. The UnlockCode value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snow device through the Snowball client when the client is started for the first time. The only valid status for calling this API is WithCustomer as the manifest and Unlock code values are used for securing your device and should only be used when you have the device. As a best practice, we recommend that you don't save a copy of the UnlockCode in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snow device associated with that job.
#
# POST /
# operationId: GetJobUnlockCode
export def "get-job-unlock-code" [
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
  job_id: string # The ID for the job that you want to get the UnlockCode value for, for example JID123e4567-e89b-12d3-a456-426655440000.
]: any -> record<UnlockCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.GetJobUnlockCode")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"JobId": $job_id} | compact
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

# Returns information about the Snow Family service limit for your account, and also the number of Snow devices your account has in use. The default service limit for the number of Snow devices that you can have at one time is 1. If you want to increase your service limit, contact Amazon Web Services Support.
#
# POST /
# operationId: GetSnowballUsage
export def "get-snowball-usage" [
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
  --body: record
]: any -> record<SnowballLimit: int, SnowballsInUse: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.GetSnowballUsage")
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

# Returns an Amazon S3 presigned URL for an update file associated with a specified JobId.
#
# POST /
# operationId: GetSoftwareUpdates
export def "get-software-updates" [
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
  job_id: string # The ID for a job that you want to get the software update file for, for example JID123e4567-e89b-12d3-a456-426655440000.
]: any -> record<UpdatesURI: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.GetSoftwareUpdates")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"JobId": $job_id} | compact
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

# Returns an array of JobListEntry objects of the specified length. Each JobListEntry object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
#
# POST /
# operationId: ListClusterJobs
export def "list-cluster-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  cluster_id: string # The 39-character ID for the cluster that you want to list, for example CID123e4567-e89b-12d3-a456-426655440000.
  --max-results-body: int # The number of JobListEntry objects to return. (body field)
  --next-token-body: string # HTTP requests are stateless. To identify what object comes "next" in the list of JobListEntry objects, you have the option of specifying NextToken as the starting point for your returned list. (body field)
]: any -> record<JobListEntries: table<JobId: string, JobState: string, IsMaster: bool, JobType: string, SnowballType: string, CreationDate: string, Description: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.ListClusterJobs")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ClusterId": $cluster_id, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns an array of ClusterListEntry objects of the specified length. Each ClusterListEntry object contains a cluster's state, a cluster's ID, and other important status information.
#
# POST /
# operationId: ListClusters
export def "list-clusters" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  --max-results-body: int # The number of ClusterListEntry objects to return. (body field)
  --next-token-body: string # HTTP requests are stateless. To identify what object comes "next" in the list of ClusterListEntry objects, you have the option of specifying NextToken as the starting point for your returned list. (body field)
]: any -> record<ClusterListEntries: table<ClusterId: string, ClusterState: string, CreationDate: string, Description: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.ListClusters")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your Amazon Web Services accountthat would be supported for use on a Snow device. Currently, supported AMIs are based on the Amazon Linux-2, Ubuntu 20.04 LTS - Focal, or Ubuntu 22.04 LTS - Jammy images, available on the Amazon Web Services Marketplace. Ubuntu 16.04 LTS - Xenial (HVM) images are no longer supported in the Market, but still supported for use on devices through Amazon EC2 VM Import/Export and running locally in AMIs.
#
# POST /
# operationId: ListCompatibleImages
export def "list-compatible-images" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  --max-results-body: int # The maximum number of results for the list of compatible images. Currently, a Snowball Edge device can store 10 AMIs. (body field)
  --next-token-body: string # HTTP requests are stateless. To identify what object comes "next" in the list of compatible images, you can specify a value for NextToken as the starting point for your list of returned images. (body field)
]: any -> record<CompatibleImages: table<AmiId: string, Name: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.ListCompatibleImages")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns an array of JobListEntry objects of the specified length. Each JobListEntry object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
#
# POST /
# operationId: ListJobs
export def "list-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  --max-results-body: int # The number of JobListEntry objects to return. (body field)
  --next-token-body: string # HTTP requests are stateless. To identify what object comes "next" in the list of JobListEntry objects, you have the option of specifying NextToken as the starting point for your returned list. (body field)
]: any -> record<JobListEntries: table<JobId: string, JobState: string, IsMaster: bool, JobType: string, SnowballType: string, CreationDate: string, Description: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.ListJobs")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all long-term pricing types.
#
# POST /
# operationId: ListLongTermPricing
export def "list-long-term-pricing" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  --max-results-body: int # The maximum number of ListLongTermPricing objects to return. (body field)
  --next-token-body: string # Because HTTP requests are stateless, this is the starting point for your next list of ListLongTermPricing to return. (body field)
]: any -> record<LongTermPricingEntries: table<LongTermPricingId: string, LongTermPricingEndDate: string, LongTermPricingStartDate: string, LongTermPricingType: string, CurrentActiveJob: string, ReplacementJob: string, IsLongTermPricingAutoRenew: bool, LongTermPricingStatus: string, SnowballType: string, JobIds: list>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.ListLongTermPricing")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all supported versions for Snow on-device services. Returns an array of ServiceVersion object containing the supported versions for a particular service.
#
# POST /
# operationId: ListServiceVersions
# --DependentServices item shape: {ServiceName?: "KUBERNETES"|"EKS_ANYWHERE", ServiceVersion?: record}
export def "list-service-versions" [
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
  service_name: string@service-name-completer # The name of the service for which you're requesting supported versions.
  --dependent-services: list # A list of names and versions of dependant services of the requested service. — item shape: {ServiceName?: "KUBERNETES"|"EKS_ANYWHERE", ServiceVersion?: record}
  --max-results: int # The maximum number of ListServiceVersions objects to return.
  --next-token: string # Because HTTP requests are stateless, this is the starting point for the next list of returned ListServiceVersionsRequest versions.
]: any -> record<ServiceVersions: table<Version: string>, ServiceName: string, DependentServices: table<ServiceName: string, ServiceVersion: record>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.ListServiceVersions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ServiceName": $service_name, "DependentServices": $dependent_services, "MaxResults": $max_results, "NextToken": $next_token} | compact
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

# While a cluster's ClusterState value is in the AwaitingQuorum state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
#
# POST /
# operationId: UpdateCluster
# --Resources shape: {S3Resources?: list, LambdaResources?: list, Ec2AmiResources?: list}
# --OnDeviceServiceConfiguration shape: {NFSOnDeviceService?: record, TGWOnDeviceService?: record, EKSOnDeviceService?: record, S3OnDeviceService?: record}
# --Notification shape: {SnsTopicARN?: string, JobStatesToNotify?: list<string>, NotifyAll?: bool}
export def "update-cluster" [
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
  cluster_id: string # The cluster ID of the cluster that you want to update, for example CID123e4567-e89b-12d3-a456-426655440000.
  --role-arn: string # The new role Amazon Resource Name (ARN) that you want to associate with this cluster. To create a role ARN, use the CreateRole (https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateRole.html) API action in Identity and Access Management (IAM).
  --description: string # The updated description of this cluster.
  --resources: record # Contains an array of Amazon Web Services resource objects. Each object represents an Amazon S3 bucket, an Lambda function, or an Amazon Machine Image (AMI) based on Amazon EC2 that is associated with a particular job. — shape: {S3Resources?: list, LambdaResources?: list, Ec2AmiResources?: list}
  --on-device-service-configuration: record # An object that represents the metadata and configuration settings for services on an Amazon Web Services Snow Family device. — shape: {NFSOnDeviceService?: record, TGWOnDeviceService?: record, EKSOnDeviceService?: record, S3OnDeviceService?: record}
  --address-id: string # The ID of the updated Address object.
  --shipping-option: string@shipping-option-completer # The updated shipping option value of this cluster's ShippingDetails object.
  --notification: record # The Amazon Simple Notification Service (Amazon SNS) notification settings associated with a specific job. The Notification object is returned as a part of the response syntax of the DescribeJob action in the JobMetadata data type. When the notification settings are defined during job creation, you can choose to notify based on a specific set of job states using the JobStatesToNotify array of strings, or you can specify that you want to have Amazon SNS notifications sent out for all job states with NotifyAll set to true. — shape: {SnsTopicARN?: string, JobStatesToNotify?: list<string>, NotifyAll?: bool}
  --forwarding-address-id: string # The updated ID for the forwarding address for a cluster. This field is not supported in most regions.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.UpdateCluster")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClusterId": $cluster_id, "RoleARN": $role_arn, "Description": $description, "Resources": $resources, "OnDeviceServiceConfiguration": $on_device_service_configuration, "AddressId": $address_id, "ShippingOption": $shipping_option, "Notification": $notification, "ForwardingAddressId": $forwarding_address_id} | compact
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

# While a job's JobState value is New, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
#
# POST /
# operationId: UpdateJob
# --Notification shape: {SnsTopicARN?: string, JobStatesToNotify?: list<string>, NotifyAll?: bool}
# --Resources shape: {S3Resources?: list, LambdaResources?: list, Ec2AmiResources?: list}
# --OnDeviceServiceConfiguration shape: {NFSOnDeviceService?: record, TGWOnDeviceService?: record, EKSOnDeviceService?: record, S3OnDeviceService?: record}
export def "update-job" [
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
  job_id: string # The job ID of the job that you want to update, for example JID123e4567-e89b-12d3-a456-426655440000.
  --role-arn: string # The new role Amazon Resource Name (ARN) that you want to associate with this job. To create a role ARN, use the CreateRole (https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateRole.html)Identity and Access Management (IAM) API action.
  --notification: record # The Amazon Simple Notification Service (Amazon SNS) notification settings associated with a specific job. The Notification object is returned as a part of the response syntax of the DescribeJob action in the JobMetadata data type. When the notification settings are defined during job creation, you can choose to notify based on a specific set of job states using the JobStatesToNotify array of strings, or you can specify that you want to have Amazon SNS notifications sent out for all job states with NotifyAll set to true. — shape: {SnsTopicARN?: string, JobStatesToNotify?: list<string>, NotifyAll?: bool}
  --resources: record # Contains an array of Amazon Web Services resource objects. Each object represents an Amazon S3 bucket, an Lambda function, or an Amazon Machine Image (AMI) based on Amazon EC2 that is associated with a particular job. — shape: {S3Resources?: list, LambdaResources?: list, Ec2AmiResources?: list}
  --on-device-service-configuration: record # An object that represents the metadata and configuration settings for services on an Amazon Web Services Snow Family device. — shape: {NFSOnDeviceService?: record, TGWOnDeviceService?: record, EKSOnDeviceService?: record, S3OnDeviceService?: record}
  --address-id: string # The ID of the updated Address object.
  --shipping-option: string@shipping-option-completer # The updated shipping option value of this job's ShippingDetails object.
  --description: string # The updated description of this job's JobMetadata object.
  --snowball-capacity-preference: string@snowball-capacity-preference-completer # The updated SnowballCapacityPreference of this job's JobMetadata object. The 50 TB Snowballs are only available in the US regions. For more information, see "https://docs.aws.amazon.com/snowball/latest/snowcone-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide or "https://docs.aws.amazon.com/snowball/latest/developer-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide.
  --forwarding-address-id: string # The updated ID for the forwarding address for a job. This field is not supported in most regions.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.UpdateJob")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"JobId": $job_id, "RoleARN": $role_arn, "Notification": $notification, "Resources": $resources, "OnDeviceServiceConfiguration": $on_device_service_configuration, "AddressId": $address_id, "ShippingOption": $shipping_option, "Description": $description, "SnowballCapacityPreference": $snowball_capacity_preference, "ForwardingAddressId": $forwarding_address_id} | compact
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

# Updates the state when a shipment state changes to a different state.
#
# POST /
# operationId: UpdateJobShipmentState
export def "update-job-shipment-state" [
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
  job_id: string # The job ID of the job whose shipment date you want to update, for example JID123e4567-e89b-12d3-a456-426655440000.
  shipment_state: string@shipment-state-completer # The state of a device when it is being shipped. Set to RECEIVED when the device arrives at your location. Set to RETURNED when you have returned the device to Amazon Web Services.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.UpdateJobShipmentState")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"JobId": $job_id, "ShipmentState": $shipment_state} | compact
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

# Updates the long-term pricing type.
#
# POST /
# operationId: UpdateLongTermPricing
export def "update-long-term-pricing" [
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
  long_term_pricing_id: string # The ID of the long-term pricing type for the device.
  --replacement-job: string # Specifies that a device that is ordered with long-term pricing should be replaced with a new device.
  --is-long-term-pricing-auto-renew: oneof<nothing, bool> # If set to true, specifies that the current long-term pricing type for the device should be automatically renewed before the long-term pricing contract expires.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSIESnowballJobManagementService.UpdateLongTermPricing")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LongTermPricingId": $long_term_pricing_id, "ReplacementJob": $replacement_job, "IsLongTermPricingAutoRenew": $is_long_term_pricing_auto_renew} | compact
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
