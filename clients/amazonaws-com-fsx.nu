# Auto-generated client for Amazon FSx v2018-03-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/fsx/2018-03-01/openapi.json
# Auth: --token flag or $env.AMAZON_FSX_TOKEN

const BASE_URL = "http://fsx.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_FSX_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
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

def base-url-completer [] { ["http://fsx.us-east-1.amazonaws.com" "http://fsx.us-east-2.amazonaws.com" "http://fsx.us-west-1.amazonaws.com" "http://fsx.us-west-2.amazonaws.com" "http://fsx.us-gov-west-1.amazonaws.com" "http://fsx.us-gov-east-1.amazonaws.com" "http://fsx.ca-central-1.amazonaws.com" "http://fsx.eu-north-1.amazonaws.com" "http://fsx.eu-west-1.amazonaws.com" "http://fsx.eu-west-2.amazonaws.com" "http://fsx.eu-west-3.amazonaws.com" "http://fsx.eu-central-1.amazonaws.com" "http://fsx.eu-south-1.amazonaws.com" "http://fsx.af-south-1.amazonaws.com" "http://fsx.ap-northeast-1.amazonaws.com" "http://fsx.ap-northeast-2.amazonaws.com" "http://fsx.ap-northeast-3.amazonaws.com" "http://fsx.ap-southeast-1.amazonaws.com" "http://fsx.ap-southeast-2.amazonaws.com" "http://fsx.ap-east-1.amazonaws.com" "http://fsx.ap-south-1.amazonaws.com" "http://fsx.sa-east-1.amazonaws.com" "http://fsx.me-south-1.amazonaws.com" "https://fsx.us-east-1.amazonaws.com" "https://fsx.us-east-2.amazonaws.com" "https://fsx.us-west-1.amazonaws.com" "https://fsx.us-west-2.amazonaws.com" "https://fsx.us-gov-west-1.amazonaws.com" "https://fsx.us-gov-east-1.amazonaws.com" "https://fsx.ca-central-1.amazonaws.com" "https://fsx.eu-north-1.amazonaws.com" "https://fsx.eu-west-1.amazonaws.com" "https://fsx.eu-west-2.amazonaws.com" "https://fsx.eu-west-3.amazonaws.com" "https://fsx.eu-central-1.amazonaws.com" "https://fsx.eu-south-1.amazonaws.com" "https://fsx.af-south-1.amazonaws.com" "https://fsx.ap-northeast-1.amazonaws.com" "https://fsx.ap-northeast-2.amazonaws.com" "https://fsx.ap-northeast-3.amazonaws.com" "https://fsx.ap-southeast-1.amazonaws.com" "https://fsx.ap-southeast-2.amazonaws.com" "https://fsx.ap-east-1.amazonaws.com" "https://fsx.ap-south-1.amazonaws.com" "https://fsx.sa-east-1.amazonaws.com" "https://fsx.me-south-1.amazonaws.com" "http://fsx.cn-north-1.amazonaws.com.cn" "http://fsx.cn-northwest-1.amazonaws.com.cn" "https://fsx.cn-north-1.amazonaws.com.cn" "https://fsx.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSSimbaAPIService_v20180301.AssociateFileSystemAliases"] }
def x-amz-target-completer-1 [] { ["AWSSimbaAPIService_v20180301.CancelDataRepositoryTask"] }
def x-amz-target-completer-2 [] { ["AWSSimbaAPIService_v20180301.CopyBackup"] }
def x-amz-target-completer-3 [] { ["AWSSimbaAPIService_v20180301.CreateBackup"] }
def x-amz-target-completer-4 [] { ["AWSSimbaAPIService_v20180301.CreateDataRepositoryAssociation"] }
def type-completer [] { ["AUTO_RELEASE_DATA" "EXPORT_TO_REPOSITORY" "IMPORT_METADATA_FROM_REPOSITORY" "RELEASE_DATA_FROM_FILESYSTEM"] }
def x-amz-target-completer-5 [] { ["AWSSimbaAPIService_v20180301.CreateDataRepositoryTask"] }
def file-cache-type-completer [] { ["LUSTRE"] }
def x-amz-target-completer-6 [] { ["AWSSimbaAPIService_v20180301.CreateFileCache"] }
def file-system-type-completer [] { ["LUSTRE" "ONTAP" "OPENZFS" "WINDOWS"] }
def storage-type-completer [] { ["HDD" "SSD"] }
def x-amz-target-completer-7 [] { ["AWSSimbaAPIService_v20180301.CreateFileSystem"] }
def x-amz-target-completer-8 [] { ["AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup"] }
def x-amz-target-completer-9 [] { ["AWSSimbaAPIService_v20180301.CreateSnapshot"] }
def root-volume-security-style-completer [] { ["MIXED" "NTFS" "UNIX"] }
def x-amz-target-completer-10 [] { ["AWSSimbaAPIService_v20180301.CreateStorageVirtualMachine"] }
def volume-type-completer [] { ["ONTAP" "OPENZFS"] }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-file-system-aliases" "cancel-data-repository-task" "copy-backup" "create-backup" "create-data-repository-association" "create-data-repository-task" "create-file-cache" "create-file-system" "create-file-system-from-backup" "create-snapshot" "create-storage-virtual-machine" "create-volume" "create-volume-from-backup" "delete-backup" "delete-data-repository-association" "delete-file-cache" "delete-file-system" "delete-snapshot" "delete-storage-virtual-machine" "delete-volume" "describe-backups" "describe-data-repository-associations" "describe-data-repository-tasks" "describe-file-caches" "describe-file-system-aliases" "describe-file-systems" "describe-snapshots" "describe-storage-virtual-machines" "describe-volumes" "disassociate-file-system-aliases" "list-tags-for-resource" "release-file-system-nfs-v3-locks" "restore-volume-from-snapshot" "tag-resource" "untag-resource" "update-data-repository-association" "update-file-cache" "update-file-system" "update-snapshot" "update-storage-virtual-machine" "update-volume" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
# POST /
# operationId: AssociateFileSystemAliases
export def "associate-file-system-aliases" [
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  aliases: list<string> # An array of one or more DNS alias names to associate with the file system. The alias name has to comply with the following formatting requirements: Formatted as a fully-qualified domain name (FQDN), hostname.domain , for example, accounting.corp.example.com. Can contain alphanumeric characters and the hyphen (-). Cannot start or end with a hyphen. Can start with a numeric. For DNS alias names, Amazon FSx stores alphabetic characters as lowercase letters (a-z), regardless of how you specify them: as uppercase letters, lowercase letters, or the corresponding letters in escape codes.
]: any -> oneof<record<Aliases: table<Name: string, Lifecycle: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.AssociateFileSystemAliases")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "FileSystemId": $file_system_id, "Aliases": $aliases} | compact
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

# Cancels an existing Amazon FSx for Lustre data repository task if that task is in either the PENDING or EXECUTING state. When you cancel a task, Amazon FSx does the following. Any files that FSx has already exported are not reverted. FSx continues to export any files that are "in-flight" when the cancel operation is received. FSx does not export any files that have not yet been exported.
#
# POST /
# operationId: CancelDataRepositoryTask
export def "cancel-data-repository-task" [
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
  task_id: string # Specifies the data repository task to cancel.
]: any -> oneof<record<Lifecycle: string, TaskId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.CancelDataRepositoryTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TaskId": $task_id} | compact
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

# Copies an existing backup within the same Amazon Web Services account to another Amazon Web Services Region (cross-Region copy) or within the same Amazon Web Services Region (in-Region copy). You can have up to five backup copy requests in progress to a single destination Region per account. You can use cross-Region backup copies for cross-Region disaster recovery. You can periodically take backups and copy them to another Region so that in the event of a disaster in the primary Region, you can restore from backup and recover availability quickly in the other Region. You can make cross-Region copies only within your Amazon Web Services partition. A partition is a grouping of Regions. Amazon Web Services currently has three partitions: aws (Standard Regions), aws-cn (China Regions), and aws-us-gov (Amazon Web Services GovCloud [US] Regions). You can also use backup copies to clone your file dataset to another Region or within the same Region. You can use the SourceRegion parameter to specify the Amazon Web Services Region from which the backup will be copied. For example, if you make the call from the us-west-1 Region and want to copy a backup from the us-east-2 Region, you specify us-east-2 in the SourceRegion parameter to make a cross-Region copy. If you don't specify a Region, the backup copy is created in the same Region where the request is sent from (in-Region copy). For more information about creating backup copies, see Copying backups (https://docs.aws.amazon.com/fsx/latest/WindowsGuide/using-backups.html#copy-backups) in the Amazon FSx for Windows User Guide, Copying backups (https://docs.aws.amazon.com/fsx/latest/LustreGuide/using-backups-fsx.html#copy-backups) in the Amazon FSx for Lustre User Guide, and Copying backups (https://docs.aws.amazon.com/fsx/latest/OpenZFSGuide/using-backups.html#copy-backups) in the Amazon FSx for OpenZFS User Guide.
#
# POST /
# operationId: CopyBackup
export def "copy-backup" [
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  source_backup_id: string # The ID of the source backup. Specifies the ID of the backup that's being copied.
  --source-region: string # The source Amazon Web Services Region of the backup. Specifies the Amazon Web Services Region from which the backup is being copied. The source and destination Regions must be in the same Amazon Web Services partition. If you don't specify a Region, SourceRegion defaults to the Region where the request is sent from (in-Region copy).
  --kms-key-id: string # Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows: Amazon FSx for Lustre PERSISTENT_1 and PERSISTENT_2 deployment types only. SCRATCH_1 and SCRATCH_2 types are encrypted using the Amazon FSx service KMS key for your account. Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server If a KmsKeyId isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see Encrypt (https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html) in the Key Management Service API Reference.
  --copy-tags: oneof<nothing, bool> # A Boolean flag indicating whether tags from the source backup should be copied to the backup copy. This value defaults to false. If you set CopyTags to true and the source backup has existing tags, you can use the Tags parameter to create new tags, provided that the sum of the source backup tags and the new tags doesn't exceed 50. Both sets of tags are merged. If there are tag conflicts (for example, two tags with the same key but different values), the tags created with the Tags parameter take precedence.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
]: any -> oneof<record<Backup: record<BackupId: string, Lifecycle: string, FailureDetails: record<Message: string>, Type: string, ProgressPercent: int, CreationTime: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list, NetworkInterfaceIds: list, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list, WindowsConfiguration: record, LustreConfiguration: record, AdministrativeActions: list, OntapConfiguration: record, FileSystemTypeVersion: string, OpenZFSConfiguration: record>, DirectoryInformation: record<DomainName: string, ActiveDirectoryId: string, ResourceARN: string>, OwnerId: string, SourceBackupId: string, SourceBackupRegion: string, ResourceType: string, Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record, ResourceARN: string, Tags: list, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record, AdministrativeActions: list, OpenZFSConfiguration: record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.CopyBackup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "SourceBackupId": $source_backup_id, "SourceRegion": $source_region, "KmsKeyId": $kms_key_id, "CopyTags": $copy_tags, "Tags": $tags} | compact
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

# Creates a backup of an existing Amazon FSx for Windows File Server file system, Amazon FSx for Lustre file system, Amazon FSx for NetApp ONTAP volume, or Amazon FSx for OpenZFS file system. We recommend creating regular backups so that you can restore a file system or volume from a backup if an issue arises with the original file system or volume. For Amazon FSx for Lustre file systems, you can create a backup only for file systems that have the following configuration: A Persistent deployment type Are not linked to a data repository For more information about backups, see the following: For Amazon FSx for Lustre, see Working with FSx for Lustre backups (https://docs.aws.amazon.com/fsx/latest/LustreGuide/using-backups-fsx.html). For Amazon FSx for Windows, see Working with FSx for Windows backups (https://docs.aws.amazon.com/fsx/latest/WindowsGuide/using-backups.html). For Amazon FSx for NetApp ONTAP, see Working with FSx for NetApp ONTAP backups (https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/using-backups.html). For Amazon FSx for OpenZFS, see Working with FSx for OpenZFS backups (https://docs.aws.amazon.com/fsx/latest/OpenZFSGuide/using-backups.html). If a backup with the specified client request token exists and the parameters match, this operation returns the description of the existing backup. If a backup with the specified client request token exists and the parameters don't match, this operation returns IncompatibleParameterError. If a backup with the specified client request token doesn't exist, CreateBackup does the following: Creates a new Amazon FSx backup with an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the backup. By using the idempotent operation, you can retry a CreateBackup operation without the risk of creating an extra backup. This approach can be useful when an initial call fails in a way that makes it unclear whether a backup was created. If you use the same client request token and the initial call created a backup, the operation returns a successful result because all the parameters are the same. The CreateBackup operation returns while the backup's lifecycle state is still CREATING. You can check the backup creation status by calling the DescribeBackups (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeBackups.html) operation, which returns the backup state along with other information.
#
# POST /
# operationId: CreateBackup
export def "create-backup" [
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
  --file-system-id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --volume-id: string # (Optional) The ID of the FSx for ONTAP volume to back up.
]: any -> oneof<record<Backup: record<BackupId: string, Lifecycle: string, FailureDetails: record<Message: string>, Type: string, ProgressPercent: int, CreationTime: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list, NetworkInterfaceIds: list, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list, WindowsConfiguration: record, LustreConfiguration: record, AdministrativeActions: list, OntapConfiguration: record, FileSystemTypeVersion: string, OpenZFSConfiguration: record>, DirectoryInformation: record<DomainName: string, ActiveDirectoryId: string, ResourceARN: string>, OwnerId: string, SourceBackupId: string, SourceBackupRegion: string, ResourceType: string, Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record, ResourceARN: string, Tags: list, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record, AdministrativeActions: list, OpenZFSConfiguration: record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.CreateBackup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FileSystemId": $file_system_id, "ClientRequestToken": $client_request_token, "Tags": $tags, "VolumeId": $volume_id} | compact
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

# Creates an Amazon FSx for Lustre data repository association (DRA). A data repository association is a link between a directory on the file system and an Amazon S3 bucket or prefix. You can have a maximum of 8 data repository associations on a file system. Data repository associations are supported for all file systems except for Scratch_1 deployment type. Each data repository association must have a unique Amazon FSx file system directory and a unique S3 bucket or prefix associated with it. You can configure a data repository association for automatic import only, for automatic export only, or for both. To learn more about linking a data repository to your file system, see Linking your file system to an S3 bucket (https://docs.aws.amazon.com/fsx/latest/LustreGuide/create-dra-linked-data-repo.html). CreateDataRepositoryAssociation isn't supported on Amazon File Cache resources. To create a DRA on Amazon File Cache, use the CreateFileCache operation.
#
# POST /
# operationId: CreateDataRepositoryAssociation
export def "create-data-repository-association" [
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
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --file-system-path: string # A path on the file system that points to a high-level directory (such as /ns1/) or subdirectory (such as /ns1/subdir/) that will be mapped 1-1 with DataRepositoryPath. The leading forward slash in the name is required. Two data repository associations cannot have overlapping file system paths. For example, if a data repository is associated with file system path /ns1/, then you cannot link another data repository with file system path /ns1/ns2. This path specifies where in your file system files will be exported from or imported to. This file system directory can be linked to only one Amazon S3 bucket, and no other S3 bucket can be linked to the directory. If you specify only a forward slash (/) as the file system path, you can link only one data repository to the file system. You can only specify "/" as the file system path for the first data repository associated with a file system.
  data_repository_path: string # The path to the Amazon S3 data repository that will be linked to the file system. The path can be an S3 bucket or prefix in the format s3://myBucket/myPrefix/. This path specifies where in the S3 data repository files will be imported from or exported to.
  --batch-import-meta-data-on-create: oneof<nothing, bool> # Set to true to run an import data repository task to import metadata from the data repository to the file system after the data repository association is created. Default is false.
  --imported-file-chunk-size: int # For files imported from a data repository, this value determines the stripe count and maximum amount of data per file (in MiB) stored on a single physical disk. The maximum number of disks that a single file can be striped across is limited by the total number of disks that make up the file system. The default chunk size is 1,024 MiB (1 GiB) and can go as high as 512,000 MiB (500 GiB). Amazon S3 objects have a maximum size of 5 TB.
  --s3: record # The configuration for an Amazon S3 data repository linked to an Amazon FSx for Lustre file system with a data repository association. The configuration consists of an AutoImportPolicy that defines which file events on the data repository are automatically imported to the file system and an AutoExportPolicy that defines which file events on the file system are automatically exported to the data repository. File events are when files or directories are added, changed, or deleted on the file system or the data repository. Data repository associations on Amazon File Cache don't use S3DataRepositoryConfiguration because they don't support automatic import or automatic export. — shape: {AutoImportPolicy?: record, AutoExportPolicy?: record}
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
]: any -> oneof<record<Association: record<AssociationId: string, ResourceARN: string, FileSystemId: string, Lifecycle: string, FailureDetails: record<Message: string>, FileSystemPath: string, DataRepositoryPath: string, BatchImportMetaDataOnCreate: bool, ImportedFileChunkSize: int, S3: record<AutoImportPolicy: record, AutoExportPolicy: record>, Tags: list<record>, CreationTime: string, FileCacheId: string, FileCachePath: string, DataRepositorySubdirectories: list<string>, NFS: record<Version: string, DnsIps: list, AutoExportPolicy: record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.CreateDataRepositoryAssociation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FileSystemId": $file_system_id, "FileSystemPath": $file_system_path, "DataRepositoryPath": $data_repository_path, "BatchImportMetaDataOnCreate": $batch_import_meta_data_on_create, "ImportedFileChunkSize": $imported_file_chunk_size, "S3": $s3, "ClientRequestToken": $client_request_token, "Tags": $tags} | compact
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

# Creates an Amazon FSx for Lustre data repository task. You use data repository tasks to perform bulk operations between your Amazon FSx file system and its linked data repositories. An example of a data repository task is exporting any data and metadata changes, including POSIX metadata, to files, directories, and symbolic links (symlinks) from your FSx file system to a linked data repository. A CreateDataRepositoryTask operation will fail if a data repository is not linked to the FSx file system. To learn more about data repository tasks, see Data Repository Tasks (https://docs.aws.amazon.com/fsx/latest/LustreGuide/data-repository-tasks.html). To learn more about linking a data repository to your file system, see Linking your file system to an S3 bucket (https://docs.aws.amazon.com/fsx/latest/LustreGuide/create-dra-linked-data-repo.html).
#
# POST /
# operationId: CreateDataRepositoryTask
export def "create-data-repository-task" [
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
  type: string@type-completer # Specifies the type of data repository task to create.
  --paths: list<string> # A list of paths for the data repository task to use when the task is processed. If a path that you provide isn't valid, the task fails. For export tasks, the list contains paths on the Amazon FSx file system from which the files are exported to the Amazon S3 bucket. The default path is the file system root directory. The paths you provide need to be relative to the mount point of the file system. If the mount point is /mnt/fsx and /mnt/fsx/path1 is a directory or file on the file system you want to export, then the path to provide is path1. For import tasks, the list contains paths in the Amazon S3 bucket from which POSIX metadata changes are imported to the Amazon FSx file system. The path can be an S3 bucket or prefix in the format s3://myBucket/myPrefix (where myPrefix is optional).
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  report: record # Provides a report detailing the data repository task results of the files processed that match the criteria specified in the report Scope parameter. FSx delivers the report to the file system's linked data repository in Amazon S3, using the path specified in the report Path parameter. You can specify whether or not a report gets generated for a task using the Enabled parameter. — shape: {Enabled: bool, Path?: string, Format?: "REPORT_CSV_20191124", Scope?: "FAILED_FILES_ONLY"}
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --capacity-to-release: int # Specifies the amount of data to release, in GiB, by an Amazon File Cache AUTO_RELEASE_DATA task that automatically releases files from the cache.
]: any -> oneof<record<DataRepositoryTask: record<TaskId: string, Lifecycle: string, Type: string, CreationTime: string, StartTime: string, EndTime: string, ResourceARN: string, Tags: list<record>, FileSystemId: string, Paths: list<string>, FailureDetails: record<Message: string>, Status: record<TotalCount: int, SucceededCount: int, FailedCount: int, LastUpdatedTime: string, ReleasedCapacity: int>, Report: record<Enabled: bool, Path: string, Format: string, Scope: string>, CapacityToRelease: int, FileCacheId: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.CreateDataRepositoryTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Type": $type, "Paths": $paths, "FileSystemId": $file_system_id, "Report": $report, "ClientRequestToken": $client_request_token, "Tags": $tags, "CapacityToRelease": $capacity_to_release} | compact
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

# Creates a new Amazon File Cache resource. You can use this operation with a client request token in the request that Amazon File Cache uses to ensure idempotent creation. If a cache with the specified client request token exists and the parameters match, CreateFileCache returns the description of the existing cache. If a cache with the specified client request token exists and the parameters don't match, this call returns IncompatibleParameterError. If a file cache with the specified client request token doesn't exist, CreateFileCache does the following: Creates a new, empty Amazon File Cache resourcewith an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the cache in JSON format. The CreateFileCache call returns while the cache's lifecycle state is still CREATING. You can check the cache creation status by calling the DescribeFileCaches (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileCaches.html) operation, which returns the cache state along with other information.
#
# POST /
# operationId: CreateFileCache
export def "create-file-cache" [
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_cache_type: string@file-cache-type-completer # The type of cache that you're creating, which must be LUSTRE.
  file_cache_type_version: string # Sets the Lustre version for the cache that you're creating, which must be 2.12.
  storage_capacity: int # The storage capacity for your Amazon FSx file system, in gibibytes.
  subnet_ids: list<string> # A list of subnet IDs that the cache will be accessible from. You can specify only one subnet ID in a call to the CreateFileCache operation.
  --security-group-ids: list<string> # A list of IDs specifying the security groups to apply to all network interfaces created for file system access. This list isn't returned in later requests to describe the file system.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --copy-tags-to-data-repository-associations: oneof<nothing, bool> # A boolean flag indicating whether tags for the cache should be copied to data repository associations. This value defaults to false.
  --kms-key-id: string # Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows: Amazon FSx for Lustre PERSISTENT_1 and PERSISTENT_2 deployment types only. SCRATCH_1 and SCRATCH_2 types are encrypted using the Amazon FSx service KMS key for your account. Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server If a KmsKeyId isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see Encrypt (https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html) in the Key Management Service API Reference.
  --lustre-configuration: record # The Amazon File Cache configuration for the cache that you are creating. — shape: {PerUnitStorageThroughput: int, DeploymentType: "CACHE_1", WeeklyMaintenanceStartTime?: string, MetadataConfiguration: record}
  --data-repository-associations: list # A list of up to 8 configurations for data repository associations (DRAs) to be created during the cache creation. The DRAs link the cache to either an Amazon S3 data repository or a Network File System (NFS) data repository that supports the NFSv3 protocol. The DRA configurations must meet the following requirements: All configurations on the list must be of the same data repository type, either all S3 or all NFS. A cache can't link to different data repository types at the same time. An NFS DRA must link to an NFS file system that supports the NFSv3 protocol. DRA automatic import and automatic export is not supported. — item shape: {FileCachePath: string, DataRepositoryPath: string, DataRepositorySubdirectories?: list<string>, NFS?: record}
]: any -> oneof<record<FileCache: record<OwnerId: string, CreationTime: string, FileCacheId: string, FileCacheType: string, FileCacheTypeVersion: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, CopyTagsToDataRepositoryAssociations: bool, LustreConfiguration: record<PerUnitStorageThroughput: int, DeploymentType: string, MountName: string, WeeklyMaintenanceStartTime: string, MetadataConfiguration: record, LogConfiguration: record>, DataRepositoryAssociationIds: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.CreateFileCache")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "FileCacheType": $file_cache_type, "FileCacheTypeVersion": $file_cache_type_version, "StorageCapacity": $storage_capacity, "SubnetIds": $subnet_ids, "SecurityGroupIds": $security_group_ids, "Tags": $tags, "CopyTagsToDataRepositoryAssociations": $copy_tags_to_data_repository_associations, "KmsKeyId": $kms_key_id, "LustreConfiguration": $lustre_configuration, "DataRepositoryAssociations": $data_repository_associations} | compact
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

# Creates a new, empty Amazon FSx file system. You can create the following supported Amazon FSx file systems using the CreateFileSystem API operation: Amazon FSx for Lustre Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server This operation requires a client request token in the request that Amazon FSx uses to ensure idempotent creation. This means that calling the operation multiple times with the same client request token has no effect. By using the idempotent operation, you can retry a CreateFileSystem operation without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives success as long as the parameters are the same. If a file system with the specified client request token exists and the parameters match, CreateFileSystem returns the description of the existing file system. If a file system with the specified client request token exists and the parameters don't match, this call returns IncompatibleParameterError. If a file system with the specified client request token doesn't exist, CreateFileSystem does the following: Creates a new, empty Amazon FSx file system with an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the file system in JSON format. The CreateFileSystem call returns while the file system's lifecycle state is still CREATING. You can check the file-system creation status by calling the DescribeFileSystems (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileSystems.html) operation, which returns the file system state along with other information.
#
# POST /
# operationId: CreateFileSystem
export def "create-file-system" [
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_type: string@file-system-type-completer # The type of file system.
  storage_capacity: int # The storage capacity for your Amazon FSx file system, in gibibytes.
  --storage-type: string@storage-type-completer # The storage type for your Amazon FSx file system.
  subnet_ids: list<string> # A list of subnet IDs that the cache will be accessible from. You can specify only one subnet ID in a call to the CreateFileCache operation.
  --security-group-ids: list<string> # A list of IDs specifying the security groups to apply to all network interfaces created for file system access. This list isn't returned in later requests to describe the file system.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --kms-key-id: string # Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows: Amazon FSx for Lustre PERSISTENT_1 and PERSISTENT_2 deployment types only. SCRATCH_1 and SCRATCH_2 types are encrypted using the Amazon FSx service KMS key for your account. Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server If a KmsKeyId isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see Encrypt (https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html) in the Key Management Service API Reference.
  --windows-configuration: record # The configuration object for the Microsoft Windows file system used in CreateFileSystem and CreateFileSystemFromBackup operations. — shape: {ActiveDirectoryId?: string, SelfManagedActiveDirectoryConfiguration?: record, DeploymentType?: "MULTI_AZ_1"|"SINGLE_AZ_1"|"SINGLE_AZ_2", PreferredSubnetId?: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime?: string, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, Aliases?: list<string>, AuditLogConfiguration?: record}
  --lustre-configuration: record # The Lustre configuration for the file system being created. The following parameters are not supported for file systems with a data repository association created with . AutoImportPolicy ExportPath ImportedChunkSize ImportPath — shape: {WeeklyMaintenanceStartTime?: string, ImportPath?: string, ExportPath?: string, ImportedFileChunkSize?: int, DeploymentType?: "SCRATCH_1"|"SCRATCH_2"|"PERSISTENT_1"|"PERSISTENT_2", AutoImportPolicy?: "NONE"|"NEW"|"NEW_CHANGED"|"NEW_CHANGED_DELETED", PerUnitStorageThroughput?: int, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, DriveCacheType?: "NONE"|"READ", DataCompressionType?: "NONE"|"LZ4", LogConfiguration?: record, ... (1 more fields)}
  --ontap-configuration: record # The ONTAP configuration properties of the FSx for ONTAP file system that you are creating. — shape: {AutomaticBackupRetentionDays?: int, DailyAutomaticBackupStartTime?: string, DeploymentType: "MULTI_AZ_1"|"SINGLE_AZ_1", EndpointIpAddressRange?: string, FsxAdminPassword?: string, DiskIopsConfiguration?: record, PreferredSubnetId?: string, RouteTableIds?: list<string>, ThroughputCapacity: int, WeeklyMaintenanceStartTime?: string}
  --file-system-type-version: string # (Optional) For FSx for Lustre file systems, sets the Lustre version for the file system that you're creating. Valid values are 2.10 and 2.12: 2.10 is supported by the Scratch and Persistent_1 Lustre deployment types. 2.12 is supported by all Lustre deployment types. 2.12 is required when setting FSx for Lustre DeploymentType to PERSISTENT_2. Default value = 2.10, except when DeploymentType is set to PERSISTENT_2, then the default is 2.12. If you set FileSystemTypeVersion to 2.10 for a PERSISTENT_2 Lustre deployment type, the CreateFileSystem operation fails.
  --open-zfs-configuration: record # The Amazon FSx for OpenZFS configuration properties for the file system that you are creating. — shape: {AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, CopyTagsToVolumes?: bool, DailyAutomaticBackupStartTime?: string, DeploymentType: "SINGLE_AZ_1"|"SINGLE_AZ_2", ThroughputCapacity: int, WeeklyMaintenanceStartTime?: string, DiskIopsConfiguration?: record, RootVolumeConfiguration?: record}
]: any -> oneof<record<FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, WindowsConfiguration: record<ActiveDirectoryId: string, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: string, RemoteAdministrationEndpoint: string, PreferredSubnetId: string, PreferredFileServerIp: string, ThroughputCapacity: int, MaintenanceOperationsInProgress: list, WeeklyMaintenanceStartTime: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: string, DataRepositoryConfiguration: record, DeploymentType: string, PerUnitStorageThroughput: int, MountName: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, DriveCacheType: string, DataCompressionType: string, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: list<record>, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: string, EndpointIpAddressRange: string, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: list, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: string, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, CopyTagsToVolumes: bool, DailyAutomaticBackupStartTime: string, DeploymentType: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.CreateFileSystem")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "FileSystemType": $file_system_type, "StorageCapacity": $storage_capacity, "StorageType": $storage_type, "SubnetIds": $subnet_ids, "SecurityGroupIds": $security_group_ids, "Tags": $tags, "KmsKeyId": $kms_key_id, "WindowsConfiguration": $windows_configuration, "LustreConfiguration": $lustre_configuration, "OntapConfiguration": $ontap_configuration, "FileSystemTypeVersion": $file_system_type_version, "OpenZFSConfiguration": $open_zfs_configuration} | compact
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

# Creates a new Amazon FSx for Lustre, Amazon FSx for Windows File Server, or Amazon FSx for OpenZFS file system from an existing Amazon FSx backup. If a file system with the specified client request token exists and the parameters match, this operation returns the description of the file system. If a file system with the specified client request token exists but the parameters don't match, this call returns IncompatibleParameterError. If a file system with the specified client request token doesn't exist, this operation does the following: Creates a new Amazon FSx file system from backup with an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the file system. Parameters like the Active Directory, default share name, automatic backup, and backup settings default to the parameters of the file system that was backed up, unless overridden. You can explicitly supply other settings. By using the idempotent operation, you can retry a CreateFileSystemFromBackup call without the risk of creating an extra file system. This approach can be useful when an initial call fails in a way that makes it unclear whether a file system was created. Examples are if a transport level timeout occurred, or your connection was reset. If you use the same client request token and the initial call created a file system, the client receives a success message as long as the parameters are the same. The CreateFileSystemFromBackup call returns while the file system's lifecycle state is still CREATING. You can check the file-system creation status by calling the DescribeFileSystems (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileSystems.html) operation, which returns the file system state along with other information.
#
# POST /
# operationId: CreateFileSystemFromBackup
export def "create-file-system-from-backup" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  backup_id: string # The ID of the source backup. Specifies the backup that you are copying.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  subnet_ids: list<string> # A list of subnet IDs that the cache will be accessible from. You can specify only one subnet ID in a call to the CreateFileCache operation.
  --security-group-ids: list<string> # A list of IDs specifying the security groups to apply to all network interfaces created for file system access. This list isn't returned in later requests to describe the file system.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --windows-configuration: record # The configuration object for the Microsoft Windows file system used in CreateFileSystem and CreateFileSystemFromBackup operations. — shape: {ActiveDirectoryId?: string, SelfManagedActiveDirectoryConfiguration?: record, DeploymentType?: "MULTI_AZ_1"|"SINGLE_AZ_1"|"SINGLE_AZ_2", PreferredSubnetId?: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime?: string, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, Aliases?: list<string>, AuditLogConfiguration?: record}
  --lustre-configuration: record # The Lustre configuration for the file system being created. The following parameters are not supported for file systems with a data repository association created with . AutoImportPolicy ExportPath ImportedChunkSize ImportPath — shape: {WeeklyMaintenanceStartTime?: string, ImportPath?: string, ExportPath?: string, ImportedFileChunkSize?: int, DeploymentType?: "SCRATCH_1"|"SCRATCH_2"|"PERSISTENT_1"|"PERSISTENT_2", AutoImportPolicy?: "NONE"|"NEW"|"NEW_CHANGED"|"NEW_CHANGED_DELETED", PerUnitStorageThroughput?: int, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, DriveCacheType?: "NONE"|"READ", DataCompressionType?: "NONE"|"LZ4", LogConfiguration?: record, ... (1 more fields)}
  --storage-type: string@storage-type-completer # The storage type for your Amazon FSx file system.
  --kms-key-id: string # Specifies the ID of the Key Management Service (KMS) key to use for encrypting data on Amazon FSx file systems, as follows: Amazon FSx for Lustre PERSISTENT_1 and PERSISTENT_2 deployment types only. SCRATCH_1 and SCRATCH_2 types are encrypted using the Amazon FSx service KMS key for your account. Amazon FSx for NetApp ONTAP Amazon FSx for OpenZFS Amazon FSx for Windows File Server If a KmsKeyId isn't specified, the Amazon FSx-managed KMS key for your account is used. For more information, see Encrypt (https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html) in the Key Management Service API Reference.
  --file-system-type-version: string # Sets the version for the Amazon FSx for Lustre file system that you're creating from a backup. Valid values are 2.10 and 2.12. You don't need to specify FileSystemTypeVersion because it will be applied using the backup's FileSystemTypeVersion setting. If you choose to specify FileSystemTypeVersion when creating from backup, the value must match the backup's FileSystemTypeVersion setting.
  --open-zfs-configuration: record # The Amazon FSx for OpenZFS configuration properties for the file system that you are creating. — shape: {AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, CopyTagsToVolumes?: bool, DailyAutomaticBackupStartTime?: string, DeploymentType: "SINGLE_AZ_1"|"SINGLE_AZ_2", ThroughputCapacity: int, WeeklyMaintenanceStartTime?: string, DiskIopsConfiguration?: record, RootVolumeConfiguration?: record}
  --storage-capacity: int # The storage capacity for your Amazon FSx file system, in gibibytes.
]: any -> oneof<record<FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, WindowsConfiguration: record<ActiveDirectoryId: string, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: string, RemoteAdministrationEndpoint: string, PreferredSubnetId: string, PreferredFileServerIp: string, ThroughputCapacity: int, MaintenanceOperationsInProgress: list, WeeklyMaintenanceStartTime: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: string, DataRepositoryConfiguration: record, DeploymentType: string, PerUnitStorageThroughput: int, MountName: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, DriveCacheType: string, DataCompressionType: string, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: list<record>, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: string, EndpointIpAddressRange: string, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: list, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: string, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, CopyTagsToVolumes: bool, DailyAutomaticBackupStartTime: string, DeploymentType: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.CreateFileSystemFromBackup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BackupId": $backup_id, "ClientRequestToken": $client_request_token, "SubnetIds": $subnet_ids, "SecurityGroupIds": $security_group_ids, "Tags": $tags, "WindowsConfiguration": $windows_configuration, "LustreConfiguration": $lustre_configuration, "StorageType": $storage_type, "KmsKeyId": $kms_key_id, "FileSystemTypeVersion": $file_system_type_version, "OpenZFSConfiguration": $open_zfs_configuration, "StorageCapacity": $storage_capacity} | compact
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

# Creates a snapshot of an existing Amazon FSx for OpenZFS volume. With snapshots, you can easily undo file changes and compare file versions by restoring the volume to a previous version. If a snapshot with the specified client request token exists, and the parameters match, this operation returns the description of the existing snapshot. If a snapshot with the specified client request token exists, and the parameters don't match, this operation returns IncompatibleParameterError. If a snapshot with the specified client request token doesn't exist, CreateSnapshot does the following: Creates a new OpenZFS snapshot with an assigned ID, and an initial lifecycle state of CREATING. Returns the description of the snapshot. By using the idempotent operation, you can retry a CreateSnapshot operation without the risk of creating an extra snapshot. This approach can be useful when an initial call fails in a way that makes it unclear whether a snapshot was created. If you use the same client request token and the initial call created a snapshot, the operation returns a successful result because all the parameters are the same. The CreateSnapshot operation returns while the snapshot's lifecycle state is still CREATING. You can check the snapshot creation status by calling the DescribeSnapshots (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeSnapshots.html) operation, which returns the snapshot state along with other information.
#
# POST /
# operationId: CreateSnapshot
export def "create-snapshot" [
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  name: string # The name of the snapshot.
  volume_id: string # The ID of the volume that you are taking a snapshot of.
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
]: any -> oneof<record<Snapshot: record<ResourceARN: string, SnapshotId: string, Name: string, VolumeId: string, CreationTime: string, Lifecycle: string, LifecycleTransitionReason: record<Message: string>, Tags: list<record>, AdministrativeActions: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.CreateSnapshot")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "Name": $name, "VolumeId": $volume_id, "Tags": $tags} | compact
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

# Creates a storage virtual machine (SVM) for an Amazon FSx for ONTAP file system.
#
# POST /
# operationId: CreateStorageVirtualMachine
export def "create-storage-virtual-machine" [
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
  --active-directory-configuration: record # The configuration that Amazon FSx uses to join the ONTAP storage virtual machine (SVM) to your self-managed (including on-premises) Microsoft Active Directory (AD) directory. — shape: {NetBiosName: string, SelfManagedActiveDirectoryConfiguration?: record}
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  name: string # The name of the SVM.
  --svm-admin-password: string # The password to use when managing the SVM using the NetApp ONTAP CLI or REST API. If you do not specify a password, you can still use the file system's fsxadmin user to manage the SVM. (format: password)
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --root-volume-security-style: string@root-volume-security-style-completer # The security style of the root volume of the SVM. Specify one of the following values: UNIX if the file system is managed by a UNIX administrator, the majority of users are NFS clients, and an application accessing the data uses a UNIX user as the service account. NTFS if the file system is managed by a Windows administrator, the majority of users are SMB clients, and an application accessing the data uses a Windows user as the service account. MIXED if the file system is managed by both UNIX and Windows administrators and users consist of both NFS and SMB clients.
]: any -> oneof<record<StorageVirtualMachine: record<ActiveDirectoryConfiguration: record<NetBiosName: string, SelfManagedActiveDirectoryConfiguration: record>, CreationTime: string, Endpoints: record<Iscsi: record, Management: record, Nfs: record, Smb: record>, FileSystemId: string, Lifecycle: string, Name: string, ResourceARN: string, StorageVirtualMachineId: string, Subtype: string, UUID: string, Tags: list<record>, LifecycleTransitionReason: record<Message: string>, RootVolumeSecurityStyle: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.CreateStorageVirtualMachine")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ActiveDirectoryConfiguration": $active_directory_configuration, "ClientRequestToken": $client_request_token, "FileSystemId": $file_system_id, "Name": $name, "SvmAdminPassword": $svm_admin_password, "Tags": $tags, "RootVolumeSecurityStyle": $root_volume_security_style} | compact
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

# Creates an FSx for ONTAP or Amazon FSx for OpenZFS storage volume.
#
# POST /
# operationId: CreateVolume
export def "create-volume" [
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
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  volume_type: string@volume-type-completer # Specifies the type of volume to create; ONTAP and OPENZFS are the only valid volume types.
  name: string # Specifies the name of the volume that you're creating.
  --ontap-configuration: record # Specifies the configuration of the ONTAP volume that you are creating. — shape: {JunctionPath?: string, SecurityStyle?: "UNIX"|"NTFS"|"MIXED", SizeInMegabytes: int, StorageEfficiencyEnabled?: bool, StorageVirtualMachineId: string, TieringPolicy?: record, OntapVolumeType?: "RW"|"DP", SnapshotPolicy?: string, CopyTagsToBackups?: bool}
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
  --open-zfs-configuration: record # Specifies the configuration of the Amazon FSx for OpenZFS volume that you are creating. — shape: {ParentVolumeId: string, StorageCapacityReservationGiB?: int, StorageCapacityQuotaGiB?: int, RecordSizeKiB?: int, DataCompressionType?: "NONE"|"ZSTD"|"LZ4", CopyTagsToSnapshots?: bool, OriginSnapshot?: record, ReadOnly?: bool, NfsExports?: list, UserAndGroupQuotas?: list}
]: any -> oneof<record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record<FlexCacheEndpointType: string, JunctionPath: string, SecurityStyle: string, SizeInMegabytes: int, StorageEfficiencyEnabled: bool, StorageVirtualMachineId: string, StorageVirtualMachineRoot: bool, TieringPolicy: record, UUID: string, OntapVolumeType: string, SnapshotPolicy: string, CopyTagsToBackups: bool>, ResourceARN: string, Tags: list<record>, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: list<record>, OpenZFSConfiguration: record<ParentVolumeId: string, VolumePath: string, StorageCapacityReservationGiB: int, StorageCapacityQuotaGiB: int, RecordSizeKiB: int, DataCompressionType: string, CopyTagsToSnapshots: bool, OriginSnapshot: record, ReadOnly: bool, NfsExports: list, UserAndGroupQuotas: list, RestoreToSnapshot: string, DeleteIntermediateSnaphots: bool, DeleteClonedVolumes: bool>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.CreateVolume")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "VolumeType": $volume_type, "Name": $name, "OntapConfiguration": $ontap_configuration, "Tags": $tags, "OpenZFSConfiguration": $open_zfs_configuration} | compact
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

# Creates a new Amazon FSx for NetApp ONTAP volume from an existing Amazon FSx volume backup.
#
# POST /
# operationId: CreateVolumeFromBackup
export def "create-volume-from-backup" [
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
  backup_id: string # The ID of the source backup. Specifies the backup that you are copying.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  name: string # The name of the new volume you're creating.
  --ontap-configuration: record # Specifies the configuration of the ONTAP volume that you are creating. — shape: {JunctionPath?: string, SecurityStyle?: "UNIX"|"NTFS"|"MIXED", SizeInMegabytes: int, StorageEfficiencyEnabled?: bool, StorageVirtualMachineId: string, TieringPolicy?: record, OntapVolumeType?: "RW"|"DP", SnapshotPolicy?: string, CopyTagsToBackups?: bool}
  --tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
]: any -> oneof<record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record<FlexCacheEndpointType: string, JunctionPath: string, SecurityStyle: string, SizeInMegabytes: int, StorageEfficiencyEnabled: bool, StorageVirtualMachineId: string, StorageVirtualMachineRoot: bool, TieringPolicy: record, UUID: string, OntapVolumeType: string, SnapshotPolicy: string, CopyTagsToBackups: bool>, ResourceARN: string, Tags: list<record>, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: list<record>, OpenZFSConfiguration: record<ParentVolumeId: string, VolumePath: string, StorageCapacityReservationGiB: int, StorageCapacityQuotaGiB: int, RecordSizeKiB: int, DataCompressionType: string, CopyTagsToSnapshots: bool, OriginSnapshot: record, ReadOnly: bool, NfsExports: list, UserAndGroupQuotas: list, RestoreToSnapshot: string, DeleteIntermediateSnaphots: bool, DeleteClonedVolumes: bool>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.CreateVolumeFromBackup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BackupId": $backup_id, "ClientRequestToken": $client_request_token, "Name": $name, "OntapConfiguration": $ontap_configuration, "Tags": $tags} | compact
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

# Deletes an Amazon FSx backup. After deletion, the backup no longer exists, and its data is gone. The DeleteBackup call returns instantly. The backup won't show up in later DescribeBackups calls. The data in a deleted backup is also deleted and can't be recovered by any means.
#
# POST /
# operationId: DeleteBackup
export def "delete-backup" [
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
  backup_id: string # The ID of the source backup. Specifies the backup that you are copying.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
]: any -> oneof<record<BackupId: string, Lifecycle: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DeleteBackup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BackupId": $backup_id, "ClientRequestToken": $client_request_token} | compact
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

# Deletes a data repository association on an Amazon FSx for Lustre file system. Deleting the data repository association unlinks the file system from the Amazon S3 bucket. When deleting a data repository association, you have the option of deleting the data in the file system that corresponds to the data repository association. Data repository associations are supported for all file systems except for Scratch_1 deployment type.
#
# POST /
# operationId: DeleteDataRepositoryAssociation
export def "delete-data-repository-association" [
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
  association_id: string # The ID of the data repository association that you want to delete.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --delete-data-in-file-system: oneof<nothing, bool> # Set to true to delete the data in the file system that corresponds to the data repository association.
]: any -> oneof<record<AssociationId: string, Lifecycle: string, DeleteDataInFileSystem: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DeleteDataRepositoryAssociation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AssociationId": $association_id, "ClientRequestToken": $client_request_token, "DeleteDataInFileSystem": $delete_data_in_file_system} | compact
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

# Deletes an Amazon File Cache resource. After deletion, the cache no longer exists, and its data is gone. The DeleteFileCache operation returns while the cache has the DELETING status. You can check the cache deletion status by calling the DescribeFileCaches (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileCaches.html) operation, which returns a list of caches in your account. If you pass the cache ID for a deleted cache, the DescribeFileCaches operation returns a FileCacheNotFound error. The data in a deleted cache is also deleted and can't be recovered by any means.
#
# POST /
# operationId: DeleteFileCache
export def "delete-file-cache" [
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
  file_cache_id: string # The ID of the cache that's being deleted.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
]: any -> oneof<record<FileCacheId: string, Lifecycle: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DeleteFileCache")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FileCacheId": $file_cache_id, "ClientRequestToken": $client_request_token} | compact
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

# Deletes a file system. After deletion, the file system no longer exists, and its data is gone. Any existing automatic backups and snapshots are also deleted. To delete an Amazon FSx for NetApp ONTAP file system, first delete all the volumes and storage virtual machines (SVMs) on the file system. Then provide a FileSystemId value to the DeleFileSystem operation. By default, when you delete an Amazon FSx for Windows File Server file system, a final backup is created upon deletion. This final backup isn't subject to the file system's retention policy, and must be manually deleted. The DeleteFileSystem operation returns while the file system has the DELETING status. You can check the file system deletion status by calling the DescribeFileSystems (https://docs.aws.amazon.com/fsx/latest/APIReference/API_DescribeFileSystems.html) operation, which returns a list of file systems in your account. If you pass the file system ID for a deleted file system, the DescribeFileSystems operation returns a FileSystemNotFound error. If a data repository task is in a PENDING or EXECUTING state, deleting an Amazon FSx for Lustre file system will fail with an HTTP status code 400 (Bad Request). The data in a deleted file system is also deleted and can't be recovered by any means.
#
# POST /
# operationId: DeleteFileSystem
export def "delete-file-system" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --windows-configuration: record # The configuration object for the Microsoft Windows file system used in the DeleteFileSystem operation. — shape: {SkipFinalBackup?: bool, FinalBackupTags?: list}
  --lustre-configuration: record # The configuration object for the Amazon FSx for Lustre file system being deleted in the DeleteFileSystem operation. — shape: {SkipFinalBackup?: bool, FinalBackupTags?: list}
  --open-zfs-configuration: record # The configuration object for the Amazon FSx for OpenZFS file system used in the DeleteFileSystem operation. — shape: {SkipFinalBackup?: bool, FinalBackupTags?: list, Options?: list<string>}
]: any -> oneof<record<FileSystemId: string, Lifecycle: string, WindowsResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>, LustreResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>, OpenZFSResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DeleteFileSystem")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FileSystemId": $file_system_id, "ClientRequestToken": $client_request_token, "WindowsConfiguration": $windows_configuration, "LustreConfiguration": $lustre_configuration, "OpenZFSConfiguration": $open_zfs_configuration} | compact
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

# Deletes an Amazon FSx for OpenZFS snapshot. After deletion, the snapshot no longer exists, and its data is gone. Deleting a snapshot doesn't affect snapshots stored in a file system backup. The DeleteSnapshot operation returns instantly. The snapshot appears with the lifecycle status of DELETING until the deletion is complete.
#
# POST /
# operationId: DeleteSnapshot
export def "delete-snapshot" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  snapshot_id: string # The ID of the snapshot that you want to delete.
]: any -> oneof<record<SnapshotId: string, Lifecycle: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DeleteSnapshot")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "SnapshotId": $snapshot_id} | compact
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

# Deletes an existing Amazon FSx for ONTAP storage virtual machine (SVM). Prior to deleting an SVM, you must delete all non-root volumes in the SVM, otherwise the operation will fail.
#
# POST /
# operationId: DeleteStorageVirtualMachine
export def "delete-storage-virtual-machine" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  storage_virtual_machine_id: string # The ID of the SVM that you want to delete.
]: any -> oneof<record<StorageVirtualMachineId: string, Lifecycle: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DeleteStorageVirtualMachine")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "StorageVirtualMachineId": $storage_virtual_machine_id} | compact
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

# Deletes an Amazon FSx for NetApp ONTAP or Amazon FSx for OpenZFS volume.
#
# POST /
# operationId: DeleteVolume
export def "delete-volume" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  volume_id: string # The ID of the volume that you are deleting.
  --ontap-configuration: record # Use to specify skipping a final backup, or to add tags to a final backup. — shape: {SkipFinalBackup?: bool, FinalBackupTags?: list}
  --open-zfs-configuration: record # A value that specifies whether to delete all child volumes and snapshots. — shape: {Options?: list<string>}
]: any -> oneof<record<VolumeId: string, Lifecycle: string, OntapResponse: record<FinalBackupId: string, FinalBackupTags: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DeleteVolume")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "VolumeId": $volume_id, "OntapConfiguration": $ontap_configuration, "OpenZFSConfiguration": $open_zfs_configuration} | compact
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

# Returns the description of a specific Amazon FSx backup, if a BackupIds value is provided for that backup. Otherwise, it returns all backups owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all backups, you can optionally specify the MaxResults parameter to limit the number of backups in a response. If more backups remain, Amazon FSx returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of the NextToken value from the last response. This operation is used in an iterative process to retrieve a list of your backups. DescribeBackups is called first without a NextToken value. Then the operation continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken value. When using this operation, keep the following in mind: The operation might return fewer than the MaxResults value of backup descriptions while still including a NextToken value. The order of the backups returned in the response of one DescribeBackups call and the order of the backups returned across the responses of a multi-call iteration is unspecified.
#
# POST /
# operationId: DescribeBackups
export def "describe-backups" [
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
  --backup-ids: list<string> # A list of backup IDs.
  --filters: list # A list of Filter elements. — item shape: {Name?: "file-system-id"|"backup-type"|"file-system-type"|"volume-id"|"data-repository-type"|"file-cache-id"|"file-cache-type", Values?: list<string>}
  --max-results-body: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (body field)
  --next-token-body: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (body field)
]: any -> oneof<record<Backups: table<BackupId: string, Lifecycle: string, FailureDetails: record, Type: string, ProgressPercent: int, CreationTime: string, KmsKeyId: string, ResourceARN: string, Tags: list, FileSystem: record, DirectoryInformation: record, OwnerId: string, SourceBackupId: string, SourceBackupRegion: string, ResourceType: string, Volume: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DescribeBackups")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"BackupIds": $backup_ids, "Filters": $filters, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
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

# Returns the description of specific Amazon FSx for Lustre or Amazon File Cache data repository associations, if one or more AssociationIds values are provided in the request, or if filters are used in the request. Data repository associations are supported on Amazon File Cache resources and all Amazon FSx for Lustre file systems excluding Scratch_1 deployment types. You can use filters to narrow the response to include just data repository associations for specific file systems (use the file-system-id filter with the ID of the file system) or caches (use the file-cache-id filter with the ID of the cache), or data repository associations for a specific repository type (use the data-repository-type filter with a value of S3 or NFS). If you don't use filters, the response returns all data repository associations owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all data repository associations, you can paginate the response by using the optional MaxResults parameter to limit the number of data repository associations returned in a response. If more data repository associations remain, a NextToken value is returned in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response.
#
# POST /
# operationId: DescribeDataRepositoryAssociations
export def "describe-data-repository-associations" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  --association-ids: list<string> # IDs of the data repository associations whose descriptions you want to retrieve (String).
  --filters: list # A list of Filter elements. — item shape: {Name?: "file-system-id"|"backup-type"|"file-system-type"|"volume-id"|"data-repository-type"|"file-cache-id"|"file-cache-type", Values?: list<string>}
  --max-results-body: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (body field)
  --next-token-body: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (body field)
]: any -> oneof<record<Associations: table<AssociationId: string, ResourceARN: string, FileSystemId: string, Lifecycle: string, FailureDetails: record, FileSystemPath: string, DataRepositoryPath: string, BatchImportMetaDataOnCreate: bool, ImportedFileChunkSize: int, S3: record, Tags: list, CreationTime: string, FileCacheId: string, FileCachePath: string, DataRepositorySubdirectories: list, NFS: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DescribeDataRepositoryAssociations")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AssociationIds": $association_ids, "Filters": $filters, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
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

# Returns the description of specific Amazon FSx for Lustre or Amazon File Cache data repository tasks, if one or more TaskIds values are provided in the request, or if filters are used in the request. You can use filters to narrow the response to include just tasks for specific file systems or caches, or tasks in a specific lifecycle state. Otherwise, it returns all data repository tasks owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all tasks, you can paginate the response by using the optional MaxResults parameter to limit the number of tasks returned in a response. If more tasks remain, a NextToken value is returned in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response.
#
# POST /
# operationId: DescribeDataRepositoryTasks
export def "describe-data-repository-tasks" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  --task-ids: list<string> # (Optional) IDs of the tasks whose descriptions you want to retrieve (String).
  --filters: list # (Optional) You can use filters to narrow the DescribeDataRepositoryTasks response to include just tasks for specific file systems, or tasks in a specific lifecycle state. — item shape: {Name?: "file-system-id"|"task-lifecycle"|"data-repository-association-id"|"file-cache-id", Values?: list<string>}
  --max-results-body: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (body field)
  --next-token-body: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (body field)
]: any -> oneof<record<DataRepositoryTasks: table<TaskId: string, Lifecycle: string, Type: string, CreationTime: string, StartTime: string, EndTime: string, ResourceARN: string, Tags: list, FileSystemId: string, Paths: list, FailureDetails: record, Status: record, Report: record, CapacityToRelease: int, FileCacheId: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DescribeDataRepositoryTasks")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"TaskIds": $task_ids, "Filters": $filters, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
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

# Returns the description of a specific Amazon File Cache resource, if a FileCacheIds value is provided for that cache. Otherwise, it returns descriptions of all caches owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all cache descriptions, you can optionally specify the MaxResults parameter to limit the number of descriptions in a response. If more cache descriptions remain, the operation returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response. This operation is used in an iterative process to retrieve a list of your cache descriptions. DescribeFileCaches is called first without a NextTokenvalue. Then the operation continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken. When using this operation, keep the following in mind: The implementation might return fewer than MaxResults cache descriptions while still including a NextToken value. The order of caches returned in the response of one DescribeFileCaches call and the order of caches returned across the responses of a multicall iteration is unspecified.
#
# POST /
# operationId: DescribeFileCaches
export def "describe-file-caches" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  --file-cache-ids: list<string> # IDs of the caches whose descriptions you want to retrieve (String).
  --max-results-body: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (body field)
  --next-token-body: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (body field)
]: any -> oneof<record<FileCaches: table<OwnerId: string, CreationTime: string, FileCacheId: string, FileCacheType: string, FileCacheTypeVersion: string, Lifecycle: string, FailureDetails: record, StorageCapacity: int, VpcId: string, SubnetIds: list, NetworkInterfaceIds: list, DNSName: string, KmsKeyId: string, ResourceARN: string, LustreConfiguration: record, DataRepositoryAssociationIds: list>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DescribeFileCaches")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FileCacheIds": $file_cache_ids, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
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

# Returns the DNS aliases that are associated with the specified Amazon FSx for Windows File Server file system. A history of all DNS aliases that have been associated with and disassociated from the file system is available in the list of AdministrativeAction provided in the DescribeFileSystems operation response.
#
# POST /
# operationId: DescribeFileSystemAliases
export def "describe-file-system-aliases" [
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --max-results-body: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (body field)
  --next-token-body: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (body field)
]: any -> oneof<record<Aliases: table<Name: string, Lifecycle: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DescribeFileSystemAliases")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "FileSystemId": $file_system_id, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
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

# Returns the description of specific Amazon FSx file systems, if a FileSystemIds value is provided for that file system. Otherwise, it returns descriptions of all file systems owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all file system descriptions, you can optionally specify the MaxResults parameter to limit the number of descriptions in a response. If more file system descriptions remain, Amazon FSx returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response. This operation is used in an iterative process to retrieve a list of your file system descriptions. DescribeFileSystems is called first without a NextTokenvalue. Then the operation continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken. When using this operation, keep the following in mind: The implementation might return fewer than MaxResults file system descriptions while still including a NextToken value. The order of file systems returned in the response of one DescribeFileSystems call and the order of file systems returned across the responses of a multicall iteration is unspecified.
#
# POST /
# operationId: DescribeFileSystems
export def "describe-file-systems" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  --file-system-ids: list<string> # A list of file system IDs.
  --max-results-body: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (body field)
  --next-token-body: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (body field)
]: any -> oneof<record<FileSystems: table<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list, NetworkInterfaceIds: list, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list, WindowsConfiguration: record, LustreConfiguration: record, AdministrativeActions: list, OntapConfiguration: record, FileSystemTypeVersion: string, OpenZFSConfiguration: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DescribeFileSystems")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FileSystemIds": $file_system_ids, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
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

# Returns the description of specific Amazon FSx for OpenZFS snapshots, if a SnapshotIds value is provided. Otherwise, this operation returns all snapshots owned by your Amazon Web Services account in the Amazon Web Services Region of the endpoint that you're calling. When retrieving all snapshots, you can optionally specify the MaxResults parameter to limit the number of snapshots in a response. If more backups remain, Amazon FSx returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response. Use this operation in an iterative process to retrieve a list of your snapshots. DescribeSnapshots is called first without a NextToken value. Then the operation continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken value. When using this operation, keep the following in mind: The operation might return fewer than the MaxResults value of snapshot descriptions while still including a NextToken value. The order of snapshots returned in the response of one DescribeSnapshots call and the order of backups returned across the responses of a multi-call iteration is unspecified.
#
# POST /
# operationId: DescribeSnapshots
export def "describe-snapshots" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  --snapshot-ids: list<string> # The IDs of the snapshots that you want to retrieve. This parameter value overrides any filters. If any IDs aren't found, a SnapshotNotFound error occurs.
  --filters: list # The filters structure. The supported names are file-system-id or volume-id. — item shape: {Name?: "file-system-id"|"volume-id", Values?: list<string>}
  --max-results-body: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (body field)
  --next-token-body: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (body field)
]: any -> oneof<record<Snapshots: table<ResourceARN: string, SnapshotId: string, Name: string, VolumeId: string, CreationTime: string, Lifecycle: string, LifecycleTransitionReason: record, Tags: list, AdministrativeActions: list>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DescribeSnapshots")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"SnapshotIds": $snapshot_ids, "Filters": $filters, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
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

# Describes one or more Amazon FSx for NetApp ONTAP storage virtual machines (SVMs).
#
# POST /
# operationId: DescribeStorageVirtualMachines
export def "describe-storage-virtual-machines" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  --storage-virtual-machine-ids: list<string> # Enter the ID of one or more SVMs that you want to view.
  --filters: list # Enter a filter name:value pair to view a select set of SVMs. — item shape: {Name?: "file-system-id", Values?: list<string>}
  --max-results-body: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (body field)
  --next-token-body: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (body field)
]: any -> oneof<record<StorageVirtualMachines: table<ActiveDirectoryConfiguration: record, CreationTime: string, Endpoints: record, FileSystemId: string, Lifecycle: string, Name: string, ResourceARN: string, StorageVirtualMachineId: string, Subtype: string, UUID: string, Tags: list, LifecycleTransitionReason: record, RootVolumeSecurityStyle: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DescribeStorageVirtualMachines")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"StorageVirtualMachineIds": $storage_virtual_machine_ids, "Filters": $filters, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
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

# Describes one or more Amazon FSx for NetApp ONTAP or Amazon FSx for OpenZFS volumes.
#
# POST /
# operationId: DescribeVolumes
export def "describe-volumes" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  --volume-ids: list<string> # The IDs of the volumes whose descriptions you want to retrieve.
  --filters: list # Enter a filter Name and Values pair to view a select set of volumes. — item shape: {Name?: "file-system-id"|"storage-virtual-machine-id", Values?: list<string>}
  --max-results-body: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (body field)
  --next-token-body: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (body field)
]: any -> oneof<record<Volumes: table<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record, ResourceARN: string, Tags: list, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record, AdministrativeActions: list, OpenZFSConfiguration: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DescribeVolumes")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"VolumeIds": $volume_ids, "Filters": $filters, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
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

# Use this action to disassociate, or remove, one or more Domain Name Service (DNS) aliases from an Amazon FSx for Windows File Server file system. If you attempt to disassociate a DNS alias that is not associated with the file system, Amazon FSx responds with a 400 Bad Request. For more information, see Working with DNS Aliases (https://docs.aws.amazon.com/fsx/latest/WindowsGuide/managing-dns-aliases.html). The system generated response showing the DNS aliases that Amazon FSx is attempting to disassociate from the file system. Use the API operation to monitor the status of the aliases Amazon FSx is disassociating with the file system.
#
# POST /
# operationId: DisassociateFileSystemAliases
export def "disassociate-file-system-aliases" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  aliases: list<string> # An array of one or more DNS alias names to disassociate, or remove, from the file system.
]: any -> oneof<record<Aliases: table<Name: string, Lifecycle: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.DisassociateFileSystemAliases")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "FileSystemId": $file_system_id, "Aliases": $aliases} | compact
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

# Lists tags for Amazon FSx resources. When retrieving all tags, you can optionally specify the MaxResults parameter to limit the number of tags in a response. If more tags remain, Amazon FSx returns a NextToken value in the response. In this case, send a later request with the NextToken request parameter set to the value of NextToken from the last response. This action is used in an iterative process to retrieve a list of your tags. ListTagsForResource is called first without a NextTokenvalue. Then the action continues to be called with the NextToken parameter set to the value of the last NextToken value until a response has no NextToken. When using this action, keep the following in mind: The implementation might return fewer than MaxResults file system descriptions while still including a NextToken value. The order of tags returned in the response of one ListTagsForResource call and the order of tags returned across the responses of a multi-call iteration is unspecified.
#
# POST /
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  resource_arn: string # The Amazon Resource Name (ARN) for a given resource. ARNs uniquely identify Amazon Web Services resources. We require an ARN when you need to specify a resource unambiguously across all of Amazon Web Services. For more information, see Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) in the Amazon Web Services General Reference.
  --max-results-body: int # The maximum number of resources to return in the response. This value must be an integer greater than zero. (body field)
  --next-token-body: string # (Optional) Opaque pagination token returned from a previous operation (String). If present, this token indicates from what point you can continue processing the request, where the previous NextToken value left off. (body field)
]: any -> oneof<record<Tags: table<Key: string, Value: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.ListTagsForResource")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ResourceARN": $resource_arn, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
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

# Releases the file system lock from an Amazon FSx for OpenZFS file system.
#
# POST /
# operationId: ReleaseFileSystemNfsV3Locks
export def "release-file-system-nfs-v3-locks" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
]: any -> oneof<record<FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, WindowsConfiguration: record<ActiveDirectoryId: string, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: string, RemoteAdministrationEndpoint: string, PreferredSubnetId: string, PreferredFileServerIp: string, ThroughputCapacity: int, MaintenanceOperationsInProgress: list, WeeklyMaintenanceStartTime: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: string, DataRepositoryConfiguration: record, DeploymentType: string, PerUnitStorageThroughput: int, MountName: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, DriveCacheType: string, DataCompressionType: string, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: list<record>, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: string, EndpointIpAddressRange: string, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: list, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: string, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, CopyTagsToVolumes: bool, DailyAutomaticBackupStartTime: string, DeploymentType: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.ReleaseFileSystemNfsV3Locks")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FileSystemId": $file_system_id, "ClientRequestToken": $client_request_token} | compact
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

# Returns an Amazon FSx for OpenZFS volume to the state saved by the specified snapshot.
#
# POST /
# operationId: RestoreVolumeFromSnapshot
export def "restore-volume-from-snapshot" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  volume_id: string # The ID of the volume that you are restoring.
  snapshot_id: string # The ID of the source snapshot. Specifies the snapshot that you are restoring from.
  --options: list<string> # The settings used when restoring the specified volume from snapshot. DELETE_INTERMEDIATE_SNAPSHOTS - Deletes snapshots between the current state and the specified snapshot. If there are intermediate snapshots and this option isn't used, RestoreVolumeFromSnapshot fails. DELETE_CLONED_VOLUMES - Deletes any dependent clone volumes created from intermediate snapshots. If there are any dependent clone volumes and this option isn't used, RestoreVolumeFromSnapshot fails.
]: any -> oneof<record<VolumeId: string, Lifecycle: string, AdministrativeActions: table<AdministrativeActionType: string, ProgressPercent: int, RequestTime: string, Status: string, TargetFileSystemValues: record, FailureDetails: record, TargetVolumeValues: record, TargetSnapshotValues: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.RestoreVolumeFromSnapshot")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "VolumeId": $volume_id, "SnapshotId": $snapshot_id, "Options": $options} | compact
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

# Tags an Amazon FSx resource.
#
# POST /
# operationId: TagResource
export def "tag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  resource_arn: string # The Amazon Resource Name (ARN) for a given resource. ARNs uniquely identify Amazon Web Services resources. We require an ARN when you need to specify a resource unambiguously across all of Amazon Web Services. For more information, see Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) in the Amazon Web Services General Reference.
  tags: list # A list of Tag values, with a maximum of 50 elements. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARN": $resource_arn, "Tags": $tags} | compact
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

# This action removes a tag from an Amazon FSx resource.
#
# POST /
# operationId: UntagResource
export def "untag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  resource_arn: string # The Amazon Resource Name (ARN) for a given resource. ARNs uniquely identify Amazon Web Services resources. We require an ARN when you need to specify a resource unambiguously across all of Amazon Web Services. For more information, see Amazon Resource Names (ARNs) (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) in the Amazon Web Services General Reference.
  tag_keys: list<string> # A list of TagKey values, with a maximum of 50 elements.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARN": $resource_arn, "TagKeys": $tag_keys} | compact
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

# Updates the configuration of an existing data repository association on an Amazon FSx for Lustre file system. Data repository associations are supported for all file systems except for Scratch_1 deployment type.
#
# POST /
# operationId: UpdateDataRepositoryAssociation
export def "update-data-repository-association" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  association_id: string # The ID of the data repository association that you are updating.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --imported-file-chunk-size: int # For files imported from a data repository, this value determines the stripe count and maximum amount of data per file (in MiB) stored on a single physical disk. The maximum number of disks that a single file can be striped across is limited by the total number of disks that make up the file system. The default chunk size is 1,024 MiB (1 GiB) and can go as high as 512,000 MiB (500 GiB). Amazon S3 objects have a maximum size of 5 TB.
  --s3: record # The configuration for an Amazon S3 data repository linked to an Amazon FSx for Lustre file system with a data repository association. The configuration consists of an AutoImportPolicy that defines which file events on the data repository are automatically imported to the file system and an AutoExportPolicy that defines which file events on the file system are automatically exported to the data repository. File events are when files or directories are added, changed, or deleted on the file system or the data repository. Data repository associations on Amazon File Cache don't use S3DataRepositoryConfiguration because they don't support automatic import or automatic export. — shape: {AutoImportPolicy?: record, AutoExportPolicy?: record}
]: any -> oneof<record<Association: record<AssociationId: string, ResourceARN: string, FileSystemId: string, Lifecycle: string, FailureDetails: record<Message: string>, FileSystemPath: string, DataRepositoryPath: string, BatchImportMetaDataOnCreate: bool, ImportedFileChunkSize: int, S3: record<AutoImportPolicy: record, AutoExportPolicy: record>, Tags: list<record>, CreationTime: string, FileCacheId: string, FileCachePath: string, DataRepositorySubdirectories: list<string>, NFS: record<Version: string, DnsIps: list, AutoExportPolicy: record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.UpdateDataRepositoryAssociation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AssociationId": $association_id, "ClientRequestToken": $client_request_token, "ImportedFileChunkSize": $imported_file_chunk_size, "S3": $s3} | compact
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

# Updates the configuration of an existing Amazon File Cache resource. You can update multiple properties in a single request.
#
# POST /
# operationId: UpdateFileCache
export def "update-file-cache" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  file_cache_id: string # The ID of the cache that you are updating.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --lustre-configuration: record # The configuration update for an Amazon File Cache resource. — shape: {WeeklyMaintenanceStartTime?: string}
]: any -> oneof<record<FileCache: record<OwnerId: string, CreationTime: string, FileCacheId: string, FileCacheType: string, FileCacheTypeVersion: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, LustreConfiguration: record<PerUnitStorageThroughput: int, DeploymentType: string, MountName: string, WeeklyMaintenanceStartTime: string, MetadataConfiguration: record, LogConfiguration: record>, DataRepositoryAssociationIds: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.UpdateFileCache")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FileCacheId": $file_cache_id, "ClientRequestToken": $client_request_token, "LustreConfiguration": $lustre_configuration} | compact
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

# Use this operation to update the configuration of an existing Amazon FSx file system. You can update multiple properties in a single request. For FSx for Windows File Server file systems, you can update the following properties: AuditLogConfiguration AutomaticBackupRetentionDays DailyAutomaticBackupStartTime SelfManagedActiveDirectoryConfiguration StorageCapacity ThroughputCapacity WeeklyMaintenanceStartTime For FSx for Lustre file systems, you can update the following properties: AutoImportPolicy AutomaticBackupRetentionDays DailyAutomaticBackupStartTime DataCompressionType LustreRootSquashConfiguration StorageCapacity WeeklyMaintenanceStartTime For FSx for ONTAP file systems, you can update the following properties: AddRouteTableIds AutomaticBackupRetentionDays DailyAutomaticBackupStartTime DiskIopsConfiguration FsxAdminPassword RemoveRouteTableIds StorageCapacity ThroughputCapacity WeeklyMaintenanceStartTime For FSx for OpenZFS file systems, you can update the following properties: AutomaticBackupRetentionDays CopyTagsToBackups CopyTagsToVolumes DailyAutomaticBackupStartTime DiskIopsConfiguration StorageCapacity ThroughputCapacity WeeklyMaintenanceStartTime
#
# POST /
# operationId: UpdateFileSystem
export def "update-file-system" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  file_system_id: string # The globally unique ID of the file system, assigned by Amazon FSx.
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  --storage-capacity: int # The storage capacity for your Amazon FSx file system, in gibibytes.
  --windows-configuration: record # Updates the configuration for an existing Amazon FSx for Windows File Server file system. Amazon FSx only overwrites existing properties with non-null values provided in the request. — shape: {WeeklyMaintenanceStartTime?: string, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, ThroughputCapacity?: int, SelfManagedActiveDirectoryConfiguration?: record, AuditLogConfiguration?: record}
  --lustre-configuration: record # The configuration object for Amazon FSx for Lustre file systems used in the UpdateFileSystem operation. — shape: {WeeklyMaintenanceStartTime?: string, DailyAutomaticBackupStartTime?: string, AutomaticBackupRetentionDays?: int, AutoImportPolicy?: "NONE"|"NEW"|"NEW_CHANGED"|"NEW_CHANGED_DELETED", DataCompressionType?: "NONE"|"LZ4", LogConfiguration?: record, RootSquashConfiguration?: record}
  --ontap-configuration: record # The configuration updates for an Amazon FSx for NetApp ONTAP file system. — shape: {AutomaticBackupRetentionDays?: int, DailyAutomaticBackupStartTime?: string, FsxAdminPassword?: string, WeeklyMaintenanceStartTime?: string, DiskIopsConfiguration?: record, ThroughputCapacity?: int, AddRouteTableIds?: list<string>, RemoveRouteTableIds?: list<string>}
  --open-zfs-configuration: record # The configuration updates for an Amazon FSx for OpenZFS file system. — shape: {AutomaticBackupRetentionDays?: int, CopyTagsToBackups?: bool, CopyTagsToVolumes?: bool, DailyAutomaticBackupStartTime?: string, ThroughputCapacity?: int, WeeklyMaintenanceStartTime?: string, DiskIopsConfiguration?: record}
]: any -> oneof<record<FileSystem: record<OwnerId: string, CreationTime: string, FileSystemId: string, FileSystemType: string, Lifecycle: string, FailureDetails: record<Message: string>, StorageCapacity: int, StorageType: string, VpcId: string, SubnetIds: list<string>, NetworkInterfaceIds: list<string>, DNSName: string, KmsKeyId: string, ResourceARN: string, Tags: list<record>, WindowsConfiguration: record<ActiveDirectoryId: string, SelfManagedActiveDirectoryConfiguration: record, DeploymentType: string, RemoteAdministrationEndpoint: string, PreferredSubnetId: string, PreferredFileServerIp: string, ThroughputCapacity: int, MaintenanceOperationsInProgress: list, WeeklyMaintenanceStartTime: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, Aliases: list, AuditLogConfiguration: record>, LustreConfiguration: record<WeeklyMaintenanceStartTime: string, DataRepositoryConfiguration: record, DeploymentType: string, PerUnitStorageThroughput: int, MountName: string, DailyAutomaticBackupStartTime: string, AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, DriveCacheType: string, DataCompressionType: string, LogConfiguration: record, RootSquashConfiguration: record>, AdministrativeActions: list<record>, OntapConfiguration: record<AutomaticBackupRetentionDays: int, DailyAutomaticBackupStartTime: string, DeploymentType: string, EndpointIpAddressRange: string, Endpoints: record, DiskIopsConfiguration: record, PreferredSubnetId: string, RouteTableIds: list, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string>, FileSystemTypeVersion: string, OpenZFSConfiguration: record<AutomaticBackupRetentionDays: int, CopyTagsToBackups: bool, CopyTagsToVolumes: bool, DailyAutomaticBackupStartTime: string, DeploymentType: string, ThroughputCapacity: int, WeeklyMaintenanceStartTime: string, DiskIopsConfiguration: record, RootVolumeId: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.UpdateFileSystem")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FileSystemId": $file_system_id, "ClientRequestToken": $client_request_token, "StorageCapacity": $storage_capacity, "WindowsConfiguration": $windows_configuration, "LustreConfiguration": $lustre_configuration, "OntapConfiguration": $ontap_configuration, "OpenZFSConfiguration": $open_zfs_configuration} | compact
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

# Updates the name of an Amazon FSx for OpenZFS snapshot.
#
# POST /
# operationId: UpdateSnapshot
export def "update-snapshot" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  name: string # The name of the snapshot to update.
  snapshot_id: string # The ID of the snapshot that you want to update, in the format fsvolsnap-0123456789abcdef0.
]: any -> oneof<record<Snapshot: record<ResourceARN: string, SnapshotId: string, Name: string, VolumeId: string, CreationTime: string, Lifecycle: string, LifecycleTransitionReason: record<Message: string>, Tags: list<record>, AdministrativeActions: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.UpdateSnapshot")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "Name": $name, "SnapshotId": $snapshot_id} | compact
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

# Updates an Amazon FSx for ONTAP storage virtual machine (SVM).
#
# POST /
# operationId: UpdateStorageVirtualMachine
export def "update-storage-virtual-machine" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  --active-directory-configuration: record # Updates the Microsoft Active Directory (AD) configuration of an SVM joined to an AD. Please note, account credentials are not returned in the response payload. — shape: {SelfManagedActiveDirectoryConfiguration?: record}
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  storage_virtual_machine_id: string # The ID of the SVM that you want to update, in the format svm-0123456789abcdef0.
  --svm-admin-password: string # Enter a new SvmAdminPassword if you are updating it. (format: password)
]: any -> oneof<record<StorageVirtualMachine: record<ActiveDirectoryConfiguration: record<NetBiosName: string, SelfManagedActiveDirectoryConfiguration: record>, CreationTime: string, Endpoints: record<Iscsi: record, Management: record, Nfs: record, Smb: record>, FileSystemId: string, Lifecycle: string, Name: string, ResourceARN: string, StorageVirtualMachineId: string, Subtype: string, UUID: string, Tags: list<record>, LifecycleTransitionReason: record<Message: string>, RootVolumeSecurityStyle: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.UpdateStorageVirtualMachine")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ActiveDirectoryConfiguration": $active_directory_configuration, "ClientRequestToken": $client_request_token, "StorageVirtualMachineId": $storage_virtual_machine_id, "SvmAdminPassword": $svm_admin_password} | compact
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

# Updates the configuration of an Amazon FSx for NetApp ONTAP or Amazon FSx for OpenZFS volume.
#
# POST /
# operationId: UpdateVolume
export def "update-volume" [
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
  --x-amz-target: string@x-amz-target-completer-40 # required
  --client-request-token: string # (Optional) An idempotency token for resource creation, in a string of up to 63 ASCII characters. This token is automatically filled on your behalf when you use the Command Line Interface (CLI) or an Amazon Web Services SDK.
  volume_id: string # The ID of the volume that you want to update, in the format fsvol-0123456789abcdef0.
  --ontap-configuration: record # Used to specify changes to the ONTAP configuration for the volume you are updating. — shape: {JunctionPath?: string, SecurityStyle?: "UNIX"|"NTFS"|"MIXED", SizeInMegabytes?: int, StorageEfficiencyEnabled?: bool, TieringPolicy?: record, SnapshotPolicy?: string, CopyTagsToBackups?: bool}
  --name: string # The name of the OpenZFS volume. OpenZFS root volumes are automatically named FSX. Child volume names must be unique among their parent volume's children. The name of the volume is part of the mount string for the OpenZFS volume.
  --open-zfs-configuration: record # Used to specify changes to the OpenZFS configuration for the volume that you are updating. — shape: {StorageCapacityReservationGiB?: int, StorageCapacityQuotaGiB?: int, RecordSizeKiB?: int, DataCompressionType?: "NONE"|"ZSTD"|"LZ4", NfsExports?: list, UserAndGroupQuotas?: list, ReadOnly?: bool}
]: any -> oneof<record<Volume: record<CreationTime: string, FileSystemId: string, Lifecycle: string, Name: string, OntapConfiguration: record<FlexCacheEndpointType: string, JunctionPath: string, SecurityStyle: string, SizeInMegabytes: int, StorageEfficiencyEnabled: bool, StorageVirtualMachineId: string, StorageVirtualMachineRoot: bool, TieringPolicy: record, UUID: string, OntapVolumeType: string, SnapshotPolicy: string, CopyTagsToBackups: bool>, ResourceARN: string, Tags: list<record>, VolumeId: string, VolumeType: string, LifecycleTransitionReason: record<Message: string>, AdministrativeActions: list<record>, OpenZFSConfiguration: record<ParentVolumeId: string, VolumePath: string, StorageCapacityReservationGiB: int, StorageCapacityQuotaGiB: int, RecordSizeKiB: int, DataCompressionType: string, CopyTagsToSnapshots: bool, OriginSnapshot: record, ReadOnly: bool, NfsExports: list, UserAndGroupQuotas: list, RestoreToSnapshot: string, DeleteIntermediateSnaphots: bool, DeleteClonedVolumes: bool>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSSimbaAPIService_v20180301.UpdateVolume")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientRequestToken": $client_request_token, "VolumeId": $volume_id, "OntapConfiguration": $ontap_configuration, "Name": $name, "OpenZFSConfiguration": $open_zfs_configuration} | compact
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
