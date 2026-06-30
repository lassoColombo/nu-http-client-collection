# Auto-generated client for Amazon Elastic File System v2015-02-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/elasticfilesystem/2015-02-01/openapi.json
# Auth: --token flag or $env.AMAZON_ELASTIC_FILE_SYSTEM_TOKEN

const BASE_URL = "http://elasticfilesystem.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_ELASTIC_FILE_SYSTEM_TOKEN | default "" }
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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://elasticfilesystem.us-east-1.amazonaws.com" "http://elasticfilesystem.us-east-2.amazonaws.com" "http://elasticfilesystem.us-west-1.amazonaws.com" "http://elasticfilesystem.us-west-2.amazonaws.com" "http://elasticfilesystem.us-gov-west-1.amazonaws.com" "http://elasticfilesystem.us-gov-east-1.amazonaws.com" "http://elasticfilesystem.ca-central-1.amazonaws.com" "http://elasticfilesystem.eu-north-1.amazonaws.com" "http://elasticfilesystem.eu-west-1.amazonaws.com" "http://elasticfilesystem.eu-west-2.amazonaws.com" "http://elasticfilesystem.eu-west-3.amazonaws.com" "http://elasticfilesystem.eu-central-1.amazonaws.com" "http://elasticfilesystem.eu-south-1.amazonaws.com" "http://elasticfilesystem.af-south-1.amazonaws.com" "http://elasticfilesystem.ap-northeast-1.amazonaws.com" "http://elasticfilesystem.ap-northeast-2.amazonaws.com" "http://elasticfilesystem.ap-northeast-3.amazonaws.com" "http://elasticfilesystem.ap-southeast-1.amazonaws.com" "http://elasticfilesystem.ap-southeast-2.amazonaws.com" "http://elasticfilesystem.ap-east-1.amazonaws.com" "http://elasticfilesystem.ap-south-1.amazonaws.com" "http://elasticfilesystem.sa-east-1.amazonaws.com" "http://elasticfilesystem.me-south-1.amazonaws.com" "https://elasticfilesystem.us-east-1.amazonaws.com" "https://elasticfilesystem.us-east-2.amazonaws.com" "https://elasticfilesystem.us-west-1.amazonaws.com" "https://elasticfilesystem.us-west-2.amazonaws.com" "https://elasticfilesystem.us-gov-west-1.amazonaws.com" "https://elasticfilesystem.us-gov-east-1.amazonaws.com" "https://elasticfilesystem.ca-central-1.amazonaws.com" "https://elasticfilesystem.eu-north-1.amazonaws.com" "https://elasticfilesystem.eu-west-1.amazonaws.com" "https://elasticfilesystem.eu-west-2.amazonaws.com" "https://elasticfilesystem.eu-west-3.amazonaws.com" "https://elasticfilesystem.eu-central-1.amazonaws.com" "https://elasticfilesystem.eu-south-1.amazonaws.com" "https://elasticfilesystem.af-south-1.amazonaws.com" "https://elasticfilesystem.ap-northeast-1.amazonaws.com" "https://elasticfilesystem.ap-northeast-2.amazonaws.com" "https://elasticfilesystem.ap-northeast-3.amazonaws.com" "https://elasticfilesystem.ap-southeast-1.amazonaws.com" "https://elasticfilesystem.ap-southeast-2.amazonaws.com" "https://elasticfilesystem.ap-east-1.amazonaws.com" "https://elasticfilesystem.ap-south-1.amazonaws.com" "https://elasticfilesystem.sa-east-1.amazonaws.com" "https://elasticfilesystem.me-south-1.amazonaws.com" "http://elasticfilesystem.cn-north-1.amazonaws.com.cn" "http://elasticfilesystem.cn-northwest-1.amazonaws.com.cn" "https://elasticfilesystem.cn-north-1.amazonaws.com.cn" "https://elasticfilesystem.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def performance-mode-completer [] { ["generalPurpose" "maxIO"] }
def throughput-mode-completer [] { ["bursting" "elastic" "provisioned"] }
def resource-id-type-completer [] { ["LONG_ID" "SHORT_ID"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2015-02-01-access-points create" } } | get name | first)
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

# Creates an EFS access point. An access point is an application-specific view into an EFS file system that applies an operating system user and group, and a file system path, to any file system request made through the access point. The operating system user and group override any identity information provided by the NFS client. The file system path is exposed as the access point's root directory. Applications using the access point can only access data in the application's own directory and any subdirectories. To learn more, see Mounting a file system using EFS access points (https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html). If multiple requests to create access points on the same file system are sent in quick succession, and the file system is near the limit of 1000 access points, you may experience a throttling response for these requests. This is to ensure that the file system does not exceed the stated access point limit. This operation requires permissions for the elasticfilesystem:CreateAccessPoint action.
#
# POST /2015-02-01/access-points
# operationId: CreateAccessPoint
# --Tags item shape: {Key: any, Value: any}
# --PosixUser shape: {Uid?: any, Gid?: any, SecondaryGids?: any}
# --RootDirectory shape: {Path?: any, CreationInfo?: any}
export def "2015-02-01-access-points create" [
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
  client_token: string # A string of up to 64 ASCII characters that Amazon EFS uses to ensure idempotent creation.
  --tags: list # Creates tags associated with the access point. Each tag is a key-value pair, each key must be unique. For more information, see Tagging Amazon Web Services resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference Guide. — item shape: {Key: any, Value: any}
  file_system_id: string # The ID of the EFS file system that the access point provides access to.
  --posix-user: record # The full POSIX identity, including the user ID, group ID, and any secondary group IDs, on the access point that is used for all file system operations performed by NFS clients using the access point. — shape: {Uid?: any, Gid?: any, SecondaryGids?: any}
  --root-directory: record # Specifies the directory on the Amazon EFS file system that the access point provides access to. The access point exposes the specified file system path as the root directory of your file system to applications using the access point. NFS clients using the access point can only access data in the access point's RootDirectory and it's subdirectories. — shape: {Path?: any, CreationInfo?: any}
]: any -> record<ClientToken: record, Name: record, Tags: record, AccessPointId: record, AccessPointArn: record, FileSystemId: record, PosixUser: record<Uid: record, Gid: record, SecondaryGids: record>, RootDirectory: record<Path: record, CreationInfo: record<OwnerUid: record, OwnerGid: record, Permissions: record>>, OwnerId: record, LifeCycleState: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-02-01/access-points" $auth.query)
  let req_body = {"ClientToken": $client_token, "Tags": $tags, "FileSystemId": $file_system_id, "PosixUser": $posix_user, "RootDirectory": $root_directory} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Returns the description of a specific Amazon EFS access point if the AccessPointId is provided. If you provide an EFS FileSystemId, it returns descriptions of all access points for that file system. You can provide either an AccessPointId or a FileSystemId in the request, but not both. This operation requires permissions for the elasticfilesystem:DescribeAccessPoints action.
#
# GET /2015-02-01/access-points
# operationId: DescribeAccessPoints
export def "2015-02-01-access-points get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # (Optional) When retrieving all access points for a file system, you can optionally specify the MaxItems parameter to limit the number of objects returned in a response. The default value is 100.
  --next-token: string # NextToken is present if the response is paginated. You can use NextMarker in the subsequent request to fetch the next page of access point descriptions.
  --access-point-id: string # (Optional) Specifies an EFS access point to describe in the response; mutually exclusive with FileSystemId.
  --file-system-id: string # (Optional) If you provide a FileSystemId, EFS returns all access points for that file system; mutually exclusive with AccessPointId.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AccessPoints: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "AccessPointId" $access_point_id "scalar") (serialize-qp "FileSystemId" $file_system_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-02-01/access-points" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token, "AccessPointId": $access_point_id, "FileSystemId": $file_system_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new, empty file system. The operation requires a creation token in the request that Amazon EFS uses to ensure idempotent creation (calling the operation with same creation token has no effect). If a file system does not currently exist that is owned by the caller's Amazon Web Services account with the specified creation token, this operation does the following: Creates a new, empty file system. The file system will have an Amazon EFS assigned ID, and an initial lifecycle state creating. Returns with the description of the created file system. Otherwise, this operation returns a FileSystemAlreadyExists error with the ID of the existing file system. For basic use cases, you can use a randomly generated UUID for the creation token. The idempotent operation allows you to retry a CreateFileSystem call without risk of creating an extra file system. This can happen when an initial call fails in a way that leaves it uncertain whether or not a file system was actually created. An example might be that a transport level timeout occurred or your connection was reset. As long as you use the same creation token, if the initial call had succeeded in creating a file system, the client can learn of its existence from the FileSystemAlreadyExists error. For more information, see Creating a file system (https://docs.aws.amazon.com/efs/latest/ug/creating-using-create-fs.html#creating-using-create-fs-part1) in the Amazon EFS User Guide. The CreateFileSystem call returns while the file system's lifecycle state is still creating. You can check the file system creation status by calling the DescribeFileSystems operation, which among other things returns the file system state. This operation accepts an optional PerformanceMode parameter that you choose for your file system. We recommend generalPurpose performance mode for most file systems. File systems using the maxIO performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. For more information, see Amazon EFS performance modes (https://docs.aws.amazon.com/efs/latest/ug/performance.html#performancemodes.html). You can set the throughput mode for the file system using the ThroughputMode parameter. After the file system is fully created, Amazon EFS sets its lifecycle state to available, at which point you can create one or more mount targets for the file system in your VPC. For more information, see CreateMountTarget. You mount your Amazon EFS file system on an EC2 instances in your VPC by using the mount target. For more information, see Amazon EFS: How it Works (https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html). This operation requires permissions for the elasticfilesystem:CreateFileSystem action.
#
# POST /2015-02-01/file-systems
# operationId: CreateFileSystem
# --Tags item shape: {Key: any, Value: any}
export def "2015-02-01-file-systems create" [
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
  creation_token: string # A string of up to 64 ASCII characters. Amazon EFS uses this to ensure idempotent creation.
  --performance-mode: string@performance-mode-completer # The performance mode of the file system. We recommend generalPurpose performance mode for most file systems. File systems using the maxIO performance mode can scale to higher levels of aggregate throughput and operations per second with a tradeoff of slightly higher latencies for most file operations. The performance mode can't be changed after the file system has been created. The maxIO mode is not supported on file systems using One Zone storage classes.
  --encrypted: oneof<nothing, bool> # A Boolean value that, if true, creates an encrypted file system. When creating an encrypted file system, you have the option of specifying an existing Key Management Service key (KMS key). If you don't specify a KMS key, then the default KMS key for Amazon EFS, /aws/elasticfilesystem, is used to protect the encrypted file system.
  --kms-key-id: string # The ID of the KMS key that you want to use to protect the encrypted file system. This parameter is required only if you want to use a non-default KMS key. If this parameter is not specified, the default KMS key for Amazon EFS is used. You can specify a KMS key ID using the following formats: Key ID - A unique identifier of the key, for example 1234abcd-12ab-34cd-56ef-1234567890ab. ARN - An Amazon Resource Name (ARN) for the key, for example arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab. Key alias - A previously created display name for a key, for example alias/projectKey1. Key alias ARN - An ARN for a key alias, for example arn:aws:kms:us-west-2:444455556666:alias/projectKey1. If you use KmsKeyId, you must set the CreateFileSystemRequest$Encrypted parameter to true. EFS accepts only symmetric KMS keys. You cannot use asymmetric KMS keys with Amazon EFS file systems.
  --throughput-mode: string@throughput-mode-completer # Specifies the throughput mode for the file system. The mode can be bursting, provisioned, or elastic. If you set ThroughputMode to provisioned, you must also set a value for ProvisionedThroughputInMibps. After you create the file system, you can decrease your file system's throughput in Provisioned Throughput mode or change between the throughput modes, with certain time restrictions. For more information, see Specifying throughput with provisioned mode (https://docs.aws.amazon.com/efs/latest/ug/performance.html#provisioned-throughput) in the Amazon EFS User Guide. Default is bursting.
  --provisioned-throughput-in-mibps: float # The throughput, measured in MiB/s, that you want to provision for a file system that you're creating. Valid values are 1-1024. Required if ThroughputMode is set to provisioned. The upper limit for throughput is 1024 MiB/s. To increase this limit, contact Amazon Web Services Support. For more information, see Amazon EFS quotas that you can increase (https://docs.aws.amazon.com/efs/latest/ug/limits.html#soft-limits) in the Amazon EFS User Guide. (format: double)
  --availability-zone-name: string # Used to create a file system that uses One Zone storage classes. It specifies the Amazon Web Services Availability Zone in which to create the file system. Use the format us-east-1a to specify the Availability Zone. For more information about One Zone storage classes, see Using EFS storage classes (https://docs.aws.amazon.com/efs/latest/ug/storage-classes.html) in the Amazon EFS User Guide. One Zone storage classes are not available in all Availability Zones in Amazon Web Services Regions where Amazon EFS is available.
  --backup: oneof<nothing, bool> # Specifies whether automatic backups are enabled on the file system that you are creating. Set the value to true to enable automatic backups. If you are creating a file system that uses One Zone storage classes, automatic backups are enabled by default. For more information, see Automatic backups (https://docs.aws.amazon.com/efs/latest/ug/awsbackup.html#automatic-backups) in the Amazon EFS User Guide. Default is false. However, if you specify an AvailabilityZoneName, the default is true. Backup is not available in all Amazon Web Services Regions where Amazon EFS is available.
  --tags: list # Use to create one or more tags associated with the file system. Each tag is a user-defined key-value pair. Name your file system on creation by including a "Key":"Name","Value":"{value}" key-value pair. Each key must be unique. For more information, see Tagging Amazon Web Services resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference Guide. — item shape: {Key: any, Value: any}
]: any -> record<OwnerId: record, CreationToken: record, FileSystemId: record, FileSystemArn: record, CreationTime: record, LifeCycleState: record, Name: record, NumberOfMountTargets: record, SizeInBytes: record<Value: record, Timestamp: record, ValueInIA: record, ValueInStandard: record>, PerformanceMode: record, Encrypted: record, KmsKeyId: record, ThroughputMode: record, ProvisionedThroughputInMibps: record, AvailabilityZoneName: record, AvailabilityZoneId: record, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-02-01/file-systems" $auth.query)
  let req_body = {"CreationToken": $creation_token, "PerformanceMode": $performance_mode, "Encrypted": $encrypted, "KmsKeyId": $kms_key_id, "ThroughputMode": $throughput_mode, "ProvisionedThroughputInMibps": $provisioned_throughput_in_mibps, "AvailabilityZoneName": $availability_zone_name, "Backup": $backup, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Returns the description of a specific Amazon EFS file system if either the file system CreationToken or the FileSystemId is provided. Otherwise, it returns descriptions of all file systems owned by the caller's Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all file system descriptions, you can optionally specify the MaxItems parameter to limit the number of descriptions in a response. This number is automatically set to 100. If more file system descriptions remain, Amazon EFS returns a NextMarker, an opaque token, in the response. In this case, you should send a subsequent request with the Marker request parameter set to the value of NextMarker. To retrieve a list of your file system descriptions, this operation is used in an iterative process, where DescribeFileSystems is called first without the Marker and then the operation continues to call it with the Marker parameter set to the value of the NextMarker from the previous response until the response has no NextMarker. The order of file systems returned in the response of one DescribeFileSystems call and the order of file systems returned across the responses of a multi-call iteration is unspecified. This operation requires permissions for the elasticfilesystem:DescribeFileSystems action.
#
# GET /2015-02-01/file-systems
# operationId: DescribeFileSystems
export def "2015-02-01-file-systems get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: int # (Optional) Specifies the maximum number of file systems to return in the response (integer). This number is automatically set to 100. The response is paginated at 100 per page if you have more than 100 file systems.
  --marker: string # (Optional) Opaque pagination token returned from a previous DescribeFileSystems operation (String). If present, specifies to continue the list from where the returning call had left off.
  --creation-token: string # (Optional) Restricts the list to the file system with this creation token (String). You specify a creation token when you create an Amazon EFS file system.
  --file-system-id: string # (Optional) ID of the file system whose description you want to retrieve (String).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, FileSystems: record, NextMarker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxItems" $max_items "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "CreationToken" $creation_token "scalar") (serialize-qp "FileSystemId" $file_system_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-02-01/file-systems" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MaxItems": $max_items, "Marker": $marker, "CreationToken": $creation_token, "FileSystemId": $file_system_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a mount target for a file system. You can then mount the file system on EC2 instances by using the mount target. You can create one mount target in each Availability Zone in your VPC. All EC2 instances in a VPC within a given Availability Zone share a single mount target for a given file system. If you have multiple subnets in an Availability Zone, you create a mount target in one of the subnets. EC2 instances do not need to be in the same subnet as the mount target in order to access their file system. You can create only one mount target for an EFS file system using One Zone storage classes. You must create that mount target in the same Availability Zone in which the file system is located. Use the AvailabilityZoneName and AvailabiltyZoneId properties in the DescribeFileSystems response object to get this information. Use the subnetId associated with the file system's Availability Zone when creating the mount target. For more information, see Amazon EFS: How it Works (https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html). To create a mount target for a file system, the file system's lifecycle state must be available. For more information, see DescribeFileSystems. In the request, provide the following: The file system ID for which you are creating the mount target. A subnet ID, which determines the following: The VPC in which Amazon EFS creates the mount target The Availability Zone in which Amazon EFS creates the mount target The IP address range from which Amazon EFS selects the IP address of the mount target (if you don't specify an IP address in the request) After creating the mount target, Amazon EFS returns a response that includes, a MountTargetId and an IpAddress. You use this IP address when mounting the file system in an EC2 instance. You can also use the mount target's DNS name when mounting the file system. The EC2 instance on which you mount the file system by using the mount target can resolve the mount target's DNS name to its IP address. For more information, see How it Works: Implementation Overview (https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html#how-it-works-implementation). Note that you can create mount targets for a file system in only one VPC, and there can be only one mount target per Availability Zone. That is, if the file system already has one or more mount targets created for it, the subnet specified in the request to add another mount target must meet the following requirements: Must belong to the same VPC as the subnets of the existing mount targets Must not be in the same Availability Zone as any of the subnets of the existing mount targets If the request satisfies the requirements, Amazon EFS does the following: Creates a new mount target in the specified subnet. Also creates a new network interface in the subnet as follows: If the request provides an IpAddress, Amazon EFS assigns that IP address to the network interface. Otherwise, Amazon EFS assigns a free address in the subnet (in the same way that the Amazon EC2 CreateNetworkInterface call does when a request does not specify a primary private IP address). If the request provides SecurityGroups, this network interface is associated with those security groups. Otherwise, it belongs to the default security group for the subnet's VPC. Assigns the description Mount target fsmt-id for file system fs-id where fsmt-id is the mount target ID, and fs-id is the FileSystemId. Sets the requesterManaged property of the network interface to true, and the requesterId value to EFS. Each Amazon EFS mount target has one corresponding requester-managed EC2 network interface. After the network interface is created, Amazon EFS sets the NetworkInterfaceId field in the mount target's description to the network interface ID, and the IpAddress field to its address. If network interface creation fails, the entire CreateMountTarget operation fails. The CreateMountTarget call returns only after creating the network interface, but while the mount target state is still creating, you can check the mount target creation status by calling the DescribeMountTargets operation, which among other things returns the mount target state. We recommend that you create a mount target in each of the Availability Zones. There are cost considerations for using a file system in an Availability Zone through a mount target created in another Availability Zone. For more information, see Amazon EFS (http://aws.amazon.com/efs/). In addition, by always using a mount target local to the instance's Availability Zone, you eliminate a partial failure scenario. If the Availability Zone in which your mount target is created goes down, then you can't access your file system through that mount target. This operation requires permissions for the following action on the file system: elasticfilesystem:CreateMountTarget This operation also requires permissions for the following Amazon EC2 actions: ec2:DescribeSubnets ec2:DescribeNetworkInterfaces ec2:CreateNetworkInterface
#
# POST /2015-02-01/mount-targets
# operationId: CreateMountTarget
export def "2015-02-01-mount-targets create" [
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
  file_system_id: string # The ID of the file system for which to create the mount target.
  subnet_id: string # The ID of the subnet to add the mount target in. For file systems that use One Zone storage classes, use the subnet that is associated with the file system's Availability Zone.
  --ip-address: string # Valid IPv4 address within the address range of the specified subnet.
  --security-groups: list<string> # Up to five VPC security group IDs, of the form sg-xxxxxxxx. These must be for the same VPC as subnet specified.
]: any -> record<OwnerId: record, MountTargetId: record, FileSystemId: record, SubnetId: record, LifeCycleState: record, IpAddress: record, NetworkInterfaceId: record, AvailabilityZoneId: record, AvailabilityZoneName: record, VpcId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-02-01/mount-targets" $auth.query)
  let req_body = {"FileSystemId": $file_system_id, "SubnetId": $subnet_id, "IpAddress": $ip_address, "SecurityGroups": $security_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Returns the descriptions of all the current mount targets, or a specific mount target, for a file system. When requesting all of the current mount targets, the order of mount targets returned in the response is unspecified. This operation requires permissions for the elasticfilesystem:DescribeMountTargets action, on either the file system ID that you specify in FileSystemId, or on the file system of the mount target that you specify in MountTargetId.
#
# GET /2015-02-01/mount-targets
# operationId: DescribeMountTargets
export def "2015-02-01-mount-targets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: int # (Optional) Maximum number of mount targets to return in the response. Currently, this number is automatically set to 10, and other values are ignored. The response is paginated at 100 per page if you have more than 100 mount targets.
  --marker: string # (Optional) Opaque pagination token returned from a previous DescribeMountTargets operation (String). If present, it specifies to continue the list from where the previous returning call left off.
  --file-system-id: string # (Optional) ID of the file system whose mount targets you want to list (String). It must be included in your request if an AccessPointId or MountTargetId is not included. Accepts either a file system ID or ARN as input.
  --mount-target-id: string # (Optional) ID of the mount target that you want to have described (String). It must be included in your request if FileSystemId is not included. Accepts either a mount target ID or ARN as input.
  --access-point-id: string # (Optional) The ID of the access point whose mount targets that you want to list. It must be included in your request if a FileSystemId or MountTargetId is not included in your request. Accepts either an access point ID or ARN as input.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, MountTargets: record, NextMarker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxItems" $max_items "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "FileSystemId" $file_system_id "scalar") (serialize-qp "MountTargetId" $mount_target_id "scalar") (serialize-qp "AccessPointId" $access_point_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-02-01/mount-targets" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MaxItems": $max_items, "Marker": $marker, "FileSystemId": $file_system_id, "MountTargetId": $mount_target_id, "AccessPointId": $access_point_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a replication configuration that replicates an existing EFS file system to a new, read-only file system. For more information, see Amazon EFS replication (https://docs.aws.amazon.com/efs/latest/ug/efs-replication.html) in the Amazon EFS User Guide. The replication configuration specifies the following: Source file system - An existing EFS file system that you want replicated. The source file system cannot be a destination file system in an existing replication configuration. Destination file system configuration - The configuration of the destination file system to which the source file system will be replicated. There can only be one destination file system in a replication configuration. The destination file system configuration consists of the following properties: Amazon Web Services Region - The Amazon Web Services Region in which the destination file system is created. Amazon EFS replication is available in all Amazon Web Services Regions that Amazon EFS is available in, except Africa (Cape Town), Asia Pacific (Hong Kong), Asia Pacific (Jakarta), Europe (Milan), and Middle East (Bahrain). Availability Zone - If you want the destination file system to use EFS One Zone availability and durability, you must specify the Availability Zone to create the file system in. For more information about EFS storage classes, see Amazon EFS storage classes (https://docs.aws.amazon.com/efs/latest/ug/storage-classes.html) in the Amazon EFS User Guide. Encryption - All destination file systems are created with encryption at rest enabled. You can specify the Key Management Service (KMS) key that is used to encrypt the destination file system. If you don't specify a KMS key, your service-managed KMS key for Amazon EFS is used. After the file system is created, you cannot change the KMS key. The following properties are set by default: Performance mode - The destination file system's performance mode matches that of the source file system, unless the destination file system uses EFS One Zone storage. In that case, the General Purpose performance mode is used. The performance mode cannot be changed. Throughput mode - The destination file system's throughput mode matches that of the source file system. After the file system is created, you can modify the throughput mode. The following properties are turned off by default: Lifecycle management - EFS lifecycle management and EFS Intelligent-Tiering are not enabled on the destination file system. After the destination file system is created, you can enable EFS lifecycle management and EFS Intelligent-Tiering. Automatic backups - Automatic daily backups not enabled on the destination file system. After the file system is created, you can change this setting. For more information, see Amazon EFS replication (https://docs.aws.amazon.com/efs/latest/ug/efs-replication.html) in the Amazon EFS User Guide.
#
# POST /2015-02-01/file-systems/{SourceFileSystemId}/replication-configuration
# operationId: CreateReplicationConfiguration
# --Destinations item shape: {Region?: any, AvailabilityZoneName?: any, KmsKeyId?: any}
export def "2015-02-01-file-systems-replication-configuration create" [
  source_file_system_id: string
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
  destinations: list # An array of destination configuration objects. Only one destination configuration object is supported. — item shape: {Region?: any, AvailabilityZoneName?: any, KmsKeyId?: any}
]: any -> record<SourceFileSystemId: record, SourceFileSystemRegion: record, SourceFileSystemArn: record, OriginalSourceFileSystemArn: record, CreationTime: record, Destinations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'SourceFileSystemId' must be non-empty" } }
  let full_url = (build-url $base ({source_file_system_id: (encode-path-segment $source_file_system_id)} | format pattern "/2015-02-01/file-systems/{source_file_system_id}/replication-configuration") $auth.query)
  let req_body = {"Destinations": $destinations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Deletes an existing replication configuration. To delete a replication configuration, you must make the request from the Amazon Web Services Region in which the destination file system is located. Deleting a replication configuration ends the replication process. After a replication configuration is deleted, the destination file system is no longer read-only. You can write to the destination file system after its status becomes Writeable.
#
# DELETE /2015-02-01/file-systems/{SourceFileSystemId}/replication-configuration
# operationId: DeleteReplicationConfiguration
export def "2015-02-01-file-systems-replication-configuration delete" [
  source_file_system_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'SourceFileSystemId' must be non-empty" } }
  let full_url = (build-url $base ({source_file_system_id: (encode-path-segment $source_file_system_id)} | format pattern "/2015-02-01/file-systems/{source_file_system_id}/replication-configuration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# DEPRECATED - CreateTags is deprecated and not maintained. To create tags for EFS resources, use the API action. Creates or overwrites tags associated with a file system. Each tag is a key-value pair. If a tag key specified in the request already exists on the file system, this operation overwrites its value with the value provided in the request. If you add the Name tag to your file system, Amazon EFS returns it in the response to the DescribeFileSystems operation. This operation requires permission for the elasticfilesystem:CreateTags action.
#
# POST /2015-02-01/create-tags/{FileSystemId}
# DEPRECATED
# operationId: CreateTags
# --Tags item shape: {Key: any, Value: any}
@deprecated
export def "2015-02-01-create-tags create" [
  file_system_id: string
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
  tags: list # An array of Tag objects to add. Each Tag object is a key-value pair. — item shape: {Key: any, Value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'FileSystemId' must be non-empty" } }
  let full_url = (build-url $base ({file_system_id: (encode-path-segment $file_system_id)} | format pattern "/2015-02-01/create-tags/{file_system_id}") $auth.query)
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Deletes the specified access point. After deletion is complete, new clients can no longer connect to the access points. Clients connected to the access point at the time of deletion will continue to function until they terminate their connection. This operation requires permissions for the elasticfilesystem:DeleteAccessPoint action.
#
# DELETE /2015-02-01/access-points/{AccessPointId}
# operationId: DeleteAccessPoint
export def "2015-02-01-access-points delete" [
  access_point_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_point_id | is-empty) { error make --unspanned { msg: "path parameter 'AccessPointId' must be non-empty" } }
  let full_url = (build-url $base ({access_point_id: (encode-path-segment $access_point_id)} | format pattern "/2015-02-01/access-points/{access_point_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Deletes a file system, permanently severing access to its contents. Upon return, the file system no longer exists and you can't access any contents of the deleted file system. You need to manually delete mount targets attached to a file system before you can delete an EFS file system. This step is performed for you when you use the Amazon Web Services console to delete a file system. You cannot delete a file system that is part of an EFS Replication configuration. You need to delete the replication configuration first. You can't delete a file system that is in use. That is, if the file system has any mount targets, you must first delete them. For more information, see DescribeMountTargets and DeleteMountTarget. The DeleteFileSystem call returns while the file system state is still deleting. You can check the file system deletion status by calling the DescribeFileSystems operation, which returns a list of file systems in your account. If you pass file system ID or creation token for the deleted file system, the DescribeFileSystems returns a 404 FileSystemNotFound error. This operation requires permissions for the elasticfilesystem:DeleteFileSystem action.
#
# DELETE /2015-02-01/file-systems/{FileSystemId}
# operationId: DeleteFileSystem
export def "2015-02-01-file-systems delete" [
  file_system_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'FileSystemId' must be non-empty" } }
  let full_url = (build-url $base ({file_system_id: (encode-path-segment $file_system_id)} | format pattern "/2015-02-01/file-systems/{file_system_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Updates the throughput mode or the amount of provisioned throughput of an existing file system.
#
# PUT /2015-02-01/file-systems/{FileSystemId}
# operationId: UpdateFileSystem
export def "2015-02-01-file-systems update" [
  file_system_id: string
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
  --throughput-mode: string@throughput-mode-completer # (Optional) Updates the file system's throughput mode. If you're not updating your throughput mode, you don't need to provide this value in your request. If you are changing the ThroughputMode to provisioned, you must also set a value for ProvisionedThroughputInMibps.
  --provisioned-throughput-in-mibps: float # (Optional) Sets the amount of provisioned throughput, in MiB/s, for the file system. Valid values are 1-1024. If you are changing the throughput mode to provisioned, you must also provide the amount of provisioned throughput. Required if ThroughputMode is changed to provisioned on update. (format: double)
]: any -> record<OwnerId: record, CreationToken: record, FileSystemId: record, FileSystemArn: record, CreationTime: record, LifeCycleState: record, Name: record, NumberOfMountTargets: record, SizeInBytes: record<Value: record, Timestamp: record, ValueInIA: record, ValueInStandard: record>, PerformanceMode: record, Encrypted: record, KmsKeyId: record, ThroughputMode: record, ProvisionedThroughputInMibps: record, AvailabilityZoneName: record, AvailabilityZoneId: record, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'FileSystemId' must be non-empty" } }
  let full_url = (build-url $base ({file_system_id: (encode-path-segment $file_system_id)} | format pattern "/2015-02-01/file-systems/{file_system_id}") $auth.query)
  let req_body = {"ThroughputMode": $throughput_mode, "ProvisionedThroughputInMibps": $provisioned_throughput_in_mibps} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Deletes the FileSystemPolicy for the specified file system. The default FileSystemPolicy goes into effect once the existing policy is deleted. For more information about the default file system policy, see Using Resource-based Policies with EFS (https://docs.aws.amazon.com/efs/latest/ug/res-based-policies-efs.html). This operation requires permissions for the elasticfilesystem:DeleteFileSystemPolicy action.
#
# DELETE /2015-02-01/file-systems/{FileSystemId}/policy
# operationId: DeleteFileSystemPolicy
export def "2015-02-01-file-systems-policy delete" [
  file_system_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'FileSystemId' must be non-empty" } }
  let full_url = (build-url $base ({file_system_id: (encode-path-segment $file_system_id)} | format pattern "/2015-02-01/file-systems/{file_system_id}/policy") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns the FileSystemPolicy for the specified EFS file system. This operation requires permissions for the elasticfilesystem:DescribeFileSystemPolicy action.
#
# GET /2015-02-01/file-systems/{FileSystemId}/policy
# operationId: DescribeFileSystemPolicy
export def "2015-02-01-file-systems-policy get" [
  file_system_id: string
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
]: nothing -> record<FileSystemId: record, Policy: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'FileSystemId' must be non-empty" } }
  let full_url = (build-url $base ({file_system_id: (encode-path-segment $file_system_id)} | format pattern "/2015-02-01/file-systems/{file_system_id}/policy") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Applies an Amazon EFS FileSystemPolicy to an Amazon EFS file system. A file system policy is an IAM resource-based policy and can contain multiple policy statements. A file system always has exactly one file system policy, which can be the default policy or an explicit policy set or updated using this API operation. EFS file system policies have a 20,000 character limit. When an explicit policy is set, it overrides the default policy. For more information about the default file system policy, see Default EFS File System Policy (https://docs.aws.amazon.com/efs/latest/ug/iam-access-control-nfs-efs.html#default-filesystempolicy). EFS file system policies have a 20,000 character limit. This operation requires permissions for the elasticfilesystem:PutFileSystemPolicy action.
#
# PUT /2015-02-01/file-systems/{FileSystemId}/policy
# operationId: PutFileSystemPolicy
export def "2015-02-01-file-systems-policy update" [
  file_system_id: string
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
  policy: string # The FileSystemPolicy that you're creating. Accepts a JSON formatted policy definition. EFS file system policies have a 20,000 character limit. To find out more about the elements that make up a file system policy, see EFS Resource-based Policies (https://docs.aws.amazon.com/efs/latest/ug/access-control-overview.html#access-control-manage-access-intro-resource-policies).
  --bypass-policy-lockout-safety-check: oneof<nothing, bool> # (Optional) A boolean that specifies whether or not to bypass the FileSystemPolicy lockout safety check. The lockout safety check determines whether the policy in the request will lock out, or prevent, the IAM principal that is making the request from making future PutFileSystemPolicy requests on this file system. Set BypassPolicyLockoutSafetyCheck to True only when you intend to prevent the IAM principal that is making the request from making subsequent PutFileSystemPolicy requests on this file system. The default value is False.
]: any -> record<FileSystemId: record, Policy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'FileSystemId' must be non-empty" } }
  let full_url = (build-url $base ({file_system_id: (encode-path-segment $file_system_id)} | format pattern "/2015-02-01/file-systems/{file_system_id}/policy") $auth.query)
  let req_body = {"Policy": $policy, "BypassPolicyLockoutSafetyCheck": $bypass_policy_lockout_safety_check} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the specified mount target. This operation forcibly breaks any mounts of the file system by using the mount target that is being deleted, which might disrupt instances or applications using those mounts. To avoid applications getting cut off abruptly, you might consider unmounting any mounts of the mount target, if feasible. The operation also deletes the associated network interface. Uncommitted writes might be lost, but breaking a mount target using this operation does not corrupt the file system itself. The file system you created remains. You can mount an EC2 instance in your VPC by using another mount target. This operation requires permissions for the following action on the file system: elasticfilesystem:DeleteMountTarget The DeleteMountTarget call returns while the mount target state is still deleting. You can check the mount target deletion by calling the DescribeMountTargets operation, which returns a list of mount target descriptions for the given file system. The operation also requires permissions for the following Amazon EC2 action on the mount target's network interface: ec2:DeleteNetworkInterface
#
# DELETE /2015-02-01/mount-targets/{MountTargetId}
# operationId: DeleteMountTarget
export def "2015-02-01-mount-targets delete" [
  mount_target_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mount_target_id | is-empty) { error make --unspanned { msg: "path parameter 'MountTargetId' must be non-empty" } }
  let full_url = (build-url $base ({mount_target_id: (encode-path-segment $mount_target_id)} | format pattern "/2015-02-01/mount-targets/{mount_target_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# DEPRECATED - DeleteTags is deprecated and not maintained. To remove tags from EFS resources, use the API action. Deletes the specified tags from a file system. If the DeleteTags request includes a tag key that doesn't exist, Amazon EFS ignores it and doesn't cause an error. For more information about tags and related restrictions, see Tag restrictions (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html) in the Billing and Cost Management User Guide. This operation requires permissions for the elasticfilesystem:DeleteTags action.
#
# POST /2015-02-01/delete-tags/{FileSystemId}
# DEPRECATED
# operationId: DeleteTags
@deprecated
export def "2015-02-01-delete-tags delete" [
  file_system_id: string
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
  tag_keys: list<string> # A list of tag keys to delete.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'FileSystemId' must be non-empty" } }
  let full_url = (build-url $base ({file_system_id: (encode-path-segment $file_system_id)} | format pattern "/2015-02-01/delete-tags/{file_system_id}") $auth.query)
  let req_body = {"TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns the account preferences settings for the Amazon Web Services account associated with the user making the request, in the current Amazon Web Services Region. For more information, see Managing Amazon EFS resource IDs (efs/latest/ug/manage-efs-resource-ids.html).
#
# GET /2015-02-01/account-preferences
# operationId: DescribeAccountPreferences
export def "2015-02-01-account-preferences get" [
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
]: nothing -> record<ResourceIdPreference: record<ResourceIdType: record, Resources: record>, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-02-01/account-preferences" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Use this operation to set the account preference in the current Amazon Web Services Region to use long 17 character (63 bit) or short 8 character (32 bit) resource IDs for new EFS file system and mount target resources. All existing resource IDs are not affected by any changes you make. You can set the ID preference during the opt-in period as EFS transitions to long resource IDs. For more information, see Managing Amazon EFS resource IDs (https://docs.aws.amazon.com/efs/latest/ug/manage-efs-resource-ids.html). Starting in October, 2021, you will receive an error if you try to set the account preference to use the short 8 character format resource ID. Contact Amazon Web Services support if you receive an error and must use short IDs for file system and mount target resources.
#
# PUT /2015-02-01/account-preferences
# operationId: PutAccountPreferences
export def "2015-02-01-account-preferences update" [
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
  resource_id_type: string@resource-id-type-completer # A preference indicating a choice to use 63bit/32bit IDs for all applicable resources.
]: any -> record<ResourceIdPreference: record<ResourceIdType: record, Resources: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2015-02-01/account-preferences" $auth.query)
  let req_body = {"ResourceIdType": $resource_id_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the backup policy for the specified EFS file system.
#
# GET /2015-02-01/file-systems/{FileSystemId}/backup-policy
# operationId: DescribeBackupPolicy
export def "2015-02-01-file-systems-backup-policy get" [
  file_system_id: string
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
]: nothing -> record<BackupPolicy: record<Status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'FileSystemId' must be non-empty" } }
  let full_url = (build-url $base ({file_system_id: (encode-path-segment $file_system_id)} | format pattern "/2015-02-01/file-systems/{file_system_id}/backup-policy") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates the file system's backup policy. Use this action to start or stop automatic backups of the file system.
#
# PUT /2015-02-01/file-systems/{FileSystemId}/backup-policy
# operationId: PutBackupPolicy
# --BackupPolicy shape: {Status?: any}
export def "2015-02-01-file-systems-backup-policy update" [
  file_system_id: string
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
  backup_policy: record # The backup policy for the file system used to create automatic daily backups. If status has a value of ENABLED, the file system is being automatically backed up. For more information, see Automatic backups (https://docs.aws.amazon.com/efs/latest/ug/awsbackup.html#automatic-backups). — shape: {Status?: any}
]: any -> record<BackupPolicy: record<Status: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'FileSystemId' must be non-empty" } }
  let full_url = (build-url $base ({file_system_id: (encode-path-segment $file_system_id)} | format pattern "/2015-02-01/file-systems/{file_system_id}/backup-policy") $auth.query)
  let req_body = {"BackupPolicy": $backup_policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the current LifecycleConfiguration object for the specified Amazon EFS file system. EFS lifecycle management uses the LifecycleConfiguration object to identify which files to move to the EFS Infrequent Access (IA) storage class. For a file system without a LifecycleConfiguration object, the call returns an empty array in the response. When EFS Intelligent-Tiering is enabled, TransitionToPrimaryStorageClass has a value of AFTER_1_ACCESS. This operation requires permissions for the elasticfilesystem:DescribeLifecycleConfiguration operation.
#
# GET /2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration
# operationId: DescribeLifecycleConfiguration
export def "2015-02-01-file-systems-lifecycle-configuration get" [
  file_system_id: string
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
]: nothing -> record<LifecyclePolicies: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'FileSystemId' must be non-empty" } }
  let full_url = (build-url $base ({file_system_id: (encode-path-segment $file_system_id)} | format pattern "/2015-02-01/file-systems/{file_system_id}/lifecycle-configuration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Use this action to manage EFS lifecycle management and EFS Intelligent-Tiering. A LifecycleConfiguration consists of one or more LifecyclePolicy objects that define the following: EFS Lifecycle management - When Amazon EFS automatically transitions files in a file system into the lower-cost EFS Infrequent Access (IA) storage class. To enable EFS Lifecycle management, set the value of TransitionToIA to one of the available options. EFS Intelligent-Tiering - When Amazon EFS automatically transitions files from IA back into the file system's primary storage class (EFS Standard or EFS One Zone Standard). To enable EFS Intelligent-Tiering, set the value of TransitionToPrimaryStorageClass to AFTER_1_ACCESS. For more information, see EFS Lifecycle Management (https://docs.aws.amazon.com/efs/latest/ug/lifecycle-management-efs.html). Each Amazon EFS file system supports one lifecycle configuration, which applies to all files in the file system. If a LifecycleConfiguration object already exists for the specified file system, a PutLifecycleConfiguration call modifies the existing configuration. A PutLifecycleConfiguration call with an empty LifecyclePolicies array in the request body deletes any existing LifecycleConfiguration and turns off lifecycle management and EFS Intelligent-Tiering for the file system. In the request, specify the following: The ID for the file system for which you are enabling, disabling, or modifying lifecycle management and EFS Intelligent-Tiering. A LifecyclePolicies array of LifecyclePolicy objects that define when files are moved into IA storage, and when they are moved back to Standard storage. Amazon EFS requires that each LifecyclePolicy object have only have a single transition, so the LifecyclePolicies array needs to be structured with separate LifecyclePolicy objects. See the example requests in the following section for more information. This operation requires permissions for the elasticfilesystem:PutLifecycleConfiguration operation. To apply a LifecycleConfiguration object to an encrypted file system, you need the same Key Management Service permissions as when you created the encrypted file system.
#
# PUT /2015-02-01/file-systems/{FileSystemId}/lifecycle-configuration
# operationId: PutLifecycleConfiguration
# --LifecyclePolicies item shape: {TransitionToIA?: any, TransitionToPrimaryStorageClass?: any}
export def "2015-02-01-file-systems-lifecycle-configuration update" [
  file_system_id: string
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
  lifecycle_policies: list # An array of LifecyclePolicy objects that define the file system's LifecycleConfiguration object. A LifecycleConfiguration object informs EFS lifecycle management and EFS Intelligent-Tiering of the following: When to move files in the file system from primary storage to the IA storage class. When to move files that are in IA storage to primary storage. When using the put-lifecycle-configuration CLI command or the PutLifecycleConfiguration API action, Amazon EFS requires that each LifecyclePolicy object have only a single transition. This means that in a request body, LifecyclePolicies must be structured as an array of LifecyclePolicy objects, one object for each transition, TransitionToIA, TransitionToPrimaryStorageClass. See the example requests in the following section for more information. — item shape: {TransitionToIA?: any, TransitionToPrimaryStorageClass?: any}
]: any -> record<LifecyclePolicies: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'FileSystemId' must be non-empty" } }
  let full_url = (build-url $base ({file_system_id: (encode-path-segment $file_system_id)} | format pattern "/2015-02-01/file-systems/{file_system_id}/lifecycle-configuration") $auth.query)
  let req_body = {"LifecyclePolicies": $lifecycle_policies} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the security groups currently in effect for a mount target. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not deleted. This operation requires permissions for the following actions: elasticfilesystem:DescribeMountTargetSecurityGroups action on the mount target's file system. ec2:DescribeNetworkInterfaceAttribute action on the mount target's network interface.
#
# GET /2015-02-01/mount-targets/{MountTargetId}/security-groups
# operationId: DescribeMountTargetSecurityGroups
export def "2015-02-01-mount-targets-security-groups get" [
  mount_target_id: string
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
]: nothing -> record<SecurityGroups: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mount_target_id | is-empty) { error make --unspanned { msg: "path parameter 'MountTargetId' must be non-empty" } }
  let full_url = (build-url $base ({mount_target_id: (encode-path-segment $mount_target_id)} | format pattern "/2015-02-01/mount-targets/{mount_target_id}/security-groups") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modifies the set of security groups in effect for a mount target. When you create a mount target, Amazon EFS also creates a new network interface. For more information, see CreateMountTarget. This operation replaces the security groups in effect for the network interface associated with a mount target, with the SecurityGroups provided in the request. This operation requires that the network interface of the mount target has been created and the lifecycle state of the mount target is not deleted. The operation requires permissions for the following actions: elasticfilesystem:ModifyMountTargetSecurityGroups action on the mount target's file system. ec2:ModifyNetworkInterfaceAttribute action on the mount target's network interface.
#
# PUT /2015-02-01/mount-targets/{MountTargetId}/security-groups
# operationId: ModifyMountTargetSecurityGroups
export def "2015-02-01-mount-targets-security-groups update-modify" [
  mount_target_id: string
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
  --security-groups: list<string> # An array of up to five VPC security group IDs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mount_target_id | is-empty) { error make --unspanned { msg: "path parameter 'MountTargetId' must be non-empty" } }
  let full_url = (build-url $base ({mount_target_id: (encode-path-segment $mount_target_id)} | format pattern "/2015-02-01/mount-targets/{mount_target_id}/security-groups") $auth.query)
  let req_body = {"SecurityGroups": $security_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Retrieves the replication configuration for a specific file system. If a file system is not specified, all of the replication configurations for the Amazon Web Services account in an Amazon Web Services Region are retrieved.
#
# GET /2015-02-01/file-systems/replication-configurations
# operationId: DescribeReplicationConfigurations
export def "2015-02-01-file-systems-replication-configurations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-system-id: string # You can retrieve the replication configuration for a specific file system by providing its file system ID.
  --next-token: string # NextToken is present if the response is paginated. You can use NextToken in a subsequent request to fetch the next page of output.
  --max-results: int # (Optional) To limit the number of objects returned in a response, you can specify the MaxItems parameter. The default value is 100.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Replications: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FileSystemId" $file_system_id "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2015-02-01/file-systems/replication-configurations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"FileSystemId": $file_system_id, "NextToken": $next_token, "MaxResults": $max_results} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEPRECATED - The DescribeTags action is deprecated and not maintained. To view tags associated with EFS resources, use the ListTagsForResource API action. Returns the tags associated with a file system. The order of tags returned in the response of one DescribeTags call and the order of tags returned across the responses of a multiple-call iteration (when using pagination) is unspecified. This operation requires permissions for the elasticfilesystem:DescribeTags action.
#
# GET /2015-02-01/tags/{FileSystemId}/
# DEPRECATED
# operationId: DescribeTags
@deprecated
export def "2015-02-01-tags get" [
  file_system_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: int # (Optional) The maximum number of file system tags to return in the response. Currently, this number is automatically set to 100, and other values are ignored. The response is paginated at 100 per page if you have more than 100 tags.
  --marker: string # (Optional) An opaque pagination token returned from a previous DescribeTags operation (String). If present, it specifies to continue the list from where the previous call left off.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Marker: record, Tags: record, NextMarker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_system_id | is-empty) { error make --unspanned { msg: "path parameter 'FileSystemId' must be non-empty" } }
  let qp = [(serialize-qp "MaxItems" $max_items "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_system_id: (encode-path-segment $file_system_id)} | format pattern "/2015-02-01/tags/{file_system_id}/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MaxItems": $max_items, "Marker": $marker} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists all tags for a top-level EFS resource. You must provide the ID of the resource that you want to retrieve the tags for. This operation requires permissions for the elasticfilesystem:DescribeAccessPoints action.
#
# GET /2015-02-01/resource-tags/{ResourceId}
# operationId: ListTagsForResource
export def "2015-02-01-resource-tags list" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # (Optional) Specifies the maximum number of tag objects to return in the response. The default value is 100.
  --next-token: string # (Optional) You can use NextToken in a subsequent request to fetch the next page of access point descriptions if the response payload was paginated.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Tags: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'ResourceId' must be non-empty" } }
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/2015-02-01/resource-tags/{resource_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a tag for an EFS resource. You can create tags for EFS file systems and access points using this API operation. This operation requires permissions for the elasticfilesystem:TagResource action.
#
# POST /2015-02-01/resource-tags/{ResourceId}
# operationId: TagResource
# --Tags item shape: {Key: any, Value: any}
export def "2015-02-01-resource-tags tag" [
  resource_id: string
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
  tags: list # An array of Tag objects to add. Each Tag object is a key-value pair. — item shape: {Key: any, Value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'ResourceId' must be non-empty" } }
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/2015-02-01/resource-tags/{resource_id}") $auth.query)
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Removes tags from an EFS resource. You can remove tags from EFS file systems and access points using this API operation. This operation requires permissions for the elasticfilesystem:UntagResource action.
#
# DELETE /2015-02-01/resource-tags/{ResourceId}
# operationId: UntagResource
export def "2015-02-01-resource-tags untag" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # The keys of the key-value tag pairs that you want to remove from the specified EFS resource.
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
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'ResourceId' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/2015-02-01/resource-tags/{resource_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"tagKeys": $tag_keys} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}
