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
def X-Amz-Target-completer [] { ["AWSSimbaAPIService_v20180301.AssociateFileSystemAliases"] }
def X-Amz-Target-completer-1 [] { ["AWSSimbaAPIService_v20180301.CancelDataRepositoryTask"] }
def X-Amz-Target-completer-2 [] { ["AWSSimbaAPIService_v20180301.CopyBackup"] }
def X-Amz-Target-completer-3 [] { ["AWSSimbaAPIService_v20180301.CreateBackup"] }
def X-Amz-Target-completer-4 [] { ["AWSSimbaAPIService_v20180301.CreateDataRepositoryAssociation"] }
def X-Amz-Target-completer-5 [] { ["AWSSimbaAPIService_v20180301.CreateDataRepositoryTask"] }
def X-Amz-Target-completer-6 [] { ["AWSSimbaAPIService_v20180301.CreateFileCache"] }
def X-Amz-Target-completer-7 [] { ["AWSSimbaAPIService_v20180301.CreateFileSystem"] }
def X-Amz-Target-completer-8 [] { ["AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup"] }
def X-Amz-Target-completer-9 [] { ["AWSSimbaAPIService_v20180301.CreateSnapshot"] }
def X-Amz-Target-completer-10 [] { ["AWSSimbaAPIService_v20180301.CreateStorageVirtualMachine"] }
def X-Amz-Target-completer-11 [] { ["AWSSimbaAPIService_v20180301.CreateVolume"] }
def X-Amz-Target-completer-12 [] { ["AWSSimbaAPIService_v20180301.CreateVolumeFromBackup"] }
def X-Amz-Target-completer-13 [] { ["AWSSimbaAPIService_v20180301.DeleteBackup"] }
def X-Amz-Target-completer-14 [] { ["AWSSimbaAPIService_v20180301.DeleteDataRepositoryAssociation"] }
def X-Amz-Target-completer-15 [] { ["AWSSimbaAPIService_v20180301.DeleteFileCache"] }
def X-Amz-Target-completer-16 [] { ["AWSSimbaAPIService_v20180301.DeleteFileSystem"] }
def X-Amz-Target-completer-17 [] { ["AWSSimbaAPIService_v20180301.DeleteSnapshot"] }
def X-Amz-Target-completer-18 [] { ["AWSSimbaAPIService_v20180301.DeleteStorageVirtualMachine"] }
def X-Amz-Target-completer-19 [] { ["AWSSimbaAPIService_v20180301.DeleteVolume"] }
def X-Amz-Target-completer-20 [] { ["AWSSimbaAPIService_v20180301.DescribeBackups"] }
def X-Amz-Target-completer-21 [] { ["AWSSimbaAPIService_v20180301.DescribeDataRepositoryAssociations"] }
def X-Amz-Target-completer-22 [] { ["AWSSimbaAPIService_v20180301.DescribeDataRepositoryTasks"] }
def X-Amz-Target-completer-23 [] { ["AWSSimbaAPIService_v20180301.DescribeFileCaches"] }
def X-Amz-Target-completer-24 [] { ["AWSSimbaAPIService_v20180301.DescribeFileSystemAliases"] }
def X-Amz-Target-completer-25 [] { ["AWSSimbaAPIService_v20180301.DescribeFileSystems"] }
def X-Amz-Target-completer-26 [] { ["AWSSimbaAPIService_v20180301.DescribeSnapshots"] }
def X-Amz-Target-completer-27 [] { ["AWSSimbaAPIService_v20180301.DescribeStorageVirtualMachines"] }
def X-Amz-Target-completer-28 [] { ["AWSSimbaAPIService_v20180301.DescribeVolumes"] }
def X-Amz-Target-completer-29 [] { ["AWSSimbaAPIService_v20180301.DisassociateFileSystemAliases"] }
def X-Amz-Target-completer-30 [] { ["AWSSimbaAPIService_v20180301.ListTagsForResource"] }
def X-Amz-Target-completer-31 [] { ["AWSSimbaAPIService_v20180301.ReleaseFileSystemNfsV3Locks"] }
def X-Amz-Target-completer-32 [] { ["AWSSimbaAPIService_v20180301.RestoreVolumeFromSnapshot"] }
def X-Amz-Target-completer-33 [] { ["AWSSimbaAPIService_v20180301.TagResource"] }
def X-Amz-Target-completer-34 [] { ["AWSSimbaAPIService_v20180301.UntagResource"] }
def X-Amz-Target-completer-35 [] { ["AWSSimbaAPIService_v20180301.UpdateDataRepositoryAssociation"] }
def X-Amz-Target-completer-36 [] { ["AWSSimbaAPIService_v20180301.UpdateFileCache"] }
def X-Amz-Target-completer-37 [] { ["AWSSimbaAPIService_v20180301.UpdateFileSystem"] }
def X-Amz-Target-completer-38 [] { ["AWSSimbaAPIService_v20180301.UpdateSnapshot"] }
def X-Amz-Target-completer-39 [] { ["AWSSimbaAPIService_v20180301.UpdateStorageVirtualMachine"] }
def X-Amz-Target-completer-40 [] { ["AWSSimbaAPIService_v20180301.UpdateVolume"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-aws-simba-api-service-v20180301-associate-file-system-aliases AssociateFileSystemAliases" } } | get name | first)
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

# <p>Use this action to associate one or more Domain Name Server (DNS) aliases with an existing Amazon FSx for Windows File Server file system. A file system can have a maximum of 50 DNS aliases associated with it at any one time. If you try to associate a DNS alias that is already associated with the file system, FSx takes no action on that alias in the request. For more information, see <a href="https://docs.aws.amazon.com/fsx/latest/WindowsGuide/managing-dns-aliases.html">Working with DNS Aliases</a> and <a href="https://docs.aws.amazon.com/fsx/latest/WindowsGuide/walkthrough05-file-system-custom-CNAME.html">Walkthrough 5: Using DNS aliases to access your file system</a>, including additional steps you must take to be able to access your file system using a DNS alias.</p> <p>The system response shows the DNS aliases that Amazon FSx is attempting to associate with the file system. Use the API operation to monitor the status of the aliases Amazon FSx is associating with the file system.</p>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.AssociateFileSystemAliases
# operationId: AssociateFileSystemAliases
export def "x-amz-target-aws-simba-api-service-v20180301-associate-file-system-aliases AssociateFileSystemAliases" [
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
  --X-Amz-Target: string@X-Amz-Target-completer
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  FileSystemId: any
  Aliases: any
]: any -> record<Aliases: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.AssociateFileSystemAliases")
  let body = {ClientRequestToken: $ClientRequestToken, FileSystemId: $FileSystemId, Aliases: $Aliases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Cancels an existing Amazon FSx for Lustre data repository task if that task is in either the <code>PENDING</code> or <code>EXECUTING</code> state. When you cancel a task, Amazon FSx does the following.</p> <ul> <li> <p>Any files that FSx has already exported are not reverted.</p> </li> <li> <p>FSx continues to export any files that are "in-flight" when the cancel operation is received.</p> </li> <li> <p>FSx does not export any files that have not yet been exported.</p> </li> </ul>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CancelDataRepositoryTask
# operationId: CancelDataRepositoryTask
export def "x-amz-target-aws-simba-api-service-v20180301-cancel-data-repository-task CancelDataRepositoryTask" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-1
  TaskId: any
]: any -> record<Lifecycle: record, TaskId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CancelDataRepositoryTask")
  let body = {TaskId: $TaskId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Copies an existing backup within the same Amazon Web Services account to another Amazon Web Services Region (cross-Region copy) or within the same Amazon Web Services Region (in-Region copy). You can have up to five backup copy requests in progress to a single destination Region per account.</p> <p>You can use cross-Region backup copies for cross-Region disaster recovery. You can periodically take backups and copy them to another Region so that in the event of a disaster in the primary Region, you can restore from backup and recover availability quickly in the other Region. You can make cross-Region copies only within your Amazon Web Services partition. A partition is a grouping of Regions. Amazon Web Services currently has three partitions: <code>aws</code> (Standard Regions), <code>aws-cn</code> (China Regions), and <code>aws-us-gov</code> (Amazon Web Services GovCloud [US] Regions).</p> <p>You can also use backup copies to clone your file dataset to another Region or within the same Region.</p> <p>You can use the <code>SourceRegion</code> parameter to specify the Amazon Web Services Region from which the backup will be copied. For example, if you make the call from the <code>us-west-1</code> Region and want to copy a backup from the <code>us-east-2</code> Region, you specify <code>us-east-2</code> in the <code>SourceRegion</code> parameter to make a cross-Region copy. If you don't specify a Region, the backup copy is created in the same Region where the request is sent from (in-Region copy).</p> <p>For more information about creating backup copies, see <a href="https://docs.aws.amazon.com/fsx/latest/WindowsGuide/using-backups.html#copy-backups"> Copying backups</a> in the <i>Amazon FSx for Windows User Guide</i>, <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/using-backups-fsx.html#copy-backups">Copying backups</a> in the <i>Amazon FSx for Lustre User Guide</i>, and <a href="https://docs.aws.amazon.com/fsx/latest/OpenZFSGuide/using-backups.html#copy-backups">Copying backups</a> in the <i>Amazon FSx for OpenZFS User Guide</i>.</p>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CopyBackup
# operationId: CopyBackup
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-copy-backup CopyBackup" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-2
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  SourceBackupId: any
  --SourceRegion: any
  --KmsKeyId: string # <p>Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows:</p> <ul> <li> <p>Amazon FSx for Lustre <code>PERSISTENT_1</code> and <code>PERSISTENT_2</code> deployment types only.</p> <p> <code>SCRATCH_1</code> and <code>SCRATCH_2</code> types are encrypted using the Amazon FSx service KMS key for your account.</p> </li> <li> <p>Amazon FSx for NetApp ONTAP</p> </li> <li> <p>Amazon FSx for OpenZFS</p> </li> <li> <p>Amazon FSx for Windows File Server</p> </li> </ul> <p>If a <code>KmsKeyId</code> isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html">Encrypt</a> in the <i>Key Management Service API Reference</i>.</p>
  --CopyTags: any
  --Tags: list # A list of <code>Tag</code> values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
]: any -> record<Backup: record<BackupId: record, Lifecycle: record, FailureDetails: record<Message: record>, Type: record, ProgressPercent: int, CreationTime: record, KmsKeyId: record, ResourceARN: record, Tags: record, FileSystem: record<OwnerId: record, CreationTime: record, FileSystemId: record, FileSystemType: record, Lifecycle: record, FailureDetails: record, StorageCapacity: record, StorageType: record, VpcId: record, SubnetIds: record, NetworkInterfaceIds: record, DNSName: record, KmsKeyId: record, ResourceARN: record, Tags: record, WindowsConfiguration: record, LustreConfiguration: record, AdministrativeActions: record, OntapConfiguration: record, FileSystemTypeVersion: record, OpenZFSConfiguration: record>, DirectoryInformation: record<DomainName: record, ActiveDirectoryId: record, ResourceARN: string>, OwnerId: string, SourceBackupId: string, SourceBackupRegion: record, ResourceType: record, Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: record, Name: record, OntapConfiguration: record, ResourceARN: string, Tags: list, VolumeId: record, VolumeType: record, LifecycleTransitionReason: record, AdministrativeActions: record, OpenZFSConfiguration: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CopyBackup")
  let body = {ClientRequestToken: $ClientRequestToken, SourceBackupId: $SourceBackupId, SourceRegion: $SourceRegion, KmsKeyId: $KmsKeyId, CopyTags: $CopyTags, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a backup of an existing Amazon FSx for Windows File Server file system, Amazon FSx for Lustre file system, Amazon FSx for NetApp ONTAP volume, or Amazon FSx for OpenZFS file system. We recommend creating regular backups so that you can restore a file system or volume from a backup if an issue arises with the original file system or volume.</p> <p>For Amazon FSx for Lustre file systems, you can create a backup only for file systems that have the following configuration:</p> <ul> <li> <p>A Persistent deployment type</p> </li> <li> <p>Are <i>not</i> linked to a data repository</p> </li> </ul> <p>For more information about backups, see the following:</p> <ul> <li> <p>For Amazon FSx for Lustre, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/using-backups-fsx.html">Working with FSx for Lustre backups</a>.</p> </li> <li> <p>For Amazon FSx for Windows, see <a href="https://docs.aws.amazon.com/fsx/latest/WindowsGuide/using-backups.html">Working with FSx for Windows backups</a>.</p> </li> <li> <p>For Amazon FSx for NetApp ONTAP, see <a href="https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/using-backups.html">Working with FSx for NetApp ONTAP backups</a>.</p> </li> <li> <p>For Amazon FSx for OpenZFS, see <a href="https://docs.aws.amazon.com/fsx/latest/OpenZFSGuide/using-backups.html">Working with FSx for OpenZFS backups</a>.</p> </li> </ul> <p>If a backup with the specified client request token exists and the parameters match, this operation returns the description of the existing backup. If a backup with the specified client request token exists and the parameters don't match, this operation returns <code>IncompatibleParameterError</code>. If a backup with the specified client request token doesn't exist, <code>CreateBackup</code> does the following: </p> <ul> <li> <p>Creates a new Amazon FSx backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the backup.</p> </li> </ul> <p>By using the idempotent operation, you can retry a <code>CreateBackup</code> operation without the risk of creating an extra backup. This approach can be useful when an initial call fails in a way that makes it unclear whether a backup was created. If you use the same client request token and the initial call created a backup, the operation returns a successful result because all the parameters are the same.</p> <p>The <code>CreateBackup</code> operation returns while the backup's lifecycle state is still <code>CREATING</code>. You can check the backup creation status by calling the <a href="https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeBackups.html">DescribeBackups</a> operation, which returns the backup state along with other information.</p>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateBackup
# operationId: CreateBackup
export def "x-amz-target-aws-simba-api-service-v20180301-create-backup CreateBackup" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-3
  --FileSystemId: any
  --ClientRequestToken: any
  --Tags: any
  --VolumeId: any
]: any -> record<Backup: record<BackupId: record, Lifecycle: record, FailureDetails: record<Message: record>, Type: record, ProgressPercent: int, CreationTime: record, KmsKeyId: record, ResourceARN: record, Tags: record, FileSystem: record<OwnerId: record, CreationTime: record, FileSystemId: record, FileSystemType: record, Lifecycle: record, FailureDetails: record, StorageCapacity: record, StorageType: record, VpcId: record, SubnetIds: record, NetworkInterfaceIds: record, DNSName: record, KmsKeyId: record, ResourceARN: record, Tags: record, WindowsConfiguration: record, LustreConfiguration: record, AdministrativeActions: record, OntapConfiguration: record, FileSystemTypeVersion: record, OpenZFSConfiguration: record>, DirectoryInformation: record<DomainName: record, ActiveDirectoryId: record, ResourceARN: string>, OwnerId: string, SourceBackupId: string, SourceBackupRegion: record, ResourceType: record, Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: record, Name: record, OntapConfiguration: record, ResourceARN: string, Tags: list, VolumeId: record, VolumeType: record, LifecycleTransitionReason: record, AdministrativeActions: record, OpenZFSConfiguration: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateBackup")
  let body = {FileSystemId: $FileSystemId, ClientRequestToken: $ClientRequestToken, Tags: $Tags, VolumeId: $VolumeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates an Amazon FSx for Lustre data repository association (DRA). A data repository association is a link between a directory on the file system and an Amazon S3 bucket or prefix. You can have a maximum of 8 data repository associations on a file system. Data repository associations are supported for all file systems except for <code>Scratch_1</code> deployment type.</p> <p>Each data repository association must have a unique Amazon FSx file system directory and a unique S3 bucket or prefix associated with it. You can configure a data repository association for automatic import only, for automatic export only, or for both. To learn more about linking a data repository to your file system, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/create-dra-linked-data-repo.html">Linking your file system to an S3 bucket</a>.</p> <note> <p> <code>CreateDataRepositoryAssociation</code> isn't supported on Amazon File Cache resources. To create a DRA on Amazon File Cache, use the <code>CreateFileCache</code> operation.</p> </note>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateDataRepositoryAssociation
# operationId: CreateDataRepositoryAssociation
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-data-repository-association CreateDataRepositoryAssociation" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-4
  FileSystemId: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --FileSystemPath: any
  DataRepositoryPath: any
  --BatchImportMetaDataOnCreate: any
  --ImportedFileChunkSize: any
  --S3: any
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --Tags: list # A list of <code>Tag</code> values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
]: any -> record<Association: record<AssociationId: record, ResourceARN: string, FileSystemId: string, Lifecycle: record, FailureDetails: record<Message: string>, FileSystemPath: record, DataRepositoryPath: record, BatchImportMetaDataOnCreate: record, ImportedFileChunkSize: record, S3: record<AutoImportPolicy: record, AutoExportPolicy: record>, Tags: list<record>, CreationTime: string, FileCacheId: record, FileCachePath: record, DataRepositorySubdirectories: record, NFS: record<Version: record, DnsIps: record, AutoExportPolicy: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateDataRepositoryAssociation")
  let body = {FileSystemId: $FileSystemId, FileSystemPath: $FileSystemPath, DataRepositoryPath: $DataRepositoryPath, BatchImportMetaDataOnCreate: $BatchImportMetaDataOnCreate, ImportedFileChunkSize: $ImportedFileChunkSize, S3: $S3, ClientRequestToken: $ClientRequestToken, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an Amazon FSx for Lustre data repository task. You use data repository tasks to perform bulk operations between your Amazon FSx file system and its linked data repositories. An example of a data repository task is exporting any data and metadata changes, including POSIX metadata, to files, directories, and symbolic links (symlinks) from your FSx file system to a linked data repository. A <code>CreateDataRepositoryTask</code> operation will fail if a data repository is not linked to the FSx file system. To learn more about data repository tasks, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/data-repository-tasks.html">Data Repository Tasks</a>. To learn more about linking a data repository to your file system, see <a href="https://docs.aws.amazon.com/fsx/latest/LustreGuide/create-dra-linked-data-repo.html">Linking your file system to an S3 bucket</a>.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateDataRepositoryTask
# operationId: CreateDataRepositoryTask
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-data-repository-task CreateDataRepositoryTask" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-5
  Type: any
  --Paths: any
  FileSystemId: string # The globally unique ID of the file system, assigned by Amazon FSx.
  Report: any
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --Tags: list # A list of <code>Tag</code> values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
  --CapacityToRelease: any
]: any -> record<DataRepositoryTask: record<TaskId: record, Lifecycle: record, Type: record, CreationTime: string, StartTime: record, EndTime: record, ResourceARN: string, Tags: list<record>, FileSystemId: record, Paths: record, FailureDetails: record<Message: string>, Status: record<TotalCount: record, SucceededCount: record, FailedCount: record, LastUpdatedTime: record, ReleasedCapacity: record>, Report: record<Enabled: record, Path: record, Format: record, Scope: record>, CapacityToRelease: record, FileCacheId: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateDataRepositoryTask")
  let body = {Type: $Type, Paths: $Paths, FileSystemId: $FileSystemId, Report: $Report, ClientRequestToken: $ClientRequestToken, Tags: $Tags, CapacityToRelease: $CapacityToRelease} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a new Amazon File Cache resource.</p> <p>You can use this operation with a client request token in the request that Amazon File Cache uses to ensure idempotent creation. If a cache with the specified client request token exists and the parameters match, <code>CreateFileCache</code> returns the description of the existing cache. If a cache with the specified client request token exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file cache with the specified client request token doesn't exist, <code>CreateFileCache</code> does the following: </p> <ul> <li> <p>Creates a new, empty Amazon File Cache resourcewith an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the cache in JSON format.</p> </li> </ul> <note> <p>The <code>CreateFileCache</code> call returns while the cache's lifecycle state is still <code>CREATING</code>. You can check the cache creation status by calling the <a href="https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileCaches.html">DescribeFileCaches</a> operation, which returns the cache state along with other information.</p> </note>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileCache
# operationId: CreateFileCache
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-file-cache CreateFileCache" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-6
  --ClientRequestToken: any
  FileCacheType: any
  FileCacheTypeVersion: any
  StorageCapacity: any
  SubnetIds: list # A list of subnet IDs that the cache will be accessible from. You can specify only one subnet ID in a call to the <code>CreateFileCache</code> operation.
  --SecurityGroupIds: any
  --Tags: list # A list of <code>Tag</code> values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
  --CopyTagsToDataRepositoryAssociations: any
  --KmsKeyId: any
  --LustreConfiguration: any
  --DataRepositoryAssociations: any
]: any -> record<FileCache: record<OwnerId: string, CreationTime: string, FileCacheId: record, FileCacheType: record, FileCacheTypeVersion: record, Lifecycle: record, FailureDetails: record<Message: record>, StorageCapacity: record, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: record, KmsKeyId: record, ResourceARN: string, Tags: list<record>, CopyTagsToDataRepositoryAssociations: record, LustreConfiguration: record<PerUnitStorageThroughput: record, DeploymentType: record, MountName: record, WeeklyMaintenanceStartTime: string, MetadataConfiguration: record, LogConfiguration: record>, DataRepositoryAssociationIds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileCache")
  let body = {ClientRequestToken: $ClientRequestToken, FileCacheType: $FileCacheType, FileCacheTypeVersion: $FileCacheTypeVersion, StorageCapacity: $StorageCapacity, SubnetIds: $SubnetIds, SecurityGroupIds: $SecurityGroupIds, Tags: $Tags, CopyTagsToDataRepositoryAssociations: $CopyTagsToDataRepositoryAssociations, KmsKeyId: $KmsKeyId, LustreConfiguration: $LustreConfiguration, DataRepositoryAssociations: $DataRepositoryAssociations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a new, empty Amazon FSx file system. You can create the following supported Amazon FSx file systems using the <code>CreateFileSystem</code> API operation:</p> <ul> <li> <p>Amazon FSx for Lustre</p> </li> <li> <p>Amazon FSx for NetApp ONTAP</p> </li> <li> <p>Amazon FSx for OpenZFS</p> </li> <li> <p>Amazon FSx for Windows File Server</p> </li> </ul> <p>This operation requires a client request token in the request that Amazon FSx uses to ensure idempotent creation. This means that calling the operation multiple times with the same client request token has no effect. By using the idempotent operation, you can retry a <code>CreateFileSystem</code> operation without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same.</p> <p>If a file system with the specified client request token exists and the parameters match, <code>CreateFileSystem</code> returns the description of the existing file system. If a file system with the specified client request token exists and the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, <code>CreateFileSystem</code> does the following: </p> <ul> <li> <p>Creates a new, empty Amazon FSx file system with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system in JSON format.</p> </li> </ul> <note> <p>The <code>CreateFileSystem</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a href="https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileSystems.html">DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystem
# operationId: CreateFileSystem
# --LustreConfiguration shape: {WeeklyMaintenanceStartTime?: any, ImportPath?: any, ExportPath?: any, ImportedFileChunkSize?: any, DeploymentType?: any, AutoImportPolicy?: any, PerUnitStorageThroughput?: any, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: any, DriveCacheType?: any, DataCompressionType?: any, LogConfiguration?: any, RootSquashConfiguration?: any}
# --OntapConfiguration shape: {AutomaticBackupRetentionDays?: int, DailyAutomaticBackupStartTime?: string, DeploymentType: any, EndpointIpAddressRange?: any, FsxAdminPassword?: any, DiskIopsConfiguration?: any, PreferredSubnetId?: any, RouteTableIds?: any, ThroughputCapacity: any, WeeklyMaintenanceStartTime?: string}
export def "x-amz-target-aws-simba-api-service-v20180301-create-file-system CreateFileSystem" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-7
  --ClientRequestToken: any
  FileSystemType: any
  StorageCapacity: any
  --StorageType: any
  SubnetIds: any
  --SecurityGroupIds: any
  --Tags: any
  --KmsKeyId: string # <p>Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows:</p> <ul> <li> <p>Amazon FSx for Lustre <code>PERSISTENT_1</code> and <code>PERSISTENT_2</code> deployment types only.</p> <p> <code>SCRATCH_1</code> and <code>SCRATCH_2</code> types are encrypted using the Amazon FSx service KMS key for your account.</p> </li> <li> <p>Amazon FSx for NetApp ONTAP</p> </li> <li> <p>Amazon FSx for OpenZFS</p> </li> <li> <p>Amazon FSx for Windows File Server</p> </li> </ul> <p>If a <code>KmsKeyId</code> isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html">Encrypt</a> in the <i>Key Management Service API Reference</i>.</p>
  --WindowsConfiguration: any
  --LustreConfiguration: record # <p>The Lustre configuration for the file system being created.</p> <note> <p>The following parameters are not supported for file systems with a data repository association created with .</p> <ul> <li> <p> <code>AutoImportPolicy</code> </p> </li> <li> <p> <code>ExportPath</code> </p> </li> <li> <p> <code>ImportedChunkSize</code> </p> </li> <li> <p> <code>ImportPath</code> </p> </li> </ul> </note> — shape: {WeeklyMaintenanceStartTime?: any, ImportPath?: any, ExportPath?: any, ImportedFileChunkSize?: any, DeploymentType?: any, AutoImportPolicy?: any, PerUnitStorageThroughput?: any, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: any, DriveCacheType?: any, DataCompressionType?: any, LogConfiguration?: any, RootSquashConfiguration?: any}
  --OntapConfiguration: record # The ONTAP configuration properties of the FSx for ONTAP file system that you are creating. — shape: {AutomaticBackupRetentionDays?: int, DailyAutomaticBackupStartTime?: string, DeploymentType: any, EndpointIpAddressRange?: any, FsxAdminPassword?: any, DiskIopsConfiguration?: any, PreferredSubnetId?: any, RouteTableIds?: any, ThroughputCapacity: any, WeeklyMaintenanceStartTime?: string}
  --FileSystemTypeVersion: any
  --OpenZFSConfiguration: any
]: any -> record<FileSystem: record<OwnerId: record, CreationTime: record, FileSystemId: record, FileSystemType: record, Lifecycle: record, FailureDetails: record<Message: record>, StorageCapacity: record, StorageType: record, VpcId: record, SubnetIds: record, NetworkInterfaceIds: record, DNSName: record, KmsKeyId: record, ResourceARN: record, Tags: record, WindowsConfiguration: record<ActiveDirectoryId: record, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: record, RemoteAdministrationEndpoint: record, PreferredSubnetId: record, PreferredFileServerIp: record, ThroughputCapacity: record, MaintenanceOperationsInProgress: record, WeeklyMaintenanceStartTime: record, DailyAutomaticBackupStartTime: record, AutomaticBackupRetentionDays: record, CopyTagsToBackups: record, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: record, DataRepositoryConfiguration: record, DeploymentType: record, PerUnitStorageThroughput: record, MountName: record, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, DriveCacheType: record, DataCompressionType: record, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: record, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: record, EndpointIpAddressRange: record, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: record, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: record, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, CopyTagsToVolumes: record, DailyAutomaticBackupStartTime: string, DeploymentType: record, ThroughputCapacity: record, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystem")
  let body = {ClientRequestToken: $ClientRequestToken, FileSystemType: $FileSystemType, StorageCapacity: $StorageCapacity, StorageType: $StorageType, SubnetIds: $SubnetIds, SecurityGroupIds: $SecurityGroupIds, Tags: $Tags, KmsKeyId: $KmsKeyId, WindowsConfiguration: $WindowsConfiguration, LustreConfiguration: $LustreConfiguration, OntapConfiguration: $OntapConfiguration, FileSystemTypeVersion: $FileSystemTypeVersion, OpenZFSConfiguration: $OpenZFSConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a new Amazon FSx for Lustre, Amazon FSx for Windows File Server, or Amazon FSx for OpenZFS file system from an existing Amazon FSx backup.</p> <p>If a file system with the specified client request token exists and the parameters match, this operation returns the description of the file system. If a file system with the specified client request token exists but the parameters don't match, this call returns <code>IncompatibleParameterError</code>. If a file system with the specified client request token doesn't exist, this operation does the following:</p> <ul> <li> <p>Creates a new Amazon FSx file system from backup with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the file system.</p> </li> </ul> <p>Parameters like the Active Directory, default share name, automatic backup, and backup settings default to the parameters of the file system that was backed up, unless overridden. You can explicitly supply other settings.</p> <p>By using the idempotent operation, you can retry a <code>CreateFileSystemFromBackup</code> call without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives a success message as long as the parameters are the same.</p> <note> <p>The <code>CreateFileSystemFromBackup</code> call returns while the file system's lifecycle state is still <code>CREATING</code>. You can check the file-system creation status by calling the <a href="https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileSystems.html"> DescribeFileSystems</a> operation, which returns the file system state along with other information.</p> </note>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup
# operationId: CreateFileSystemFromBackup
# --LustreConfiguration shape: {WeeklyMaintenanceStartTime?: any, ImportPath?: any, ExportPath?: any, ImportedFileChunkSize?: any, DeploymentType?: any, AutoImportPolicy?: any, PerUnitStorageThroughput?: any, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: any, DriveCacheType?: any, DataCompressionType?: any, LogConfiguration?: any, RootSquashConfiguration?: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-file-system-from-backup CreateFileSystemFromBackup" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-8
  BackupId: string # The ID of the source backup. Specifies the backup that you are copying.
  --ClientRequestToken: any
  SubnetIds: any
  --SecurityGroupIds: any
  --Tags: any
  --WindowsConfiguration: any
  --LustreConfiguration: record # <p>The Lustre configuration for the file system being created.</p> <note> <p>The following parameters are not supported for file systems with a data repository association created with .</p> <ul> <li> <p> <code>AutoImportPolicy</code> </p> </li> <li> <p> <code>ExportPath</code> </p> </li> <li> <p> <code>ImportedChunkSize</code> </p> </li> <li> <p> <code>ImportPath</code> </p> </li> </ul> </note> — shape: {WeeklyMaintenanceStartTime?: any, ImportPath?: any, ExportPath?: any, ImportedFileChunkSize?: any, DeploymentType?: any, AutoImportPolicy?: any, PerUnitStorageThroughput?: any, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: any, DriveCacheType?: any, DataCompressionType?: any, LogConfiguration?: any, RootSquashConfiguration?: any}
  --StorageType: any
  --KmsKeyId: string # <p>Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows:</p> <ul> <li> <p>Amazon FSx for Lustre <code>PERSISTENT_1</code> and <code>PERSISTENT_2</code> deployment types only.</p> <p> <code>SCRATCH_1</code> and <code>SCRATCH_2</code> types are encrypted using the Amazon FSx service KMS key for your account.</p> </li> <li> <p>Amazon FSx for NetApp ONTAP</p> </li> <li> <p>Amazon FSx for OpenZFS</p> </li> <li> <p>Amazon FSx for Windows File Server</p> </li> </ul> <p>If a <code>KmsKeyId</code> isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html">Encrypt</a> in the <i>Key Management Service API Reference</i>.</p>
  --FileSystemTypeVersion: any
  --OpenZFSConfiguration: any
  --StorageCapacity: any
]: any -> record<FileSystem: record<OwnerId: record, CreationTime: record, FileSystemId: record, FileSystemType: record, Lifecycle: record, FailureDetails: record<Message: record>, StorageCapacity: record, StorageType: record, VpcId: record, SubnetIds: record, NetworkInterfaceIds: record, DNSName: record, KmsKeyId: record, ResourceARN: record, Tags: record, WindowsConfiguration: record<ActiveDirectoryId: record, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: record, RemoteAdministrationEndpoint: record, PreferredSubnetId: record, PreferredFileServerIp: record, ThroughputCapacity: record, MaintenanceOperationsInProgress: record, WeeklyMaintenanceStartTime: record, DailyAutomaticBackupStartTime: record, AutomaticBackupRetentionDays: record, CopyTagsToBackups: record, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: record, DataRepositoryConfiguration: record, DeploymentType: record, PerUnitStorageThroughput: record, MountName: record, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, DriveCacheType: record, DataCompressionType: record, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: record, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: record, EndpointIpAddressRange: record, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: record, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: record, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, CopyTagsToVolumes: record, DailyAutomaticBackupStartTime: string, DeploymentType: record, ThroughputCapacity: record, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup")
  let body = {BackupId: $BackupId, ClientRequestToken: $ClientRequestToken, SubnetIds: $SubnetIds, SecurityGroupIds: $SecurityGroupIds, Tags: $Tags, WindowsConfiguration: $WindowsConfiguration, LustreConfiguration: $LustreConfiguration, StorageType: $StorageType, KmsKeyId: $KmsKeyId, FileSystemTypeVersion: $FileSystemTypeVersion, OpenZFSConfiguration: $OpenZFSConfiguration, StorageCapacity: $StorageCapacity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a snapshot of an existing Amazon FSx for OpenZFS volume. With snapshots, you can easily undo file changes and compare file versions by restoring the volume to a previous version.</p> <p>If a snapshot with the specified client request token exists, and the parameters match, this operation returns the description of the existing snapshot. If a snapshot with the specified client request token exists, and the parameters don't match, this operation returns <code>IncompatibleParameterError</code>. If a snapshot with the specified client request token doesn't exist, <code>CreateSnapshot</code> does the following:</p> <ul> <li> <p>Creates a new OpenZFS snapshot with an assigned ID, and an initial lifecycle state of <code>CREATING</code>.</p> </li> <li> <p>Returns the description of the snapshot.</p> </li> </ul> <p>By using the idempotent operation, you can retry a <code>CreateSnapshot</code> operation without the risk of creating an extra snapshot. This approach can be useful when an initial call fails in a way that makes it unclear whether a snapshot was created. If you use the same client request token and the initial call created a snapshot, the operation returns a successful result because all the parameters are the same.</p> <p>The <code>CreateSnapshot</code> operation returns while the snapshot's lifecycle state is still <code>CREATING</code>. You can check the snapshot creation status by calling the <a href="https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeSnapshots.html">DescribeSnapshots</a> operation, which returns the snapshot state along with other information.</p>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateSnapshot
# operationId: CreateSnapshot
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-snapshot CreateSnapshot" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-9
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  Name: any
  VolumeId: any
  --Tags: list # A list of <code>Tag</code> values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
]: any -> record<Snapshot: record<ResourceARN: string, SnapshotId: record, Name: record, VolumeId: record, CreationTime: string, Lifecycle: record, LifecycleTransitionReason: record<Message: string>, Tags: list<record>, AdministrativeActions: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateSnapshot")
  let body = {ClientRequestToken: $ClientRequestToken, Name: $Name, VolumeId: $VolumeId, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a storage virtual machine (SVM) for an Amazon FSx for ONTAP file system.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateStorageVirtualMachine
# operationId: CreateStorageVirtualMachine
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-storage-virtual-machine CreateStorageVirtualMachine" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-10
  --ActiveDirectoryConfiguration: any
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  FileSystemId: string # The globally unique ID of the file system, assigned by Amazon FSx.
  Name: any
  --SvmAdminPassword: any
  --Tags: list # A list of <code>Tag</code> values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
  --RootVolumeSecurityStyle: any
]: any -> record<StorageVirtualMachine: record<ActiveDirectoryConfiguration: record<NetBiosName: record, SelfManagedActiveDirectoryConfiguration: record>, CreationTime: string, Endpoints: record<Iscsi: record, Management: record, Nfs: record, Smb: record>, FileSystemId: string, Lifecycle: record, Name: record, ResourceARN: string, StorageVirtualMachineId: record, Subtype: record, UUID: record, Tags: list<record>, LifecycleTransitionReason: record<Message: string>, RootVolumeSecurityStyle: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateStorageVirtualMachine")
  let body = {ActiveDirectoryConfiguration: $ActiveDirectoryConfiguration, ClientRequestToken: $ClientRequestToken, FileSystemId: $FileSystemId, Name: $Name, SvmAdminPassword: $SvmAdminPassword, Tags: $Tags, RootVolumeSecurityStyle: $RootVolumeSecurityStyle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an FSx for ONTAP or Amazon FSx for OpenZFS storage volume.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateVolume
# operationId: CreateVolume
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-volume CreateVolume" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-11
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  VolumeType: any
  Name: any
  --OntapConfiguration: any
  --Tags: list # A list of <code>Tag</code> values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
  --OpenZFSConfiguration: any
]: any -> record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: record, Name: record, OntapConfiguration: record<FlexCacheEndpointType: record, JunctionPath: record, SecurityStyle: record, SizeInMegabytes: record, StorageEfficiencyEnabled: record, StorageVirtualMachineId: record, StorageVirtualMachineRoot: record, TieringPolicy: record, UUID: record, OntapVolumeType: record, SnapshotPolicy: record, CopyTagsToBackups: record>, ResourceARN: string, Tags: list<record>, VolumeId: record, VolumeType: record, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: record, OpenZFSConfiguration: record<ParentVolumeId: record, VolumePath: record, StorageCapacityReservationGiB: record, StorageCapacityQuotaGiB: record, RecordSizeKiB: record, DataCompressionType: record, CopyTagsToSnapshots: record, OriginSnapshot: record, ReadOnly: record, NfsExports: record, UserAndGroupQuotas: record, RestoreToSnapshot: record, DeleteIntermediateSnaphots: record, DeleteClonedVolumes: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateVolume")
  let body = {ClientRequestToken: $ClientRequestToken, VolumeType: $VolumeType, Name: $Name, OntapConfiguration: $OntapConfiguration, Tags: $Tags, OpenZFSConfiguration: $OpenZFSConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new Amazon FSx for NetApp ONTAP volume from an existing Amazon FSx volume backup.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateVolumeFromBackup
# operationId: CreateVolumeFromBackup
# --Tags item shape: {Key: any, Value: any}
export def "x-amz-target-aws-simba-api-service-v20180301-create-volume-from-backup CreateVolumeFromBackup" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-12
  BackupId: string # The ID of the source backup. Specifies the backup that you are copying.
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  Name: any
  --OntapConfiguration: any
  --Tags: list # A list of <code>Tag</code> values, with a maximum of 50 elements. — item shape: {Key: any, Value: any}
]: any -> record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: record, Name: record, OntapConfiguration: record<FlexCacheEndpointType: record, JunctionPath: record, SecurityStyle: record, SizeInMegabytes: record, StorageEfficiencyEnabled: record, StorageVirtualMachineId: record, StorageVirtualMachineRoot: record, TieringPolicy: record, UUID: record, OntapVolumeType: record, SnapshotPolicy: record, CopyTagsToBackups: record>, ResourceARN: string, Tags: list<record>, VolumeId: record, VolumeType: record, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: record, OpenZFSConfiguration: record<ParentVolumeId: record, VolumePath: record, StorageCapacityReservationGiB: record, StorageCapacityQuotaGiB: record, RecordSizeKiB: record, DataCompressionType: record, CopyTagsToSnapshots: record, OriginSnapshot: record, ReadOnly: record, NfsExports: record, UserAndGroupQuotas: record, RestoreToSnapshot: record, DeleteIntermediateSnaphots: record, DeleteClonedVolumes: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.CreateVolumeFromBackup")
  let body = {BackupId: $BackupId, ClientRequestToken: $ClientRequestToken, Name: $Name, OntapConfiguration: $OntapConfiguration, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes an Amazon FSx backup. After deletion, the backup no longer exists, and its data is gone.</p> <p>The <code>DeleteBackup</code> call returns instantly. The backup won't show up in later <code>DescribeBackups</code> calls.</p> <important> <p>The data in a deleted backup is also deleted and can't be recovered by any means.</p> </important>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteBackup
# operationId: DeleteBackup
export def "x-amz-target-aws-simba-api-service-v20180301-delete-backup DeleteBackup" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-13
  BackupId: any
  --ClientRequestToken: any
]: any -> record<BackupId: record, Lifecycle: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteBackup")
  let body = {BackupId: $BackupId, ClientRequestToken: $ClientRequestToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a data repository association on an Amazon FSx for Lustre file system. Deleting the data repository association unlinks the file system from the Amazon S3 bucket. When deleting a data repository association, you have the option of deleting the data in the file system that corresponds to the data repository association. Data repository associations are supported for all file systems except for <code>Scratch_1</code> deployment type.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteDataRepositoryAssociation
# operationId: DeleteDataRepositoryAssociation
export def "x-amz-target-aws-simba-api-service-v20180301-delete-data-repository-association DeleteDataRepositoryAssociation" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-14
  AssociationId: any
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --DeleteDataInFileSystem: any
]: any -> record<AssociationId: record, Lifecycle: record, DeleteDataInFileSystem: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteDataRepositoryAssociation")
  let body = {AssociationId: $AssociationId, ClientRequestToken: $ClientRequestToken, DeleteDataInFileSystem: $DeleteDataInFileSystem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes an Amazon File Cache resource. After deletion, the cache no longer exists, and its data is gone.</p> <p>The <code>DeleteFileCache</code> operation returns while the cache has the <code>DELETING</code> status. You can check the cache deletion status by calling the <a href="https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileCaches.html">DescribeFileCaches</a> operation, which returns a list of caches in your account. If you pass the cache ID for a deleted cache, the <code>DescribeFileCaches</code> operation returns a <code>FileCacheNotFound</code> error.</p> <important> <p>The data in a deleted cache is also deleted and can't be recovered by any means.</p> </important>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteFileCache
# operationId: DeleteFileCache
export def "x-amz-target-aws-simba-api-service-v20180301-delete-file-cache DeleteFileCache" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-15
  FileCacheId: any
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
]: any -> record<FileCacheId: record, Lifecycle: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteFileCache")
  let body = {FileCacheId: $FileCacheId, ClientRequestToken: $ClientRequestToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes a file system. After deletion, the file system no longer exists, and its data is gone. Any existing automatic backups and snapshots are also deleted.</p> <p>To delete an Amazon FSx for NetApp ONTAP file system, first delete all the volumes and storage virtual machines (SVMs) on the file system. Then provide a <code>FileSystemId</code> value to the <code>DeleFileSystem</code> operation.</p> <p>By default, when you delete an Amazon FSx for Windows File Server file system, a final backup is created upon deletion. This final backup isn't subject to the file system's retention policy, and must be manually deleted.</p> <p>The <code>DeleteFileSystem</code> operation returns while the file system has the <code>DELETING</code> status. You can check the file system deletion status by calling the <a href="https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileSystems.html">DescribeFileSystems</a> operation, which returns a list of file systems in your account. If you pass the file system ID for a deleted file system, the <code>DescribeFileSystems</code> operation returns a <code>FileSystemNotFound</code> error.</p> <note> <p>If a data repository task is in a <code>PENDING</code> or <code>EXECUTING</code> state, deleting an Amazon FSx for Lustre file system will fail with an HTTP status code 400 (Bad Request).</p> </note> <important> <p>The data in a deleted file system is also deleted and can't be recovered by any means.</p> </important>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteFileSystem
# operationId: DeleteFileSystem
# --WindowsConfiguration shape: {SkipFinalBackup?: any, FinalBackupTags?: any}
# --LustreConfiguration shape: {SkipFinalBackup?: any, FinalBackupTags?: any}
export def "x-amz-target-aws-simba-api-service-v20180301-delete-file-system DeleteFileSystem" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-16
  FileSystemId: any
  --ClientRequestToken: any
  --WindowsConfiguration: record # The configuration object for the Microsoft Windows file system used in the <code>DeleteFileSystem</code> operation. — shape: {SkipFinalBackup?: any, FinalBackupTags?: any}
  --LustreConfiguration: record # The configuration object for the Amazon FSx for Lustre file system being deleted in the <code>DeleteFileSystem</code> operation. — shape: {SkipFinalBackup?: any, FinalBackupTags?: any}
  --OpenZFSConfiguration: any
]: any -> record<FileSystemId: record, Lifecycle: record, WindowsResponse: record<FinalBackupId: record, FinalBackupTags: record>, LustreResponse: record<FinalBackupId: record, FinalBackupTags: record>, OpenZFSResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteFileSystem")
  let body = {FileSystemId: $FileSystemId, ClientRequestToken: $ClientRequestToken, WindowsConfiguration: $WindowsConfiguration, LustreConfiguration: $LustreConfiguration, OpenZFSConfiguration: $OpenZFSConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes an Amazon FSx for OpenZFS snapshot. After deletion, the snapshot no longer exists, and its data is gone. Deleting a snapshot doesn't affect snapshots stored in a file system backup. </p> <p>The <code>DeleteSnapshot</code> operation returns instantly. The snapshot appears with the lifecycle status of <code>DELETING</code> until the deletion is complete.</p>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteSnapshot
# operationId: DeleteSnapshot
export def "x-amz-target-aws-simba-api-service-v20180301-delete-snapshot DeleteSnapshot" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-17
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  SnapshotId: any
]: any -> record<SnapshotId: record, Lifecycle: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteSnapshot")
  let body = {ClientRequestToken: $ClientRequestToken, SnapshotId: $SnapshotId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an existing Amazon FSx for ONTAP storage virtual machine (SVM). Prior to deleting an SVM, you must delete all non-root volumes in the SVM, otherwise the operation will fail.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteStorageVirtualMachine
# operationId: DeleteStorageVirtualMachine
export def "x-amz-target-aws-simba-api-service-v20180301-delete-storage-virtual-machine DeleteStorageVirtualMachine" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-18
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  StorageVirtualMachineId: any
]: any -> record<StorageVirtualMachineId: record, Lifecycle: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteStorageVirtualMachine")
  let body = {ClientRequestToken: $ClientRequestToken, StorageVirtualMachineId: $StorageVirtualMachineId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an Amazon FSx for NetApp ONTAP or Amazon FSx for OpenZFS volume.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteVolume
# operationId: DeleteVolume
export def "x-amz-target-aws-simba-api-service-v20180301-delete-volume DeleteVolume" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-19
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  VolumeId: any
  --OntapConfiguration: any
  --OpenZFSConfiguration: any
]: any -> record<VolumeId: record, Lifecycle: record, OntapResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DeleteVolume")
  let body = {ClientRequestToken: $ClientRequestToken, VolumeId: $VolumeId, OntapConfiguration: $OntapConfiguration, OpenZFSConfiguration: $OpenZFSConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns the description of a specific Amazon FSx backup, if a <code>BackupIds</code> value is provided for that backup. Otherwise, it returns all backups owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling.</p> <p>When retrieving all backups, you can optionally specify the <code>MaxResults</code> parameter to limit the number of backups in a response. If more backups remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of the <code>NextToken</code> value from the last response.</p> <p>This operation is used in an iterative process to retrieve a list of your backups. <code>DescribeBackups</code> is called first without a <code>NextToken</code> value. Then the operation continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code> value.</p> <p>When using this operation, keep the following in mind:</p> <ul> <li> <p>The operation might return fewer than the <code>MaxResults</code> value of backup descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of the backups returned in the response of one <code>DescribeBackups</code> call and the order of the backups returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeBackups
# operationId: DescribeBackups
export def "x-amz-target-aws-simba-api-service-v20180301-describe-backups DescribeBackups" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-20
  --BackupIds: any
  --Filters: any
  --MaxResults: any
  --NextToken: any
]: any -> record<Backups: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeBackups" $qp)
  let body = {BackupIds: $BackupIds, Filters: $Filters, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns the description of specific Amazon FSx for Lustre or Amazon File Cache data repository associations, if one or more <code>AssociationIds</code> values are provided in the request, or if filters are used in the request. Data repository associations are supported on Amazon File Cache resources and all Amazon FSx for Lustre file systems excluding <code>Scratch_1</code> deployment types.</p> <p>You can use filters to narrow the response to include just data repository associations for specific file systems (use the <code>file-system-id</code> filter with the ID of the file system) or caches (use the <code>file-cache-id</code> filter with the ID of the cache), or data repository associations for a specific repository type (use the <code>data-repository-type</code> filter with a value of <code>S3</code> or <code>NFS</code>). If you don't use filters, the response returns all data repository associations owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling.</p> <p>When retrieving all data repository associations, you can paginate the response by using the optional <code>MaxResults</code> parameter to limit the number of data repository associations returned in a response. If more data repository associations remain, a <code>NextToken</code> value is returned in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeDataRepositoryAssociations
# operationId: DescribeDataRepositoryAssociations
# --Filters item shape: {Name?: any, Values?: any}
export def "x-amz-target-aws-simba-api-service-v20180301-describe-data-repository-associations DescribeDataRepositoryAssociations" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-21
  --AssociationIds: any
  --Filters: list # A list of <code>Filter</code> elements. — item shape: {Name?: any, Values?: any}
  --MaxResults: any
  --NextToken: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous <code>NextToken</code> value left off.
]: any -> record<Associations: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeDataRepositoryAssociations" $qp)
  let body = {AssociationIds: $AssociationIds, Filters: $Filters, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns the description of specific Amazon FSx for Lustre or Amazon File Cache data repository tasks, if one or more <code>TaskIds</code> values are provided in the request, or if filters are used in the request. You can use filters to narrow the response to include just tasks for specific file systems or caches, or tasks in a specific lifecycle state. Otherwise, it returns all data repository tasks owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling.</p> <p>When retrieving all tasks, you can paginate the response by using the optional <code>MaxResults</code> parameter to limit the number of tasks returned in a response. If more tasks remain, a <code>NextToken</code> value is returned in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeDataRepositoryTasks
# operationId: DescribeDataRepositoryTasks
export def "x-amz-target-aws-simba-api-service-v20180301-describe-data-repository-tasks DescribeDataRepositoryTasks" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-22
  --TaskIds: any
  --Filters: any
  --MaxResults: int # The maximum number of resources to return in the response. This value must be an integer greater than zero.
  --NextToken: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous <code>NextToken</code> value left off.
]: any -> record<DataRepositoryTasks: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeDataRepositoryTasks" $qp)
  let body = {TaskIds: $TaskIds, Filters: $Filters, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns the description of a specific Amazon File Cache resource, if a <code>FileCacheIds</code> value is provided for that cache. Otherwise, it returns descriptions of all caches owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling.</p> <p>When retrieving all cache descriptions, you can optionally specify the <code>MaxResults</code> parameter to limit the number of descriptions in a response. If more cache descriptions remain, the operation returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This operation is used in an iterative process to retrieve a list of your cache descriptions. <code>DescribeFileCaches</code> is called first without a <code>NextToken</code>value. Then the operation continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this operation, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> cache descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of caches returned in the response of one <code>DescribeFileCaches</code> call and the order of caches returned across the responses of a multicall iteration is unspecified.</p> </li> </ul>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileCaches
# operationId: DescribeFileCaches
export def "x-amz-target-aws-simba-api-service-v20180301-describe-file-caches DescribeFileCaches" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-23
  --FileCacheIds: any
  --MaxResults: int # The maximum number of resources to return in the response. This value must be an integer greater than zero.
  --NextToken: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous <code>NextToken</code> value left off.
]: any -> record<FileCaches: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileCaches" $qp)
  let body = {FileCacheIds: $FileCacheIds, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the DNS aliases that are associated with the specified Amazon FSx for Windows File Server file system. A history of all DNS aliases that have been associated with and disassociated from the file system is available in the list of <a>AdministrativeAction</a> provided in the <a>DescribeFileSystems</a> operation response.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileSystemAliases
# operationId: DescribeFileSystemAliases
export def "x-amz-target-aws-simba-api-service-v20180301-describe-file-system-aliases DescribeFileSystemAliases" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-24
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  FileSystemId: any
  --MaxResults: any
  --NextToken: any
]: any -> record<Aliases: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileSystemAliases" $qp)
  let body = {ClientRequestToken: $ClientRequestToken, FileSystemId: $FileSystemId, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns the description of specific Amazon FSx file systems, if a <code>FileSystemIds</code> value is provided for that file system. Otherwise, it returns descriptions of all file systems owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling.</p> <p>When retrieving all file system descriptions, you can optionally specify the <code>MaxResults</code> parameter to limit the number of descriptions in a response. If more file system descriptions remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This operation is used in an iterative process to retrieve a list of your file system descriptions. <code>DescribeFileSystems</code> is called first without a <code>NextToken</code>value. Then the operation continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this operation, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of file systems returned in the response of one <code>DescribeFileSystems</code> call and the order of file systems returned across the responses of a multicall iteration is unspecified.</p> </li> </ul>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileSystems
# operationId: DescribeFileSystems
export def "x-amz-target-aws-simba-api-service-v20180301-describe-file-systems DescribeFileSystems" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-25
  --FileSystemIds: any
  --MaxResults: any
  --NextToken: any
]: any -> record<FileSystems: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeFileSystems" $qp)
  let body = {FileSystemIds: $FileSystemIds, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns the description of specific Amazon FSx for OpenZFS snapshots, if a <code>SnapshotIds</code> value is provided. Otherwise, this operation returns all snapshots owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling.</p> <p>When retrieving all snapshots, you can optionally specify the <code>MaxResults</code> parameter to limit the number of snapshots in a response. If more backups remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response. </p> <p>Use this operation in an iterative process to retrieve a list of your snapshots. <code>DescribeSnapshots</code> is called first without a <code>NextToken</code> value. Then the operation continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code> value.</p> <p>When using this operation, keep the following in mind:</p> <ul> <li> <p>The operation might return fewer than the <code>MaxResults</code> value of snapshot descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of snapshots returned in the response of one <code>DescribeSnapshots</code> call and the order of backups returned across the responses of a multi-call iteration is unspecified. </p> </li> </ul>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeSnapshots
# operationId: DescribeSnapshots
export def "x-amz-target-aws-simba-api-service-v20180301-describe-snapshots DescribeSnapshots" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-26
  --SnapshotIds: any
  --Filters: any
  --MaxResults: int # The maximum number of resources to return in the response. This value must be an integer greater than zero.
  --NextToken: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous <code>NextToken</code> value left off.
]: any -> record<Snapshots: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeSnapshots" $qp)
  let body = {SnapshotIds: $SnapshotIds, Filters: $Filters, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes one or more Amazon FSx for NetApp ONTAP storage virtual machines (SVMs).
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeStorageVirtualMachines
# operationId: DescribeStorageVirtualMachines
export def "x-amz-target-aws-simba-api-service-v20180301-describe-storage-virtual-machines DescribeStorageVirtualMachines" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-27
  --StorageVirtualMachineIds: any
  --Filters: any
  --MaxResults: int # The maximum number of resources to return in the response. This value must be an integer greater than zero.
  --NextToken: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous <code>NextToken</code> value left off.
]: any -> record<StorageVirtualMachines: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeStorageVirtualMachines" $qp)
  let body = {StorageVirtualMachineIds: $StorageVirtualMachineIds, Filters: $Filters, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes one or more Amazon FSx for NetApp ONTAP or Amazon FSx for OpenZFS volumes.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeVolumes
# operationId: DescribeVolumes
export def "x-amz-target-aws-simba-api-service-v20180301-describe-volumes DescribeVolumes" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-28
  --VolumeIds: any
  --Filters: any
  --MaxResults: int # The maximum number of resources to return in the response. This value must be an integer greater than zero.
  --NextToken: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous <code>NextToken</code> value left off.
]: any -> record<Volumes: record, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DescribeVolumes" $qp)
  let body = {VolumeIds: $VolumeIds, Filters: $Filters, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Use this action to disassociate, or remove, one or more Domain Name Service (DNS) aliases from an Amazon FSx for Windows File Server file system. If you attempt to disassociate a DNS alias that is not associated with the file system, Amazon FSx responds with a 400 Bad Request. For more information, see <a href="https://docs.aws.amazon.com/fsx/latest/WindowsGuide/managing-dns-aliases.html">Working with DNS Aliases</a>.</p> <p>The system generated response showing the DNS aliases that Amazon FSx is attempting to disassociate from the file system. Use the API operation to monitor the status of the aliases Amazon FSx is disassociating with the file system.</p>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.DisassociateFileSystemAliases
# operationId: DisassociateFileSystemAliases
export def "x-amz-target-aws-simba-api-service-v20180301-disassociate-file-system-aliases DisassociateFileSystemAliases" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-29
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  FileSystemId: any
  Aliases: any
]: any -> record<Aliases: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.DisassociateFileSystemAliases")
  let body = {ClientRequestToken: $ClientRequestToken, FileSystemId: $FileSystemId, Aliases: $Aliases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Lists tags for Amazon FSx resources.</p> <p>When retrieving all tags, you can optionally specify the <code>MaxResults</code> parameter to limit the number of tags in a response. If more tags remain, Amazon FSx returns a <code>NextToken</code> value in the response. In this case, send a later request with the <code>NextToken</code> request parameter set to the value of <code>NextToken</code> from the last response.</p> <p>This action is used in an iterative process to retrieve a list of your tags. <code>ListTagsForResource</code> is called first without a <code>NextToken</code>value. Then the action continues to be called with the <code>NextToken</code> parameter set to the value of the last <code>NextToken</code> value until a response has no <code>NextToken</code>.</p> <p>When using this action, keep the following in mind:</p> <ul> <li> <p>The implementation might return fewer than <code>MaxResults</code> file system descriptions while still including a <code>NextToken</code> value.</p> </li> <li> <p>The order of tags returned in the response of one <code>ListTagsForResource</code> call and the order of tags returned across the responses of a multi-call iteration is unspecified.</p> </li> </ul>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.ListTagsForResource
# operationId: ListTagsForResource
export def "x-amz-target-aws-simba-api-service-v20180301-list-tags-for-resource ListTagsForResource" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-30
  ResourceARN: any
  --MaxResults: any
  --NextToken: any
]: any -> record<Tags: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.ListTagsForResource" $qp)
  let body = {ResourceARN: $ResourceARN, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Releases the file system lock from an Amazon FSx for OpenZFS file system.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.ReleaseFileSystemNfsV3Locks
# operationId: ReleaseFileSystemNfsV3Locks
export def "x-amz-target-aws-simba-api-service-v20180301-release-file-system-nfs-v3-locks ReleaseFileSystemNfsV3Locks" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-31
  FileSystemId: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
]: any -> record<FileSystem: record<OwnerId: record, CreationTime: record, FileSystemId: record, FileSystemType: record, Lifecycle: record, FailureDetails: record<Message: record>, StorageCapacity: record, StorageType: record, VpcId: record, SubnetIds: record, NetworkInterfaceIds: record, DNSName: record, KmsKeyId: record, ResourceARN: record, Tags: record, WindowsConfiguration: record<ActiveDirectoryId: record, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: record, RemoteAdministrationEndpoint: record, PreferredSubnetId: record, PreferredFileServerIp: record, ThroughputCapacity: record, MaintenanceOperationsInProgress: record, WeeklyMaintenanceStartTime: record, DailyAutomaticBackupStartTime: record, AutomaticBackupRetentionDays: record, CopyTagsToBackups: record, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: record, DataRepositoryConfiguration: record, DeploymentType: record, PerUnitStorageThroughput: record, MountName: record, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, DriveCacheType: record, DataCompressionType: record, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: record, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: record, EndpointIpAddressRange: record, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: record, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: record, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, CopyTagsToVolumes: record, DailyAutomaticBackupStartTime: string, DeploymentType: record, ThroughputCapacity: record, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.ReleaseFileSystemNfsV3Locks")
  let body = {FileSystemId: $FileSystemId, ClientRequestToken: $ClientRequestToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns an Amazon FSx for OpenZFS volume to the state saved by the specified snapshot.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.RestoreVolumeFromSnapshot
# operationId: RestoreVolumeFromSnapshot
export def "x-amz-target-aws-simba-api-service-v20180301-restore-volume-from-snapshot RestoreVolumeFromSnapshot" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-32
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  VolumeId: any
  SnapshotId: any
  --Options: any
]: any -> record<VolumeId: record, Lifecycle: record, AdministrativeActions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.RestoreVolumeFromSnapshot")
  let body = {ClientRequestToken: $ClientRequestToken, VolumeId: $VolumeId, SnapshotId: $SnapshotId, Options: $Options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Tags an Amazon FSx resource.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.TagResource
# operationId: TagResource
export def "x-amz-target-aws-simba-api-service-v20180301-tag-resource TagResource" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-33
  ResourceARN: any
  Tags: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.TagResource")
  let body = {ResourceARN: $ResourceARN, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This action removes a tag from an Amazon FSx resource.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UntagResource
# operationId: UntagResource
export def "x-amz-target-aws-simba-api-service-v20180301-untag-resource UntagResource" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-34
  ResourceARN: any
  TagKeys: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UntagResource")
  let body = {ResourceARN: $ResourceARN, TagKeys: $TagKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the configuration of an existing data repository association on an Amazon FSx for Lustre file system. Data repository associations are supported for all file systems except for <code>Scratch_1</code> deployment type.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateDataRepositoryAssociation
# operationId: UpdateDataRepositoryAssociation
export def "x-amz-target-aws-simba-api-service-v20180301-update-data-repository-association UpdateDataRepositoryAssociation" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-35
  AssociationId: any
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --ImportedFileChunkSize: any
  --S3: any
]: any -> record<Association: record<AssociationId: record, ResourceARN: string, FileSystemId: string, Lifecycle: record, FailureDetails: record<Message: string>, FileSystemPath: record, DataRepositoryPath: record, BatchImportMetaDataOnCreate: record, ImportedFileChunkSize: record, S3: record<AutoImportPolicy: record, AutoExportPolicy: record>, Tags: list<record>, CreationTime: string, FileCacheId: record, FileCachePath: record, DataRepositorySubdirectories: record, NFS: record<Version: record, DnsIps: record, AutoExportPolicy: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateDataRepositoryAssociation")
  let body = {AssociationId: $AssociationId, ClientRequestToken: $ClientRequestToken, ImportedFileChunkSize: $ImportedFileChunkSize, S3: $S3} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the configuration of an existing Amazon File Cache resource. You can update multiple properties in a single request.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateFileCache
# operationId: UpdateFileCache
export def "x-amz-target-aws-simba-api-service-v20180301-update-file-cache UpdateFileCache" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-36
  FileCacheId: any
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --LustreConfiguration: any
]: any -> record<FileCache: record<OwnerId: string, CreationTime: string, FileCacheId: record, FileCacheType: record, FileCacheTypeVersion: record, Lifecycle: record, FailureDetails: record<Message: record>, StorageCapacity: record, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: record, KmsKeyId: record, ResourceARN: string, LustreConfiguration: record<PerUnitStorageThroughput: record, DeploymentType: record, MountName: record, WeeklyMaintenanceStartTime: string, MetadataConfiguration: record, LogConfiguration: record>, DataRepositoryAssociationIds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateFileCache")
  let body = {FileCacheId: $FileCacheId, ClientRequestToken: $ClientRequestToken, LustreConfiguration: $LustreConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Use this operation to update the configuration of an existing Amazon FSx file system. You can update multiple properties in a single request.</p> <p>For FSx for Windows File Server file systems, you can update the following properties:</p> <ul> <li> <p> <code>AuditLogConfiguration</code> </p> </li> <li> <p> <code>AutomaticBackupRetentionDays</code> </p> </li> <li> <p> <code>DailyAutomaticBackupStartTime</code> </p> </li> <li> <p> <code>SelfManagedActiveDirectoryConfiguration</code> </p> </li> <li> <p> <code>StorageCapacity</code> </p> </li> <li> <p> <code>ThroughputCapacity</code> </p> </li> <li> <p> <code>WeeklyMaintenanceStartTime</code> </p> </li> </ul> <p>For FSx for Lustre file systems, you can update the following properties:</p> <ul> <li> <p> <code>AutoImportPolicy</code> </p> </li> <li> <p> <code>AutomaticBackupRetentionDays</code> </p> </li> <li> <p> <code>DailyAutomaticBackupStartTime</code> </p> </li> <li> <p> <code>DataCompressionType</code> </p> </li> <li> <p> <code>LustreRootSquashConfiguration</code> </p> </li> <li> <p> <code>StorageCapacity</code> </p> </li> <li> <p> <code>WeeklyMaintenanceStartTime</code> </p> </li> </ul> <p>For FSx for ONTAP file systems, you can update the following properties:</p> <ul> <li> <p> <code>AddRouteTableIds</code> </p> </li> <li> <p> <code>AutomaticBackupRetentionDays</code> </p> </li> <li> <p> <code>DailyAutomaticBackupStartTime</code> </p> </li> <li> <p> <code>DiskIopsConfiguration</code> </p> </li> <li> <p> <code>FsxAdminPassword</code> </p> </li> <li> <p> <code>RemoveRouteTableIds</code> </p> </li> <li> <p> <code>StorageCapacity</code> </p> </li> <li> <p> <code>ThroughputCapacity</code> </p> </li> <li> <p> <code>WeeklyMaintenanceStartTime</code> </p> </li> </ul> <p>For FSx for OpenZFS file systems, you can update the following properties:</p> <ul> <li> <p> <code>AutomaticBackupRetentionDays</code> </p> </li> <li> <p> <code>CopyTagsToBackups</code> </p> </li> <li> <p> <code>CopyTagsToVolumes</code> </p> </li> <li> <p> <code>DailyAutomaticBackupStartTime</code> </p> </li> <li> <p> <code>DiskIopsConfiguration</code> </p> </li> <li> <p> <code>StorageCapacity</code> </p> </li> <li> <p> <code>ThroughputCapacity</code> </p> </li> <li> <p> <code>WeeklyMaintenanceStartTime</code> </p> </li> </ul>
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateFileSystem
# operationId: UpdateFileSystem
# --LustreConfiguration shape: {WeeklyMaintenanceStartTime?: any, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, AutoImportPolicy?: any, DataCompressionType?: any, LogConfiguration?: any, RootSquashConfiguration?: any}
# --OntapConfiguration shape: {AutomaticBackupRetentionDays?: int, DailyAutomaticBackupStartTime?: string, FsxAdminPassword?: any, WeeklyMaintenanceStartTime?: string, DiskIopsConfiguration?: any, ThroughputCapacity?: any, AddRouteTableIds?: any, RemoveRouteTableIds?: any}
export def "x-amz-target-aws-simba-api-service-v20180301-update-file-system UpdateFileSystem" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-37
  FileSystemId: any
  --ClientRequestToken: any
  --StorageCapacity: any
  --WindowsConfiguration: any
  --LustreConfiguration: record # The configuration object for Amazon FSx for Lustre file systems used in the <code>UpdateFileSystem</code> operation. — shape: {WeeklyMaintenanceStartTime?: any, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, AutoImportPolicy?: any, DataCompressionType?: any, LogConfiguration?: any, RootSquashConfiguration?: any}
  --OntapConfiguration: record # The configuration updates for an Amazon FSx for NetApp ONTAP file system. — shape: {AutomaticBackupRetentionDays?: int, DailyAutomaticBackupStartTime?: string, FsxAdminPassword?: any, WeeklyMaintenanceStartTime?: string, DiskIopsConfiguration?: any, ThroughputCapacity?: any, AddRouteTableIds?: any, RemoveRouteTableIds?: any}
  --OpenZFSConfiguration: any
]: any -> record<FileSystem: record<OwnerId: record, CreationTime: record, FileSystemId: record, FileSystemType: record, Lifecycle: record, FailureDetails: record<Message: record>, StorageCapacity: record, StorageType: record, VpcId: record, SubnetIds: record, NetworkInterfaceIds: record, DNSName: record, KmsKeyId: record, ResourceARN: record, Tags: record, WindowsConfiguration: record<ActiveDirectoryId: record, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: record, RemoteAdministrationEndpoint: record, PreferredSubnetId: record, PreferredFileServerIp: record, ThroughputCapacity: record, MaintenanceOperationsInProgress: record, WeeklyMaintenanceStartTime: record, DailyAutomaticBackupStartTime: record, AutomaticBackupRetentionDays: record, CopyTagsToBackups: record, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: record, DataRepositoryConfiguration: record, DeploymentType: record, PerUnitStorageThroughput: record, MountName: record, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, DriveCacheType: record, DataCompressionType: record, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: record, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: record, EndpointIpAddressRange: record, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: record, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: record, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: record, CopyTagsToVolumes: record, DailyAutomaticBackupStartTime: string, DeploymentType: record, ThroughputCapacity: record, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateFileSystem")
  let body = {FileSystemId: $FileSystemId, ClientRequestToken: $ClientRequestToken, StorageCapacity: $StorageCapacity, WindowsConfiguration: $WindowsConfiguration, LustreConfiguration: $LustreConfiguration, OntapConfiguration: $OntapConfiguration, OpenZFSConfiguration: $OpenZFSConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the name of an Amazon FSx for OpenZFS snapshot.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateSnapshot
# operationId: UpdateSnapshot
export def "x-amz-target-aws-simba-api-service-v20180301-update-snapshot UpdateSnapshot" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-38
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  Name: any
  SnapshotId: any
]: any -> record<Snapshot: record<ResourceARN: string, SnapshotId: record, Name: record, VolumeId: record, CreationTime: string, Lifecycle: record, LifecycleTransitionReason: record<Message: string>, Tags: list<record>, AdministrativeActions: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateSnapshot")
  let body = {ClientRequestToken: $ClientRequestToken, Name: $Name, SnapshotId: $SnapshotId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an Amazon FSx for ONTAP storage virtual machine (SVM).
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateStorageVirtualMachine
# operationId: UpdateStorageVirtualMachine
export def "x-amz-target-aws-simba-api-service-v20180301-update-storage-virtual-machine UpdateStorageVirtualMachine" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-39
  --ActiveDirectoryConfiguration: any
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  StorageVirtualMachineId: any
  --SvmAdminPassword: any
]: any -> record<StorageVirtualMachine: record<ActiveDirectoryConfiguration: record<NetBiosName: record, SelfManagedActiveDirectoryConfiguration: record>, CreationTime: string, Endpoints: record<Iscsi: record, Management: record, Nfs: record, Smb: record>, FileSystemId: string, Lifecycle: record, Name: record, ResourceARN: string, StorageVirtualMachineId: record, Subtype: record, UUID: record, Tags: list<record>, LifecycleTransitionReason: record<Message: string>, RootVolumeSecurityStyle: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateStorageVirtualMachine")
  let body = {ActiveDirectoryConfiguration: $ActiveDirectoryConfiguration, ClientRequestToken: $ClientRequestToken, StorageVirtualMachineId: $StorageVirtualMachineId, SvmAdminPassword: $SvmAdminPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the configuration of an Amazon FSx for NetApp ONTAP or Amazon FSx for OpenZFS volume.
#
# POST /#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateVolume
# operationId: UpdateVolume
export def "x-amz-target-aws-simba-api-service-v20180301-update-volume UpdateVolume" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-40
  --ClientRequestToken: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  VolumeId: any
  --OntapConfiguration: any
  --Name: any
  --OpenZFSConfiguration: any
]: any -> record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: record, Name: record, OntapConfiguration: record<FlexCacheEndpointType: record, JunctionPath: record, SecurityStyle: record, SizeInMegabytes: record, StorageEfficiencyEnabled: record, StorageVirtualMachineId: record, StorageVirtualMachineRoot: record, TieringPolicy: record, UUID: record, OntapVolumeType: record, SnapshotPolicy: record, CopyTagsToBackups: record>, ResourceARN: string, Tags: list<record>, VolumeId: record, VolumeType: record, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: record, OpenZFSConfiguration: record<ParentVolumeId: record, VolumePath: record, StorageCapacityReservationGiB: record, StorageCapacityQuotaGiB: record, RecordSizeKiB: record, DataCompressionType: record, CopyTagsToSnapshots: record, OriginSnapshot: record, ReadOnly: record, NfsExports: record, UserAndGroupQuotas: record, RestoreToSnapshot: record, DeleteIntermediateSnaphots: record, DeleteClonedVolumes: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSSimbaAPIService_v20180301.UpdateVolume")
  let body = {ClientRequestToken: $ClientRequestToken, VolumeId: $VolumeId, OntapConfiguration: $OntapConfiguration, Name: $Name, OpenZFSConfiguration: $OpenZFSConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
