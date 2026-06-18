# Auto-generated client for Amazon FSx v2018-03-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/fsx/2018-03-01/openapi.json
# Auth: --token flag or $env.AMAZON_FSX_TOKEN

const BASE_URL = "http://fsx.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_FSX_TOKEN | default "" }
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

def base-url-completer [] { ["http://fsx.us-east-1.amazonaws.com" "http://fsx.us-east-2.amazonaws.com" "http://fsx.us-west-1.amazonaws.com" "http://fsx.us-west-2.amazonaws.com" "http://fsx.us-gov-west-1.amazonaws.com" "http://fsx.us-gov-east-1.amazonaws.com" "http://fsx.ca-central-1.amazonaws.com" "http://fsx.eu-north-1.amazonaws.com" "http://fsx.eu-west-1.amazonaws.com" "http://fsx.eu-west-2.amazonaws.com" "http://fsx.eu-west-3.amazonaws.com" "http://fsx.eu-central-1.amazonaws.com" "http://fsx.eu-south-1.amazonaws.com" "http://fsx.af-south-1.amazonaws.com" "http://fsx.ap-northeast-1.amazonaws.com" "http://fsx.ap-northeast-2.amazonaws.com" "http://fsx.ap-northeast-3.amazonaws.com" "http://fsx.ap-southeast-1.amazonaws.com" "http://fsx.ap-southeast-2.amazonaws.com" "http://fsx.ap-east-1.amazonaws.com" "http://fsx.ap-south-1.amazonaws.com" "http://fsx.sa-east-1.amazonaws.com" "http://fsx.me-south-1.amazonaws.com" "https://fsx.us-east-1.amazonaws.com" "https://fsx.us-east-2.amazonaws.com" "https://fsx.us-west-1.amazonaws.com" "https://fsx.us-west-2.amazonaws.com" "https://fsx.us-gov-west-1.amazonaws.com" "https://fsx.us-gov-east-1.amazonaws.com" "https://fsx.ca-central-1.amazonaws.com" "https://fsx.eu-north-1.amazonaws.com" "https://fsx.eu-west-1.amazonaws.com" "https://fsx.eu-west-2.amazonaws.com" "https://fsx.eu-west-3.amazonaws.com" "https://fsx.eu-central-1.amazonaws.com" "https://fsx.eu-south-1.amazonaws.com" "https://fsx.af-south-1.amazonaws.com" "https://fsx.ap-northeast-1.amazonaws.com" "https://fsx.ap-northeast-2.amazonaws.com" "https://fsx.ap-northeast-3.amazonaws.com" "https://fsx.ap-southeast-1.amazonaws.com" "https://fsx.ap-southeast-2.amazonaws.com" "https://fsx.ap-east-1.amazonaws.com" "https://fsx.ap-south-1.amazonaws.com" "https://fsx.sa-east-1.amazonaws.com" "https://fsx.me-south-1.amazonaws.com" "http://fsx.cn-north-1.amazonaws.com.cn" "http://fsx.cn-northwest-1.amazonaws.com.cn" "https://fsx.cn-north-1.amazonaws.com.cn" "https://fsx.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSSimbaAPIService_v20180301.AssociateFileSystemAliases"] }
def x-amz-target-completer-1 [] { ["AWSSimbaAPIService_v20180301.CancelDataRepositoryTask"] }
def x-amz-target-completer-2 [] { ["AWSSimbaAPIService_v20180301.CopyBackup"] }
def x-amz-target-completer-3 [] { ["AWSSimbaAPIService_v20180301.CreateBackup"] }
def x-amz-target-completer-4 [] { ["AWSSimbaAPIService_v20180301.CreateDataRepositoryAssociation"] }
def x-amz-target-completer-5 [] { ["AWSSimbaAPIService_v20180301.CreateDataRepositoryTask"] }
def x-amz-target-completer-6 [] { ["AWSSimbaAPIService_v20180301.CreateFileCache"] }
def x-amz-target-completer-7 [] { ["AWSSimbaAPIService_v20180301.CreateFileSystem"] }
def x-amz-target-completer-8 [] { ["AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup"] }
def x-amz-target-completer-9 [] { ["AWSSimbaAPIService_v20180301.CreateSnapshot"] }
def x-amz-target-completer-10 [] { ["AWSSimbaAPIService_v20180301.CreateStorageVirtualMachine"] }
def x-amz-target-completer-11 [] { ["AWSSimbaAPIService_v20180301.CreateVolume"] }
def x-amz-target-completer-12 [] { ["AWSSimbaAPIService_v20180301.CreateVolumeFromBackup"] }
def x-amz-target-completer-13 [] { ["AWSSimbaAPIService_v20180301.DeleteBackup"] }
def x-amz-target-completer-14 [] { ["AWSSimbaAPIService_v20180301.DeleteDataRepositoryAssociation"] }
def x-amz-target-completer-15 [] { ["AWSSimbaAPIService_v20180301.DeleteFileCache"] }
def x-amz-target-completer-16 [] { ["AWSSimbaAPIService_v20180301.DeleteFileSystem"] }
def x-amz-target-completer-17 [] { ["AWSSimbaAPIService_v20180301.DeleteSnapshot"] }
def x-amz-target-completer-18 [] { ["AWSSimbaAPIService_v20180301.DeleteStorageVirtualMachine"] }
def x-amz-target-completer-19 [] { ["AWSSimbaAPIService_v20180301.DeleteVolume"] }
def x-amz-target-completer-20 [] { ["AWSSimbaAPIService_v20180301.DescribeBackups"] }
def x-amz-target-completer-21 [] { ["AWSSimbaAPIService_v20180301.DescribeDataRepositoryAssociations"] }
def x-amz-target-completer-22 [] { ["AWSSimbaAPIService_v20180301.DescribeDataRepositoryTasks"] }
def x-amz-target-completer-23 [] { ["AWSSimbaAPIService_v20180301.DescribeFileCaches"] }
def x-amz-target-completer-24 [] { ["AWSSimbaAPIService_v20180301.DescribeFileSystemAliases"] }
def x-amz-target-completer-25 [] { ["AWSSimbaAPIService_v20180301.DescribeFileSystems"] }
def x-amz-target-completer-26 [] { ["AWSSimbaAPIService_v20180301.DescribeSnapshots"] }
def x-amz-target-completer-27 [] { ["AWSSimbaAPIService_v20180301.DescribeStorageVirtualMachines"] }
def x-amz-target-completer-28 [] { ["AWSSimbaAPIService_v20180301.DescribeVolumes"] }
def x-amz-target-completer-29 [] { ["AWSSimbaAPIService_v20180301.DisassociateFileSystemAliases"] }
def x-amz-target-completer-30 [] { ["AWSSimbaAPIService_v20180301.ListTagsForResource"] }
def x-amz-target-completer-31 [] { ["AWSSimbaAPIService_v20180301.ReleaseFileSystemNfsV3Locks"] }
def x-amz-target-completer-32 [] { ["AWSSimbaAPIService_v20180301.RestoreVolumeFromSnapshot"] }
def x-amz-target-completer-33 [] { ["AWSSimbaAPIService_v20180301.TagResource"] }
def x-amz-target-completer-34 [] { ["AWSSimbaAPIService_v20180301.UntagResource"] }
def x-amz-target-completer-35 [] { ["AWSSimbaAPIService_v20180301.UpdateDataRepositoryAssociation"] }
def x-amz-target-completer-36 [] { ["AWSSimbaAPIService_v20180301.UpdateFileCache"] }
def x-amz-target-completer-37 [] { ["AWSSimbaAPIService_v20180301.UpdateFileSystem"] }
def x-amz-target-completer-38 [] { ["AWSSimbaAPIService_v20180301.UpdateSnapshot"] }
def x-amz-target-completer-39 [] { ["AWSSimbaAPIService_v20180301.UpdateStorageVirtualMachine"] }
def x-amz-target-completer-40 [] { ["AWSSimbaAPIService_v20180301.UpdateVolume"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-aws-simba-api-service-v20180301-associate-file-system-aliases create" } } | get name | first)
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

# Use this action to associate one or more Domain Name Server (DNS) aliases with an existing Amazon FSx for Windows File Server file system. A file system can have a maximum of 50 DNS aliases associated with it at any one time. If you try to associate a DNS alias that is already associated with the file system, FSx takes no action on that alias in the request. For more information, see Working with DNS Aliases (https://docs.aws.amazon.com/fsx/latest/WindowsGuide/managing-dns-aliases.html) and Walkthrough 5: Using DNS aliases to access your file system (https://docs.aws.amazon.com/fsx/latest/WindowsGuide/walkthrough05-file-system-custom-CNAME.html), including additional steps you must take to be able to access your file system using a DNS alias. The system response shows the DNS aliases that Amazon FSx is attempting to associate with the file system. Use the API operation to monitor the status of the aliases Amazon FSx is associating with the file system.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.AssociateFileSystemAliases
# operationId: AssociateFileSystemAliases
export def "x-amz-target-aws-simba-api-service-v20180301-associate-file-system-aliases create" [
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
  --x-amz-target: string@x-amz-target-completer
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_id: any
  aliases: any
]: any -> record<Aliases: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.AssociateFileSystemAliases")
  let req_body = {"ClientRequestToken": $client_request_token, "FileSystemId": $file_system_id, "Aliases": $aliases} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Cancels an existing Amazon FSx for Lustre data repository task if that task is in either the PENDING or EXECUTING state. When you cancel a task, Amazon FSx does the following. Any files that FSx has already exported are not reverted. FSx continues to export any files that are "in-flight" when the cancel operation is received. FSx does not export any files that have not yet been exported.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CancelDataRepositoryTask
# operationId: CancelDataRepositoryTask
export def "x-amz-target-aws-simba-api-service-v20180301-cancel-data-repository-task cancel" [
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
  --x-amz-target: string@x-amz-target-completer-1
  task_id: any
]: any -> record<Lifecycle: record, TaskId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CancelDataRepositoryTask")
  let req_body = {"TaskId": $task_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Copies an existing backup within the same Amazon Web Services account to another Amazon Web Services Region (cross-Region copy) or within the same Amazon Web Services Region (in-Region copy). You can have up to five backup copy requests in progress to a single destination Region per account. You can use cross-Region backup copies for cross-Region disaster recovery. You can periodically take backups and copy them to another Region so that in the event of a disaster in the primary Region, you can restore from backup and recover availability quickly in the other Region. You can make cross-Region copies only within your Amazon Web Services partition. A partition is a grouping of Regions. Amazon Web Services currently has three partitions: aws (Standard Regions), aws-cn (China Regions), and aws-us-gov (Amazon Web Services GovCloud [US] Regions). You can also use backup copies to clone your file dataset to another Region or within the same Region. You can use the SourceRegion parameter to specify the Amazon Web Services Region from which the backup will be copied. For example, if you make the call from the us-west-1 Region and want to copy a backup from the us-east-2 Region, you specify us-east-2 in the SourceRegion parameter to make a cross-Region copy. If you don't specify a Region, the backup copy is created in the same Region where the request is sent from (in-Region copy). For more information about creating backup copies, see Copying backups (https://docs.aws.amazon.com/fsx/latest/WindowsGuide/using-backups.html#copy-backups) in the Amazon FSx for Windows User Guide, Copying backups (https://docs.aws.amazon.com/fsx/latest/LustreGuide/using-backups-fsx.html#copy-backups) in the Amazon FSx for Lustre User Guide, and Copying backups (https://docs.aws.amazon.com/fsx/latest/OpenZFSGuide/using-backups.html#copy-backups) in the Amazon FSx for OpenZFS User Guide.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CopyBackup
# operationId: CopyBackup
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-copy-backup copy" [
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
  --x-amz-target: string@x-amz-target-completer-2
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  source_backup_id: any
  --source-region: any
  --kms-key-id: string # Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows: Amazon FSx for Lustre PERSISTENT_1 and PERSISTENT_2 deployment types only. SCRATCH_1 and SCRATCH_2 types are encrypted using the Amazon FSx service KMS key for your account. Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server If a KmsKeyId isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see Encrypt (https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html) in the Key Management Service API Reference.
  --copy-tags: any
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
]: any -> record<Backup: record<BackupId: record, Lifecycle: record, FailureDetails: record<Message: record>, Type: record, ProgressPercent: int, CreationTime: record, KmsKeyId: record, ResourceARN: record, Tags: record, FileSystem: record<OwnerId: record, CreationTime: record, FileSystemId: record, FileSystemType: record, Lifecycle: record, FailureDetails: record, StorageCapacity: record, StorageType: record, VpcId: record, SubnetIds: record, NetworkInterfaceIds: record, DNSName: record, KmsKeyId: record, ResourceARN: record, Tags: record, WindowsConfiguration: record, LustreConfiguration: record, AdministrativeActions: record, OntapConfiguration: record, FileSystemTypeVersion: record, OpenZFSConfiguration: record>, DirectoryInformation: record<DomainName: record, ActiveDirectoryId: record, ResourceARN: string>, OwnerId: string, SourceBackupId: string, SourceBackupRegion: record, ResourceType: record, Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: record, Name: record, OntapConfiguration: record, ResourceARN: string, Tags: list, VolumeId: record, VolumeType: record, LifecycleTransitionReason: record, AdministrativeActions: record, OpenZFSConfiguration: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CopyBackup")
  let req_body = {"ClientRequestToken": $client_request_token, "SourceBackupId": $source_backup_id, "SourceRegion": $source_region, "KmsKeyId": $kms_key_id, "CopyTags": $copy_tags, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a backup of an existing Amazon FSx for Windows File Server file system, Amazon FSx for Lustre file system, Amazon FSx for NetApp ONTAP volume, or Amazon FSx for OpenZFS file system. We recommend creating regular backups so that you can restore a file system or volume from a backup if an issue arises with the original file system or volume. For Amazon FSx for Lustre file systems, you can create a backup only for file systems that have the following configuration: A Persistent deployment type Are not linked to a data repository For more information about backups, see the following: For Amazon FSx for Lustre, see Working with FSx for Lustre backups (https://docs.aws.amazon.com/fsx/latest/LustreGuide/using-backups-fsx.html). For Amazon FSx for Windows, see Working with FSx for Windows backups (https://docs.aws.amazon.com/fsx/latest/WindowsGuide/using-backups.html). For Amazon FSx for NetApp ONTAP, see Working with FSx for NetApp ONTAP backups (https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/using-backups.html). For Amazon FSx for OpenZFS, see Working with FSx for OpenZFS backups (https://docs.aws.amazon.com/fsx/latest/OpenZFSGuide/using-backups.html). If a backup with the specified client request token exists and the parameters match, this operation returns the description of the existing backup. If a backup with the specified client request token exists and the parameters don't match, this operation returns IncompatibleParameterError. If a backup with the specified client request token doesn't exist, CreateBackup does the following: Creates a new Amazon FSx backup with an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the backup. By using the idempotent operation, you can retry a CreateBackup operation without the risk of creating an extra backup. This approach can be useful when an initial call fails in a way that makes it unclear whether a backup was created. If you use the same client request token and the initial call created a backup, the operation returns a successful result because all the parameters are the same. The CreateBackup operation returns while the backup's lifecycle state is still CREATING. You can check the backup creation status by calling the DescribeBackups (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeBackups.html) operation, which returns the backup state along with other information.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateBackup
# operationId: CreateBackup
export def "x-amz-target-aws-simba-api-service-v20180301-create-backup create" [
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
  --x-amz-target: string@x-amz-target-completer-3
  --file-system-id: any
  --client-request-token: any
  --tags: any
  --volume-id: any
]: any -> record<Backup: record<BackupId: record, Lifecycle: record, FailureDetails: record<Message: record>, Type: record, ProgressPercent: int, CreationTime: record, KmsKeyId: record, ResourceARN: record, Tags: record, FileSystem: record<OwnerId: record, CreationTime: record, FileSystemId: record, FileSystemType: record, Lifecycle: record, FailureDetails: record, StorageCapacity: record, StorageType: record, VpcId: record, SubnetIds: record, NetworkInterfaceIds: record, DNSName: record, KmsKeyId: record, ResourceARN: record, Tags: record, WindowsConfiguration: record, LustreConfiguration: record, AdministrativeActions: record, OntapConfiguration: record, FileSystemTypeVersion: record, OpenZFSConfiguration: record>, DirectoryInformation: record<DomainName: record, ActiveDirectoryId: record, ResourceARN: string>, OwnerId: string, SourceBackupId: string, SourceBackupRegion: record, ResourceType: record, Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: record, Name: record, OntapConfiguration: record, ResourceARN: string, Tags: list, VolumeId: record, VolumeType: record, LifecycleTransitionReason: record, AdministrativeActions: record, OpenZFSConfiguration: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateBackup")
  let req_body = {"FileSystemId": $file_system_id, "ClientRequestToken": $client_request_token, "Tags": $tags, "VolumeId": $volume_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an Amazon FSx for Lustre data repository association (DRA). A data repository association is a link between a directory on the file system and an Amazon S3 bucket or prefix. You can have a maximum of 8 data repository associations on a file system. Data repository associations are supported for all file systems except for Scratch_1 deployment type. Each data repository association must have a unique Amazon FSx file system directory and a unique S3 bucket or prefix associated with it. You can configure a data repository association for automatic import only, for automatic export only, or for both. To learn more about linking a data repository to your file system, see Linking your file system to an S3 bucket (https://docs.aws.amazon.com/fsx/latest/LustreGuide/create-dra-linked-data-repo.html). CreateDataRepositoryAssociation isn't supported on Amazon File Cache resources. To create a DRA on Amazon File Cache, use the CreateFileCache operation.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateDataRepositoryAssociation
# operationId: CreateDataRepositoryAssociation
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-data-repository-association create" [
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
  --x-amz-target: string@x-amz-target-completer-4
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --file-system-path: any
  data_repository_path: any
  --batch-import-meta-data-on-create: any
  --imported-file-chunk-size: any
  --s3: any
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
]: any -> record<Association: record<AssociationId: record, ResourceARN: string, FileSystemId: string, Lifecycle: record, FailureDetails: record<Message: string>, FileSystemPath: record, DataRepositoryPath: record, BatchImportMetaDataOnCreate: record, ImportedFileChunkSize: record, S3: record<AutoImportPolicy: record, AutoExportPolicy: record>, Tags: list<record>, CreationTime: string, FileCacheId: record, FileCachePath: record, DataRepositorySubdirectories: record, NFS: record<Version: record, DnsIps: record, AutoExportPolicy: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateDataRepositoryAssociation")
  let req_body = {"FileSystemId": $file_system_id, "FileSystemPath": $file_system_path, "DataRepositoryPath": $data_repository_path, "BatchImportMetaDataOnCreate": $batch_import_meta_data_on_create, "ImportedFileChunkSize": $imported_file_chunk_size, "S3": $s3, "ClientRequestToken": $client_request_token, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an Amazon FSx for Lustre data repository task. You use data repository tasks to perform bulk operations between your Amazon FSx file system and its linked data repositories. An example of a data repository task is exporting any data and metadata changes, including POSIX metadata, to files, directories, and symbolic links (symlinks) from your FSx file system to a linked data repository. A CreateDataRepositoryTask operation will fail if a data repository is not linked to the FSx file system. To learn more about data repository tasks, see Data Repository Tasks (https://docs.aws.amazon.com/fsx/latest/LustreGuide/data-repository-tasks.html). To learn more about linking a data repository to your file system, see Linking your file system to an S3 bucket (https://docs.aws.amazon.com/fsx/latest/LustreGuide/create-dra-linked-data-repo.html).
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateDataRepositoryTask
# operationId: CreateDataRepositoryTask
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-data-repository-task create" [
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
  --x-amz-target: string@x-amz-target-completer-5
  type: any
  --paths: any
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  report: any
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
  --capacity-to-release: any
]: any -> record<DataRepositoryTask: record<TaskId: record, Lifecycle: record, Type: record, CreationTime: string, StartTime: record, EndTime: record, ResourceARN: string, Tags: list<record>, FileSystemId: record, Paths: record, FailureDetails: record<Message: string>, Status: record<TotalCount: record, SucceededCount: record, FailedCount: record, LastUpdatedTime: record, ReleasedCapacity: record>, Report: record<Enabled: record, Path: record, Format: record, Scope: record>, CapacityToRelease: record, FileCacheId: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateDataRepositoryTask")
  let req_body = {"Type": $type, "Paths": $paths, "FileSystemId": $file_system_id, "Report": $report, "ClientRequestToken": $client_request_token, "Tags": $tags, "CapacityToRelease": $capacity_to_release} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new Amazon File Cache resource. You can use this operation with a client request token in the request that Amazon File Cache uses to ensure idempotent creation. If a cache with the specified client request token exists and the parameters match, CreateFileCache returns the description of the existing cache. If a cache with the specified client request token exists and the parameters don't match, this call returns IncompatibleParameterError. If a file cache with the specified client request token doesn't exist, CreateFileCache does the following: Creates a new, empty Amazon File Cache resourcewith an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the cache in JSON format. The CreateFileCache call returns while the cache's lifecycle state is still CREATING. You can check the cache creation status by calling the DescribeFileCaches (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileCaches.html) operation, which returns the cache state along with other information.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileCache
# operationId: CreateFileCache
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-file-cache create" [
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
  --x-amz-target: string@x-amz-target-completer-6
  --client-request-token: any
  file_cache_type: any
  file_cache_type_version: any
  storage_capacity: any
  subnet_ids: list<string> # A list of subnet IDs that the cache will be accessible from. You can specify only one subnet ID in a call to the CreateFileCache operation.
  --security-group-ids: any
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
  --copy-tags-to-data-repository-associations: any
  --kms-key-id: any
  --lustre-configuration: any
  --data-repository-associations: any
]: any -> record<FileCache: record<OwnerId: string, CreationTime: string, FileCacheId: record, FileCacheType: record, FileCacheTypeVersion: record, Lifecycle: record, FailureDetails: record<Message: record>, StorageCapacity: record, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: record, KmsKeyId: record, ResourceARN: string, Tags: list<record>, CopyTagsToDataRepositoryAssociations: record, LustreConfiguration: record<PerUnitStorageThroughput: record, DeploymentType: record, MountName: record, WeeklyMaintenanceStartTime: string, MetadataConfiguration: record, LogConfiguration: record>, DataRepositoryAssociationIds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileCache")
  let req_body = {"ClientRequestToken": $client_request_token, "FileCacheType": $file_cache_type, "FileCacheTypeVersion": $file_cache_type_version, "StorageCapacity": $storage_capacity, "SubnetIds": $subnet_ids, "SecurityGroupIds": $security_group_ids, "Tags": $tags, "CopyTagsToDataRepositoryAssociations": $copy_tags_to_data_repository_associations, "KmsKeyId": $kms_key_id, "LustreConfiguration": $lustre_configuration, "DataRepositoryAssociations": $data_repository_associations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new, empty Amazon FSx file system. You can create the following supported Amazon FSx file systems using the CreateFileSystem API operation: Amazon FSx for Lustre Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server This operation requires a client request token in the request that Amazon FSx uses to ensure idempotent creation. This means that calling the operation multiple times with the same client request token has no effect. By using the idempotent operation, you can retry a CreateFileSystem operation without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same. If a file system with the specified client request token exists and the parameters match, CreateFileSystem returns the description of the existing file system. If a file system with the specified client request token exists and the parameters don't match, this call returns IncompatibleParameterError. If a file system with the specified client request token doesn't exist, CreateFileSystem does the following: Creates a new, empty Amazon FSx file system with an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the file system in JSON format. The CreateFileSystem call returns while the file system's lifecycle state is still CREATING. You can check the file-system creation status by calling the DescribeFileSystems (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileSystems.html) operation, which returns the file system state along with other information.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystem
# operationId: CreateFileSystem
# --LustreConfiguration shape: {WeeklyMaintenanceStartTime?: any, ImportPath?: any, ExportPath?: any, ImportedFileChunkSize?: any, DeploymentType?: any, AutoImportPolicy?: any, PerUnitStorageThroughput?: any, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: any, DriveCacheType?: any, DataCompressionType?: any, LogConfiguration?: any, RootSquashConfiguration?: any}
# --OntapConfiguration shape: {AutomaticBackupRetentionDays?: int, DailyAutomaticBackupStartTime?: string, DeploymentType: any, EndpointIpAddressRange?: any, FsxAdminPassword?: any, DiskIopsConfiguration?: any, PreferredSubnetId?: any, RouteTableIds?: any, ThroughputCapacity: any, WeeklyMaintenanceStartTime?: string}
export def "x-amz-target-aws-simba-api-service-v20180301-create-file-system create" [
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
  --x-amz-target: string@x-amz-target-completer-7
  --client-request-token: any
  file_system_type: any
  storage_capacity: any
  --storage-type: any
  subnet_ids: any
  --security-group-ids: any
  --tags: any
  --kms-key-id: string # Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows: Amazon FSx for Lustre PERSISTENT_1 and PERSISTENT_2 deployment types only. SCRATCH_1 and SCRATCH_2 types are encrypted using the Amazon FSx service KMS key for your account. Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server If a KmsKeyId isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see Encrypt (https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html) in the Key Management Service API Reference.
  --windows-configuration: any
  --lustre-configuration: record # The Lustre configuration for the file system being created. The following parameters are not supported for file systems with a data repository association created with . AutoImportPolicy ExportPath ImportedChunkSize ImportPath — shape: {WeeklyMaintenanceStartTime?: any, ImportPath?: any, ExportPath?: any, ImportedFileChunkSize?: any, DeploymentType?: any, AutoImportPolicy?: any, PerUnitStorageThroughput?: any, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: any, DriveCacheType?: any, DataCompressionType?: any, LogConfiguration?: any, RootSquashConfiguration?: any}
  --ontap-configuration: record # The ONTAP configuration properties of the FSx for ONTAP file system that you are creating. — shape: {AutomaticBackupRetentionDays?: int, DailyAutomaticBackupStartTime?: string, DeploymentType: any, EndpointIpAddressRange?: any, FsxAdminPassword?: any, DiskIopsConfiguration?: any, PreferredSubnetId?: any, RouteTableIds?: any, ThroughputCapacity: any, WeeklyMaintenanceStartTime?: string}
  --file-system-type-version: any
  --open-zfs-configuration: any
]: any -> record<FileSystem: record<OwnerId: record, CreationTime: record, FileSystemId: record, FileSystemType: record, Lifecycle: record, FailureDetails: record<Message: record>, StorageCapacity: record, StorageType: record, VpcId: record, SubnetIds: record, NetworkInterfaceIds: record, DNSName: record, KmsKeyId: record, ResourceARN: record, Tags: record, WindowsConfiguration: record<ActiveDirectoryId: record, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: record, RemoteAdministrationEndpoint: record, PreferredSubnetId: record, PreferredFileServerIp: record, ThroughputCapacity: record, MaintenanceOperationsInProgress: record, WeeklyMaintenanceStartTime: record, DailyAutomaticBackupStartTime: record, AutomaticBackupRetentionDays: record, CopyTagsToBackups: record, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: record, DataRepositoryConfiguration: record, DeploymentType: record, PerUnitStorageThroughput: record, MountName: record, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, DriveCacheType: record, DataCompressionType: record, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: record, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: record, EndpointIpAddressRange: record, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: record, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: record, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, CopyTagsToVolumes: record, DailyAutomaticBackupStartTime: string, DeploymentType: record, ThroughputCapacity: record, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystem")
  let req_body = {"ClientRequestToken": $client_request_token, "FileSystemType": $file_system_type, "StorageCapacity": $storage_capacity, "StorageType": $storage_type, "SubnetIds": $subnet_ids, "SecurityGroupIds": $security_group_ids, "Tags": $tags, "KmsKeyId": $kms_key_id, "WindowsConfiguration": $windows_configuration, "LustreConfiguration": $lustre_configuration, "OntapConfiguration": $ontap_configuration, "FileSystemTypeVersion": $file_system_type_version, "OpenZFSConfiguration": $open_zfs_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new Amazon FSx for Lustre, Amazon FSx for Windows File Server, or Amazon FSx for OpenZFS file system from an existing Amazon FSx backup. If a file system with the specified client request token exists and the parameters match, this operation returns the description of the file system. If a file system with the specified client request token exists but the parameters don't match, this call returns IncompatibleParameterError. If a file system with the specified client request token doesn't exist, this operation does the following: Creates a new Amazon FSx file system from backup with an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the file system. Parameters like the Active Directory, default share name, automatic backup, and backup settings default to the parameters of the file system that was backed up, unless overridden. You can explicitly supply other settings. By using the idempotent operation, you can retry a CreateFileSystemFromBackup call without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives a success message as long as the parameters are the same. The CreateFileSystemFromBackup call returns while the file system's lifecycle state is still CREATING. You can check the file-system creation status by calling the DescribeFileSystems (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileSystems.html) operation, which returns the file system state along with other information.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup
# operationId: CreateFileSystemFromBackup
# --LustreConfiguration shape: {WeeklyMaintenanceStartTime?: any, ImportPath?: any, ExportPath?: any, ImportedFileChunkSize?: any, DeploymentType?: any, AutoImportPolicy?: any, PerUnitStorageThroughput?: any, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: any, DriveCacheType?: any, DataCompressionType?: any, LogConfiguration?: any, RootSquashConfiguration?: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-file-system-from-backup create" [
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
  --x-amz-target: string@x-amz-target-completer-8
  backup_id: string # The ID of the source backup. Specifies the backup that you are copying.
  --client-request-token: any
  subnet_ids: any
  --security-group-ids: any
  --tags: any
  --windows-configuration: any
  --lustre-configuration: record # The Lustre configuration for the file system being created. The following parameters are not supported for file systems with a data repository association created with . AutoImportPolicy ExportPath ImportedChunkSize ImportPath — shape: {WeeklyMaintenanceStartTime?: any, ImportPath?: any, ExportPath?: any, ImportedFileChunkSize?: any, DeploymentType?: any, AutoImportPolicy?: any, PerUnitStorageThroughput?: any, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: any, DriveCacheType?: any, DataCompressionType?: any, LogConfiguration?: any, RootSquashConfiguration?: any}
  --storage-type: any
  --kms-key-id: string # Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows: Amazon FSx for Lustre PERSISTENT_1 and PERSISTENT_2 deployment types only. SCRATCH_1 and SCRATCH_2 types are encrypted using the Amazon FSx service KMS key for your account. Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server If a KmsKeyId isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see Encrypt (https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html) in the Key Management Service API Reference.
  --file-system-type-version: any
  --open-zfs-configuration: any
  --storage-capacity: any
]: any -> record<FileSystem: record<OwnerId: record, CreationTime: record, FileSystemId: record, FileSystemType: record, Lifecycle: record, FailureDetails: record<Message: record>, StorageCapacity: record, StorageType: record, VpcId: record, SubnetIds: record, NetworkInterfaceIds: record, DNSName: record, KmsKeyId: record, ResourceARN: record, Tags: record, WindowsConfiguration: record<ActiveDirectoryId: record, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: record, RemoteAdministrationEndpoint: record, PreferredSubnetId: record, PreferredFileServerIp: record, ThroughputCapacity: record, MaintenanceOperationsInProgress: record, WeeklyMaintenanceStartTime: record, DailyAutomaticBackupStartTime: record, AutomaticBackupRetentionDays: record, CopyTagsToBackups: record, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: record, DataRepositoryConfiguration: record, DeploymentType: record, PerUnitStorageThroughput: record, MountName: record, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, DriveCacheType: record, DataCompressionType: record, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: record, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: record, EndpointIpAddressRange: record, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: record, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: record, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, CopyTagsToVolumes: record, DailyAutomaticBackupStartTime: string, DeploymentType: record, ThroughputCapacity: record, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup")
  let req_body = {"BackupId": $backup_id, "ClientRequestToken": $client_request_token, "SubnetIds": $subnet_ids, "SecurityGroupIds": $security_group_ids, "Tags": $tags, "WindowsConfiguration": $windows_configuration, "LustreConfiguration": $lustre_configuration, "StorageType": $storage_type, "KmsKeyId": $kms_key_id, "FileSystemTypeVersion": $file_system_type_version, "OpenZFSConfiguration": $open_zfs_configuration, "StorageCapacity": $storage_capacity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a snapshot of an existing Amazon FSx for OpenZFS volume. With snapshots, you can easily undo file changes and compare file versions by restoring the volume to a previous version. If a snapshot with the specified client request token exists, and the parameters match, this operation returns the description of the existing snapshot. If a snapshot with the specified client request token exists, and the parameters don't match, this operation returns IncompatibleParameterError. If a snapshot with the specified client request token doesn't exist, CreateSnapshot does the following: Creates a new OpenZFS snapshot with an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the snapshot. By using the idempotent operation, you can retry a CreateSnapshot operation without the risk of creating an extra snapshot. This approach can be useful when an initial call fails in a way that makes it unclear whether a snapshot was created. If you use the same client request token and the initial call created a snapshot, the operation returns a successful result because all the parameters are the same. The CreateSnapshot operation returns while the snapshot's lifecycle state is still CREATING. You can check the snapshot creation status by calling the DescribeSnapshots (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeSnapshots.html) operation, which returns the snapshot state along with other information.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateSnapshot
# operationId: CreateSnapshot
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-snapshot create" [
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
  --x-amz-target: string@x-amz-target-completer-9
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  name: any
  volume_id: any
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
]: any -> record<Snapshot: record<ResourceARN: string, SnapshotId: record, Name: record, VolumeId: record, CreationTime: string, Lifecycle: record, LifecycleTransitionReason: record<Message: string>, Tags: list<record>, AdministrativeActions: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateSnapshot")
  let req_body = {"ClientRequestToken": $client_request_token, "Name": $name, "VolumeId": $volume_id, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a storage virtual machine (SVM) for an Amazon FSx for ONTAP file system.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateStorageVirtualMachine
# operationId: CreateStorageVirtualMachine
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-storage-virtual-machine create" [
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
  --x-amz-target: string@x-amz-target-completer-10
  --active-directory-configuration: any
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  name: any
  --svm-admin-password: any
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
  --root-volume-security-style: any
]: any -> record<StorageVirtualMachine: record<ActiveDirectoryConfiguration: record<NetBiosName: record, SelfManagedActiveDirectoryConfiguration: record>, CreationTime: string, Endpoints: record<Iscsi: record, Management: record, Nfs: record, Smb: record>, FileSystemId: string, Lifecycle: record, Name: record, ResourceARN: string, StorageVirtualMachineId: record, Subtype: record, UUID: record, Tags: list<record>, LifecycleTransitionReason: record<Message: string>, RootVolumeSecurityStyle: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateStorageVirtualMachine")
  let req_body = {"ActiveDirectoryConfiguration": $active_directory_configuration, "ClientRequestToken": $client_request_token, "FileSystemId": $file_system_id, "Name": $name, "SvmAdminPassword": $svm_admin_password, "Tags": $tags, "RootVolumeSecurityStyle": $root_volume_security_style} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an FSx for ONTAP or Amazon FSx for OpenZFS storage volume.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateVolume
# operationId: CreateVolume
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-volume create" [
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
  --x-amz-target: string@x-amz-target-completer-11
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  volume_type: any
  name: any
  --ontap-configuration: any
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
  --open-zfs-configuration: any
]: any -> record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: record, Name: record, OntapConfiguration: record<FlexCacheEndpointType: record, JunctionPath: record, SecurityStyle: record, SizeInMegabytes: record, StorageEfficiencyEnabled: record, StorageVirtualMachineId: record, StorageVirtualMachineRoot: record, TieringPolicy: record, UUID: record, OntapVolumeType: record, SnapshotPolicy: record, CopyTagsToBackups: record>, ResourceARN: string, Tags: list<record>, VolumeId: record, VolumeType: record, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: record, OpenZFSConfiguration: record<ParentVolumeId: record, VolumePath: record, StorageCapacityReservationGiB: record, StorageCapacityQuotaGiB: record, RecordSizeKiB: record, DataCompressionType: record, CopyTagsToSnapshots: record, OriginSnapshot: record, ReadOnly: record, NfsExports: record, UserAndGroupQuotas: record, RestoreToSnapshot: record, DeleteIntermediateSnaphots: record, DeleteClonedVolumes: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateVolume")
  let req_body = {"ClientRequestToken": $client_request_token, "VolumeType": $volume_type, "Name": $name, "OntapConfiguration": $ontap_configuration, "Tags": $tags, "OpenZFSConfiguration": $open_zfs_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new Amazon FSx for NetApp ONTAP volume from an existing Amazon FSx volume backup.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateVolumeFromBackup
# operationId: CreateVolumeFromBackup
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-volume-from-backup create" [
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
  --x-amz-target: string@x-amz-target-completer-12
  backup_id: string # The ID of the source backup. Specifies the backup that you are copying.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  name: any
  --ontap-configuration: any
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
]: any -> record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: record, Name: record, OntapConfiguration: record<FlexCacheEndpointType: record, JunctionPath: record, SecurityStyle: record, SizeInMegabytes: record, StorageEfficiencyEnabled: record, StorageVirtualMachineId: record, StorageVirtualMachineRoot: record, TieringPolicy: record, UUID: record, OntapVolumeType: record, SnapshotPolicy: record, CopyTagsToBackups: record>, ResourceARN: string, Tags: list<record>, VolumeId: record, VolumeType: record, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: record, OpenZFSConfiguration: record<ParentVolumeId: record, VolumePath: record, StorageCapacityReservationGiB: record, StorageCapacityQuotaGiB: record, RecordSizeKiB: record, DataCompressionType: record, CopyTagsToSnapshots: record, OriginSnapshot: record, ReadOnly: record, NfsExports: record, UserAndGroupQuotas: record, RestoreToSnapshot: record, DeleteIntermediateSnaphots: record, DeleteClonedVolumes: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateVolumeFromBackup")
  let req_body = {"BackupId": $backup_id, "ClientRequestToken": $client_request_token, "Name": $name, "OntapConfiguration": $ontap_configuration, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an Amazon FSx backup. After deletion, the backup no longer exists, and its data is gone. The DeleteBackup call returns instantly. The backup won't show up in later DescribeBackups calls. The data in a deleted backup is also deleted and can't be recovered by any means.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteBackup
# operationId: DeleteBackup
export def "x-amz-target-aws-simba-api-service-v20180301-delete-backup delete" [
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
  --x-amz-target: string@x-amz-target-completer-13
  backup_id: any
  --client-request-token: any
]: any -> record<BackupId: record, Lifecycle: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteBackup")
  let req_body = {"BackupId": $backup_id, "ClientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a data repository association on an Amazon FSx for Lustre file system. Deleting the data repository association unlinks the file system from the Amazon S3 bucket. When deleting a data repository association, you have the option of deleting the data in the file system that corresponds to the data repository association. Data repository associations are supported for all file systems except for Scratch_1 deployment type.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteDataRepositoryAssociation
# operationId: DeleteDataRepositoryAssociation
export def "x-amz-target-aws-simba-api-service-v20180301-delete-data-repository-association delete" [
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
  --x-amz-target: string@x-amz-target-completer-14
  association_id: any
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --delete-data-in-file-system: any
]: any -> record<AssociationId: record, Lifecycle: record, DeleteDataInFileSystem: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteDataRepositoryAssociation")
  let req_body = {"AssociationId": $association_id, "ClientRequestToken": $client_request_token, "DeleteDataInFileSystem": $delete_data_in_file_system} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an Amazon File Cache resource. After deletion, the cache no longer exists, and its data is gone. The DeleteFileCache operation returns while the cache has the DELETING status. You can check the cache deletion status by calling the DescribeFileCaches (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileCaches.html) operation, which returns a list of caches in your account. If you pass the cache ID for a deleted cache, the DescribeFileCaches operation returns a FileCacheNotFound error. The data in a deleted cache is also deleted and can't be recovered by any means.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteFileCache
# operationId: DeleteFileCache
export def "x-amz-target-aws-simba-api-service-v20180301-delete-file-cache delete" [
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
  --x-amz-target: string@x-amz-target-completer-15
  file_cache_id: any
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
]: any -> record<FileCacheId: record, Lifecycle: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteFileCache")
  let req_body = {"FileCacheId": $file_cache_id, "ClientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a file system. After deletion, the file system no longer exists, and its data is gone. Any existing automatic backups and snapshots are also deleted. To delete an Amazon FSx for NetApp ONTAP file system, first delete all the volumes and storage virtual machines (SVMs) on the file system. Then provide a FileSystemId value to the DeleFileSystem operation. By default, when you delete an Amazon FSx for Windows File Server file system, a final backup is created upon deletion. This final backup isn't subject to the file system's retention policy, and must be manually deleted. The DeleteFileSystem operation returns while the file system has the DELETING status. You can check the file system deletion status by calling the DescribeFileSystems (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileSystems.html) operation, which returns a list of file systems in your account. If you pass the file system ID for a deleted file system, the DescribeFileSystems operation returns a FileSystemNotFound error. If a data repository task is in a PENDING or EXECUTING state, deleting an Amazon FSx for Lustre file system will fail with an HTTP status code 400 (Bad Request). The data in a deleted file system is also deleted and can't be recovered by any means.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteFileSystem
# operationId: DeleteFileSystem
# --WindowsConfiguration shape: {SkipFinalBackup?: any, FinalBackupTags?: any}
# --LustreConfiguration shape: {SkipFinalBackup?: any, FinalBackupTags?: any}
export def "x-amz-target-aws-simba-api-service-v20180301-delete-file-system delete" [
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
  --x-amz-target: string@x-amz-target-completer-16
  file_system_id: any
  --client-request-token: any
  --windows-configuration: record # The configuration object for the Microsoft Windows file system used in the DeleteFileSystem operation. — shape: {SkipFinalBackup?: any, FinalBackupTags?: any}
  --lustre-configuration: record # The configuration object for the Amazon FSx for Lustre file system being deleted in the DeleteFileSystem operation. — shape: {SkipFinalBackup?: any, FinalBackupTags?: any}
  --open-zfs-configuration: any
]: any -> record<FileSystemId: record, Lifecycle: record, WindowsResponse: record<FinalBackupId: record, FinalBackupTags: record>, LustreResponse: record<FinalBackupId: record, FinalBackupTags: record>, OpenZFSResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteFileSystem")
  let req_body = {"FileSystemId": $file_system_id, "ClientRequestToken": $client_request_token, "WindowsConfiguration": $windows_configuration, "LustreConfiguration": $lustre_configuration, "OpenZFSConfiguration": $open_zfs_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an Amazon FSx for OpenZFS snapshot. After deletion, the snapshot no longer exists, and its data is gone. Deleting a snapshot doesn't affect snapshots stored in a file system backup. The DeleteSnapshot operation returns instantly. The snapshot appears with the lifecycle status of DELETING until the deletion is complete.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteSnapshot
# operationId: DeleteSnapshot
export def "x-amz-target-aws-simba-api-service-v20180301-delete-snapshot delete" [
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
  --x-amz-target: string@x-amz-target-completer-17
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  snapshot_id: any
]: any -> record<SnapshotId: record, Lifecycle: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteSnapshot")
  let req_body = {"ClientRequestToken": $client_request_token, "SnapshotId": $snapshot_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an existing Amazon FSx for ONTAP storage virtual machine (SVM). Prior to deleting an SVM, you must delete all non-root volumes in the SVM, otherwise the operation will fail.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteStorageVirtualMachine
# operationId: DeleteStorageVirtualMachine
export def "x-amz-target-aws-simba-api-service-v20180301-delete-storage-virtual-machine delete" [
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
  --x-amz-target: string@x-amz-target-completer-18
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  storage_virtual_machine_id: any
]: any -> record<StorageVirtualMachineId: record, Lifecycle: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteStorageVirtualMachine")
  let req_body = {"ClientRequestToken": $client_request_token, "StorageVirtualMachineId": $storage_virtual_machine_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an Amazon FSx for NetApp ONTAP or Amazon FSx for OpenZFS volume.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteVolume
# operationId: DeleteVolume
export def "x-amz-target-aws-simba-api-service-v20180301-delete-volume delete" [
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
  --x-amz-target: string@x-amz-target-completer-19
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  volume_id: any
  --ontap-configuration: any
  --open-zfs-configuration: any
]: any -> record<VolumeId: record, Lifecycle: record, OntapResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteVolume")
  let req_body = {"ClientRequestToken": $client_request_token, "VolumeId": $volume_id, "OntapConfiguration": $ontap_configuration, "OpenZFSConfiguration": $open_zfs_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the description of a specific Amazon FSx backup, if a BackupIds value is provided for that backup. Otherwise, it returns all backups owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all backups, you can optionally specify the MaxResults parameter to limit the number of backups in a response. If more backups remain, Amazon FSx returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of the NextToken value from the last response. This operation is used in an iterative process to retrieve a list of your backups. DescribeBackups is called first without a NextToken value. Then the operation continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken value. When using this operation, keep the following in mind: The operation might return fewer than the MaxResults value of backup descriptions while still including a NextToken value. The order of the backups returned in the response of one DescribeBackups call and the order of the backups returned across the responses of a multi-call iteration is unspecified.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeBackups
# operationId: DescribeBackups
export def "x-amz-target-aws-simba-api-service-v20180301-describe-backups get" [
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
  --x-amz-target: string@x-amz-target-completer-20
  --backup-ids: any
  --filters: any
  --max-results: any
  --next-token: any
]: any -> record<Backups: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeBackups" $qp)
  let req_body = {"BackupIds": $backup_ids, "Filters": $filters, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the description of specific Amazon FSx for Lustre or Amazon File Cache data repository associations, if one or more AssociationIds values are provided in the request, or if filters are used in the request. Data repository associations are supported on Amazon File Cache resources and all Amazon FSx for Lustre file systems excluding Scratch_1 deployment types. You can use filters to narrow the response to include just data repository associations for specific file systems (use the file-system-id filter with the ID of the file system) or caches (use the file-cache-id filter with the ID of the cache), or data repository associations for a specific repository type (use the data-repository-type filter with a value of S3 or NFS). If you don't use filters, the response returns all data repository associations owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all data repository associations, you can paginate the response by using the optional MaxResults parameter to limit the number of data repository associations returned in a response. If more data repository associations remain, a NextToken value is returned in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeDataRepositoryAssociations
# operationId: DescribeDataRepositoryAssociations
# --Filters item shape: {Name?: any, Values?: any}
export def "x-amz-target-aws-simba-api-service-v20180301-describe-data-repository-associations get" [
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
  --x-amz-target: string@x-amz-target-completer-21
  --association-ids: any
  --filters: list # A list of Filter elements. — item shape: {Name?: any, Values?: any}
  --max-results: any
  --next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off.
]: any -> record<Associations: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeDataRepositoryAssociations" $qp)
  let req_body = {"AssociationIds": $association_ids, "Filters": $filters, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the description of specific Amazon FSx for Lustre or Amazon File Cache data repository tasks, if one or more TaskIds values are provided in the request, or if filters are used in the request. You can use filters to narrow the response to include just tasks for specific file systems or caches, or tasks in a specific lifecycle state. Otherwise, it returns all data repository tasks owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all tasks, you can paginate the response by using the optional MaxResults parameter to limit the number of tasks returned in a response. If more tasks remain, a NextToken value is returned in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeDataRepositoryTasks
# operationId: DescribeDataRepositoryTasks
export def "x-amz-target-aws-simba-api-service-v20180301-describe-data-repository-tasks get" [
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
  --x-amz-target: string@x-amz-target-completer-22
  --task-ids: any
  --filters: any
  --max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero.
  --next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off.
]: any -> record<DataRepositoryTasks: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeDataRepositoryTasks" $qp)
  let req_body = {"TaskIds": $task_ids, "Filters": $filters, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the description of a specific Amazon File Cache resource, if a FileCacheIds value is provided for that cache. Otherwise, it returns descriptions of all caches owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all cache descriptions, you can optionally specify the MaxResults parameter to limit the number of descriptions in a response. If more cache descriptions remain, the operation returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response. This operation is used in an iterative process to retrieve a list of your cache descriptions. DescribeFileCaches is called first without a NextTokenvalue. Then the operation continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken. When using this operation, keep the following in mind: The implementation might return fewer than MaxResults cache descriptions while still including a NextToken value. The order of caches returned in the response of one DescribeFileCaches call and the order of caches returned across the responses of a multicall iteration is unspecified.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileCaches
# operationId: DescribeFileCaches
export def "x-amz-target-aws-simba-api-service-v20180301-describe-file-caches get" [
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
  --x-amz-target: string@x-amz-target-completer-23
  --file-cache-ids: any
  --max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero.
  --next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off.
]: any -> record<FileCaches: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileCaches" $qp)
  let req_body = {"FileCacheIds": $file_cache_ids, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the DNS aliases that are associated with the specified Amazon FSx for Windows File Server file system. A history of all DNS aliases that have been associated with and disassociated from the file system is available in the list of AdministrativeAction provided in the DescribeFileSystems operation response.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileSystemAliases
# operationId: DescribeFileSystemAliases
export def "x-amz-target-aws-simba-api-service-v20180301-describe-file-system-aliases get" [
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
  --x-amz-target: string@x-amz-target-completer-24
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_id: any
  --max-results: any
  --next-token: any
]: any -> record<Aliases: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileSystemAliases" $qp)
  let req_body = {"ClientRequestToken": $client_request_token, "FileSystemId": $file_system_id, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the description of specific Amazon FSx file systems, if a FileSystemIds value is provided for that file system. Otherwise, it returns descriptions of all file systems owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all file system descriptions, you can optionally specify the MaxResults parameter to limit the number of descriptions in a response. If more file system descriptions remain, Amazon FSx returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response. This operation is used in an iterative process to retrieve a list of your file system descriptions. DescribeFileSystems is called first without a NextTokenvalue. Then the operation continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken. When using this operation, keep the following in mind: The implementation might return fewer than MaxResults file system descriptions while still including a NextToken value. The order of file systems returned in the response of one DescribeFileSystems call and the order of file systems returned across the responses of a multicall iteration is unspecified.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileSystems
# operationId: DescribeFileSystems
export def "x-amz-target-aws-simba-api-service-v20180301-describe-file-systems get" [
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
  --x-amz-target: string@x-amz-target-completer-25
  --file-system-ids: any
  --max-results: any
  --next-token: any
]: any -> record<FileSystems: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileSystems" $qp)
  let req_body = {"FileSystemIds": $file_system_ids, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the description of specific Amazon FSx for OpenZFS snapshots, if a SnapshotIds value is provided. Otherwise, this operation returns all snapshots owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all snapshots, you can optionally specify the MaxResults parameter to limit the number of snapshots in a response. If more backups remain, Amazon FSx returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response. Use this operation in an iterative process to retrieve a list of your snapshots. DescribeSnapshots is called first without a NextToken value. Then the operation continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken value. When using this operation, keep the following in mind: The operation might return fewer than the MaxResults value of snapshot descriptions while still including a NextToken value. The order of snapshots returned in the response of one DescribeSnapshots call and the order of backups returned across the responses of a multi-call iteration is unspecified.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeSnapshots
# operationId: DescribeSnapshots
export def "x-amz-target-aws-simba-api-service-v20180301-describe-snapshots get" [
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
  --x-amz-target: string@x-amz-target-completer-26
  --snapshot-ids: any
  --filters: any
  --max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero.
  --next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off.
]: any -> record<Snapshots: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeSnapshots" $qp)
  let req_body = {"SnapshotIds": $snapshot_ids, "Filters": $filters, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes one or more Amazon FSx for NetApp ONTAP storage virtual machines (SVMs).
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeStorageVirtualMachines
# operationId: DescribeStorageVirtualMachines
export def "x-amz-target-aws-simba-api-service-v20180301-describe-storage-virtual-machines get" [
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
  --x-amz-target: string@x-amz-target-completer-27
  --storage-virtual-machine-ids: any
  --filters: any
  --max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero.
  --next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off.
]: any -> record<StorageVirtualMachines: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeStorageVirtualMachines" $qp)
  let req_body = {"StorageVirtualMachineIds": $storage_virtual_machine_ids, "Filters": $filters, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes one or more Amazon FSx for NetApp ONTAP or Amazon FSx for OpenZFS volumes.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeVolumes
# operationId: DescribeVolumes
export def "x-amz-target-aws-simba-api-service-v20180301-describe-volumes get" [
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
  --x-amz-target: string@x-amz-target-completer-28
  --volume-ids: any
  --filters: any
  --max-results: int # The maximum number of resources to return in the response. This value must be an integer greater than zero.
  --next-token: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off.
]: any -> record<Volumes: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeVolumes" $qp)
  let req_body = {"VolumeIds": $volume_ids, "Filters": $filters, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this action to disassociate, or remove, one or more Domain Name Service (DNS) aliases from an Amazon FSx for Windows File Server file system. If you attempt to disassociate a DNS alias that is not associated with the file system, Amazon FSx responds with a 400 Bad Request. For more information, see Working with DNS Aliases (https://docs.aws.amazon.com/fsx/latest/WindowsGuide/managing-dns-aliases.html). The system generated response showing the DNS aliases that Amazon FSx is attempting to disassociate from the file system. Use the API operation to monitor the status of the aliases Amazon FSx is disassociating with the file system.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DisassociateFileSystemAliases
# operationId: DisassociateFileSystemAliases
export def "x-amz-target-aws-simba-api-service-v20180301-disassociate-file-system-aliases create" [
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
  --x-amz-target: string@x-amz-target-completer-29
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_id: any
  aliases: any
]: any -> record<Aliases: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DisassociateFileSystemAliases")
  let req_body = {"ClientRequestToken": $client_request_token, "FileSystemId": $file_system_id, "Aliases": $aliases} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists tags for Amazon FSx resources. When retrieving all tags, you can optionally specify the MaxResults parameter to limit the number of tags in a response. If more tags remain, Amazon FSx returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response. This action is used in an iterative process to retrieve a list of your tags. ListTagsForResource is called first without a NextTokenvalue. Then the action continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken. When using this action, keep the following in mind: The implementation might return fewer than MaxResults file system descriptions while still including a NextToken value. The order of tags returned in the response of one ListTagsForResource call and the order of tags returned across the responses of a multi-call iteration is unspecified.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.ListTagsForResource
# operationId: ListTagsForResource
export def "x-amz-target-aws-simba-api-service-v20180301-list-tags-for-resource list" [
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
  --x-amz-target: string@x-amz-target-completer-30
  resource_arn: any
  --max-results: any
  --next-token: any
]: any -> record<Tags: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.ListTagsForResource" $qp)
  let req_body = {"ResourceARN": $resource_arn, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Releases the file system lock from an Amazon FSx for OpenZFS file system.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.ReleaseFileSystemNfsV3Locks
# operationId: ReleaseFileSystemNfsV3Locks
export def "x-amz-target-aws-simba-api-service-v20180301-release-file-system-nfs-v3-locks create" [
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
  --x-amz-target: string@x-amz-target-completer-31
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
]: any -> record<FileSystem: record<OwnerId: record, CreationTime: record, FileSystemId: record, FileSystemType: record, Lifecycle: record, FailureDetails: record<Message: record>, StorageCapacity: record, StorageType: record, VpcId: record, SubnetIds: record, NetworkInterfaceIds: record, DNSName: record, KmsKeyId: record, ResourceARN: record, Tags: record, WindowsConfiguration: record<ActiveDirectoryId: record, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: record, RemoteAdministrationEndpoint: record, PreferredSubnetId: record, PreferredFileServerIp: record, ThroughputCapacity: record, MaintenanceOperationsInProgress: record, WeeklyMaintenanceStartTime: record, DailyAutomaticBackupStartTime: record, AutomaticBackupRetentionDays: record, CopyTagsToBackups: record, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: record, DataRepositoryConfiguration: record, DeploymentType: record, PerUnitStorageThroughput: record, MountName: record, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, DriveCacheType: record, DataCompressionType: record, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: record, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: record, EndpointIpAddressRange: record, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: record, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: record, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, CopyTagsToVolumes: record, DailyAutomaticBackupStartTime: string, DeploymentType: record, ThroughputCapacity: record, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.ReleaseFileSystemNfsV3Locks")
  let req_body = {"FileSystemId": $file_system_id, "ClientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns an Amazon FSx for OpenZFS volume to the state saved by the specified snapshot.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.RestoreVolumeFromSnapshot
# operationId: RestoreVolumeFromSnapshot
export def "x-amz-target-aws-simba-api-service-v20180301-restore-volume-from-snapshot create" [
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
  --x-amz-target: string@x-amz-target-completer-32
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  volume_id: any
  snapshot_id: any
  --options: any
]: any -> record<VolumeId: record, Lifecycle: record, AdministrativeActions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.RestoreVolumeFromSnapshot")
  let req_body = {"ClientRequestToken": $client_request_token, "VolumeId": $volume_id, "SnapshotId": $snapshot_id, "Options": $options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Tags an Amazon FSx resource.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.TagResource
# operationId: TagResource
export def "x-amz-target-aws-simba-api-service-v20180301-tag-resource tag" [
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
  --x-amz-target: string@x-amz-target-completer-33
  resource_arn: any
  tags: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.TagResource")
  let req_body = {"ResourceARN": $resource_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This action removes a tag from an Amazon FSx resource.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UntagResource
# operationId: UntagResource
export def "x-amz-target-aws-simba-api-service-v20180301-untag-resource untag" [
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
  --x-amz-target: string@x-amz-target-completer-34
  resource_arn: any
  tag_keys: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UntagResource")
  let req_body = {"ResourceARN": $resource_arn, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the configuration of an existing data repository association on an Amazon FSx for Lustre file system. Data repository associations are supported for all file systems except for Scratch_1 deployment type.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateDataRepositoryAssociation
# operationId: UpdateDataRepositoryAssociation
export def "x-amz-target-aws-simba-api-service-v20180301-update-data-repository-association update" [
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
  --x-amz-target: string@x-amz-target-completer-35
  association_id: any
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --imported-file-chunk-size: any
  --s3: any
]: any -> record<Association: record<AssociationId: record, ResourceARN: string, FileSystemId: string, Lifecycle: record, FailureDetails: record<Message: string>, FileSystemPath: record, DataRepositoryPath: record, BatchImportMetaDataOnCreate: record, ImportedFileChunkSize: record, S3: record<AutoImportPolicy: record, AutoExportPolicy: record>, Tags: list<record>, CreationTime: string, FileCacheId: record, FileCachePath: record, DataRepositorySubdirectories: record, NFS: record<Version: record, DnsIps: record, AutoExportPolicy: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateDataRepositoryAssociation")
  let req_body = {"AssociationId": $association_id, "ClientRequestToken": $client_request_token, "ImportedFileChunkSize": $imported_file_chunk_size, "S3": $s3} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the configuration of an existing Amazon File Cache resource. You can update multiple properties in a single request.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateFileCache
# operationId: UpdateFileCache
export def "x-amz-target-aws-simba-api-service-v20180301-update-file-cache update" [
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
  --x-amz-target: string@x-amz-target-completer-36
  file_cache_id: any
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --lustre-configuration: any
]: any -> record<FileCache: record<OwnerId: string, CreationTime: string, FileCacheId: record, FileCacheType: record, FileCacheTypeVersion: record, Lifecycle: record, FailureDetails: record<Message: record>, StorageCapacity: record, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: record, KmsKeyId: record, ResourceARN: string, LustreConfiguration: record<PerUnitStorageThroughput: record, DeploymentType: record, MountName: record, WeeklyMaintenanceStartTime: string, MetadataConfiguration: record, LogConfiguration: record>, DataRepositoryAssociationIds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateFileCache")
  let req_body = {"FileCacheId": $file_cache_id, "ClientRequestToken": $client_request_token, "LustreConfiguration": $lustre_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this operation to update the configuration of an existing Amazon FSx file system. You can update multiple properties in a single request. For FSx for Windows File Server file systems, you can update the following properties: AuditLogConfiguration AutomaticBackupRetentionDays DailyAutomaticBackupStartTime SelfManagedActiveDirectoryConfiguration StorageCapacity ThroughputCapacity WeeklyMaintenanceStartTime For FSx for Lustre file systems, you can update the following properties: AutoImportPolicy AutomaticBackupRetentionDays DailyAutomaticBackupStartTime DataCompressionType LustreRootSquashConfiguration StorageCapacity WeeklyMaintenanceStartTime For FSx for ONTAP file systems, you can update the following properties: AddRouteTableIds AutomaticBackupRetentionDays DailyAutomaticBackupStartTime DiskIopsConfiguration FsxAdminPassword RemoveRouteTableIds StorageCapacity ThroughputCapacity WeeklyMaintenanceStartTime For FSx for OpenZFS file systems, you can update the following properties: AutomaticBackupRetentionDays CopyTagsToBackups CopyTagsToVolumes DailyAutomaticBackupStartTime DiskIopsConfiguration StorageCapacity ThroughputCapacity WeeklyMaintenanceStartTime
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateFileSystem
# operationId: UpdateFileSystem
# --LustreConfiguration shape: {WeeklyMaintenanceStartTime?: any, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, AutoImportPolicy?: any, DataCompressionType?: any, LogConfiguration?: any, RootSquashConfiguration?: any}
# --OntapConfiguration shape: {AutomaticBackupRetentionDays?: int, DailyAutomaticBackupStartTime?: string, FsxAdminPassword?: any, WeeklyMaintenanceStartTime?: string, DiskIopsConfiguration?: any, ThroughputCapacity?: any, AddRouteTableIds?: any, RemoveRouteTableIds?: any}
export def "x-amz-target-aws-simba-api-service-v20180301-update-file-system update" [
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
  --x-amz-target: string@x-amz-target-completer-37
  file_system_id: any
  --client-request-token: any
  --storage-capacity: any
  --windows-configuration: any
  --lustre-configuration: record # The configuration object for Amazon FSx for Lustre file systems used in the UpdateFileSystem operation. — shape: {WeeklyMaintenanceStartTime?: any, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, AutoImportPolicy?: any, DataCompressionType?: any, LogConfiguration?: any, RootSquashConfiguration?: any}
  --ontap-configuration: record # The configuration updates for an Amazon FSx for NetApp ONTAP file system. — shape: {AutomaticBackupRetentionDays?: int, DailyAutomaticBackupStartTime?: string, FsxAdminPassword?: any, WeeklyMaintenanceStartTime?: string, DiskIopsConfiguration?: any, ThroughputCapacity?: any, AddRouteTableIds?: any, RemoveRouteTableIds?: any}
  --open-zfs-configuration: any
]: any -> record<FileSystem: record<OwnerId: record, CreationTime: record, FileSystemId: record, FileSystemType: record, Lifecycle: record, FailureDetails: record<Message: record>, StorageCapacity: record, StorageType: record, VpcId: record, SubnetIds: record, NetworkInterfaceIds: record, DNSName: record, KmsKeyId: record, ResourceARN: record, Tags: record, WindowsConfiguration: record<ActiveDirectoryId: record, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: record, RemoteAdministrationEndpoint: record, PreferredSubnetId: record, PreferredFileServerIp: record, ThroughputCapacity: record, MaintenanceOperationsInProgress: record, WeeklyMaintenanceStartTime: record, DailyAutomaticBackupStartTime: record, AutomaticBackupRetentionDays: record, CopyTagsToBackups: record, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: record, DataRepositoryConfiguration: record, DeploymentType: record, PerUnitStorageThroughput: record, MountName: record, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, DriveCacheType: record, DataCompressionType: record, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: record, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: record, EndpointIpAddressRange: record, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: record, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: record, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, CopyTagsToVolumes: record, DailyAutomaticBackupStartTime: string, DeploymentType: record, ThroughputCapacity: record, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateFileSystem")
  let req_body = {"FileSystemId": $file_system_id, "ClientRequestToken": $client_request_token, "StorageCapacity": $storage_capacity, "WindowsConfiguration": $windows_configuration, "LustreConfiguration": $lustre_configuration, "OntapConfiguration": $ontap_configuration, "OpenZFSConfiguration": $open_zfs_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the name of an Amazon FSx for OpenZFS snapshot.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateSnapshot
# operationId: UpdateSnapshot
export def "x-amz-target-aws-simba-api-service-v20180301-update-snapshot update" [
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
  --x-amz-target: string@x-amz-target-completer-38
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  name: any
  snapshot_id: any
]: any -> record<Snapshot: record<ResourceARN: string, SnapshotId: record, Name: record, VolumeId: record, CreationTime: string, Lifecycle: record, LifecycleTransitionReason: record<Message: string>, Tags: list<record>, AdministrativeActions: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateSnapshot")
  let req_body = {"ClientRequestToken": $client_request_token, "Name": $name, "SnapshotId": $snapshot_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates an Amazon FSx for ONTAP storage virtual machine (SVM).
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateStorageVirtualMachine
# operationId: UpdateStorageVirtualMachine
export def "x-amz-target-aws-simba-api-service-v20180301-update-storage-virtual-machine update" [
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
  --x-amz-target: string@x-amz-target-completer-39
  --active-directory-configuration: any
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  storage_virtual_machine_id: any
  --svm-admin-password: any
]: any -> record<StorageVirtualMachine: record<ActiveDirectoryConfiguration: record<NetBiosName: record, SelfManagedActiveDirectoryConfiguration: record>, CreationTime: string, Endpoints: record<Iscsi: record, Management: record, Nfs: record, Smb: record>, FileSystemId: string, Lifecycle: record, Name: record, ResourceARN: string, StorageVirtualMachineId: record, Subtype: record, UUID: record, Tags: list<record>, LifecycleTransitionReason: record<Message: string>, RootVolumeSecurityStyle: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateStorageVirtualMachine")
  let req_body = {"ActiveDirectoryConfiguration": $active_directory_configuration, "ClientRequestToken": $client_request_token, "StorageVirtualMachineId": $storage_virtual_machine_id, "SvmAdminPassword": $svm_admin_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the configuration of an Amazon FSx for NetApp ONTAP or Amazon FSx for OpenZFS volume.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateVolume
# operationId: UpdateVolume
export def "x-amz-target-aws-simba-api-service-v20180301-update-volume update" [
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
  --x-amz-target: string@x-amz-target-completer-40
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  volume_id: any
  --ontap-configuration: any
  --name: any
  --open-zfs-configuration: any
]: any -> record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: record, Name: record, OntapConfiguration: record<FlexCacheEndpointType: record, JunctionPath: record, SecurityStyle: record, SizeInMegabytes: record, StorageEfficiencyEnabled: record, StorageVirtualMachineId: record, StorageVirtualMachineRoot: record, TieringPolicy: record, UUID: record, OntapVolumeType: record, SnapshotPolicy: record, CopyTagsToBackups: record>, ResourceARN: string, Tags: list<record>, VolumeId: record, VolumeType: record, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: record, OpenZFSConfiguration: record<ParentVolumeId: record, VolumePath: record, StorageCapacityReservationGiB: record, StorageCapacityQuotaGiB: record, RecordSizeKiB: record, DataCompressionType: record, CopyTagsToSnapshots: record, OriginSnapshot: record, ReadOnly: record, NfsExports: record, UserAndGroupQuotas: record, RestoreToSnapshot: record, DeleteIntermediateSnaphots: record, DeleteClonedVolumes: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateVolume")
  let req_body = {"ClientRequestToken": $client_request_token, "VolumeId": $volume_id, "OntapConfiguration": $ontap_configuration, "Name": $name, "OpenZFSConfiguration": $open_zfs_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
