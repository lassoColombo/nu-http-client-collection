# Auto-generated client for Amazon Elastic Transcoder v2012-09-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/elastictranscoder/2012-09-25/openapi.json
# Auth: --token flag or $env.AMAZON_ELASTIC_TRANSCODER_TOKEN

const BASE_URL = "http://elastictranscoder.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_ELASTIC_TRANSCODER_TOKEN | default "" }
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

def base-url-completer [] { ["http://elastictranscoder.us-east-1.amazonaws.com" "http://elastictranscoder.us-east-2.amazonaws.com" "http://elastictranscoder.us-west-1.amazonaws.com" "http://elastictranscoder.us-west-2.amazonaws.com" "http://elastictranscoder.us-gov-west-1.amazonaws.com" "http://elastictranscoder.us-gov-east-1.amazonaws.com" "http://elastictranscoder.ca-central-1.amazonaws.com" "http://elastictranscoder.eu-north-1.amazonaws.com" "http://elastictranscoder.eu-west-1.amazonaws.com" "http://elastictranscoder.eu-west-2.amazonaws.com" "http://elastictranscoder.eu-west-3.amazonaws.com" "http://elastictranscoder.eu-central-1.amazonaws.com" "http://elastictranscoder.eu-south-1.amazonaws.com" "http://elastictranscoder.af-south-1.amazonaws.com" "http://elastictranscoder.ap-northeast-1.amazonaws.com" "http://elastictranscoder.ap-northeast-2.amazonaws.com" "http://elastictranscoder.ap-northeast-3.amazonaws.com" "http://elastictranscoder.ap-southeast-1.amazonaws.com" "http://elastictranscoder.ap-southeast-2.amazonaws.com" "http://elastictranscoder.ap-east-1.amazonaws.com" "http://elastictranscoder.ap-south-1.amazonaws.com" "http://elastictranscoder.sa-east-1.amazonaws.com" "http://elastictranscoder.me-south-1.amazonaws.com" "https://elastictranscoder.us-east-1.amazonaws.com" "https://elastictranscoder.us-east-2.amazonaws.com" "https://elastictranscoder.us-west-1.amazonaws.com" "https://elastictranscoder.us-west-2.amazonaws.com" "https://elastictranscoder.us-gov-west-1.amazonaws.com" "https://elastictranscoder.us-gov-east-1.amazonaws.com" "https://elastictranscoder.ca-central-1.amazonaws.com" "https://elastictranscoder.eu-north-1.amazonaws.com" "https://elastictranscoder.eu-west-1.amazonaws.com" "https://elastictranscoder.eu-west-2.amazonaws.com" "https://elastictranscoder.eu-west-3.amazonaws.com" "https://elastictranscoder.eu-central-1.amazonaws.com" "https://elastictranscoder.eu-south-1.amazonaws.com" "https://elastictranscoder.af-south-1.amazonaws.com" "https://elastictranscoder.ap-northeast-1.amazonaws.com" "https://elastictranscoder.ap-northeast-2.amazonaws.com" "https://elastictranscoder.ap-northeast-3.amazonaws.com" "https://elastictranscoder.ap-southeast-1.amazonaws.com" "https://elastictranscoder.ap-southeast-2.amazonaws.com" "https://elastictranscoder.ap-east-1.amazonaws.com" "https://elastictranscoder.ap-south-1.amazonaws.com" "https://elastictranscoder.sa-east-1.amazonaws.com" "https://elastictranscoder.me-south-1.amazonaws.com" "http://elastictranscoder.cn-north-1.amazonaws.com.cn" "http://elastictranscoder.cn-northwest-1.amazonaws.com.cn" "https://elastictranscoder.cn-north-1.amazonaws.com.cn" "https://elastictranscoder.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2012-09-25-jobs cancel" } } | get name | first)
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

# <p>The CancelJob operation cancels an unfinished job.</p> <note> <p>You can only cancel a job that has a status of <code>Submitted</code>. To prevent a pipeline from starting to process a job while you're getting the job identifier, use <a>UpdatePipelineStatus</a> to temporarily pause the pipeline.</p> </note>
#
# DELETE /2012-09-25/jobs/{Id}
# operationId: CancelJob
export def "2012-09-25-jobs cancel" [
  id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/2012-09-25/jobs/{id}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The ReadJob operation returns detailed information about a job.
#
# GET /2012-09-25/jobs/{Id}
# operationId: ReadJob
export def "2012-09-25-jobs get" [
  id: string
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
]: nothing -> record<Job: record<Id: record, Arn: record, PipelineId: record, Input: record<Key: record, FrameRate: record, Resolution: record, AspectRatio: record, Interlaced: record, Container: record, Encryption: record, TimeSpan: record, InputCaptions: record, DetectedProperties: record>, Inputs: record, Output: record<Id: record, Key: record, ThumbnailPattern: record, ThumbnailEncryption: record, Rotate: record, PresetId: record, SegmentDuration: record, Status: record, StatusDetail: record, Duration: record, Width: record, Height: record, FrameRate: record, FileSize: record, DurationMillis: record, Watermarks: record, AlbumArt: record, Composition: record, Captions: record, Encryption: record, AppliedColorSpaceConversion: record>, Outputs: record, OutputKeyPrefix: record, Playlists: record, Status: record, UserMetadata: record, Timing: record<SubmitTimeMillis: record, StartTimeMillis: record, FinishTimeMillis: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/2012-09-25/jobs/{id}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created.</p> <p>If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).</p>
#
# POST /2012-09-25/jobs
# operationId: CreateJob
# --Input shape: {Key?: any, FrameRate?: any, Resolution?: any, AspectRatio?: any, Interlaced?: any, Container?: any, Encryption?: any, TimeSpan?: any, InputCaptions?: any, DetectedProperties?: any}
# --Inputs item shape: {Key?: any, FrameRate?: any, Resolution?: any, AspectRatio?: any, Interlaced?: any, Container?: any, Encryption?: any, TimeSpan?: any, InputCaptions?: any, DetectedProperties?: any}
# --Output shape: {Key?: any, ThumbnailPattern?: any, ThumbnailEncryption?: any, Rotate?: any, PresetId?: any, SegmentDuration?: any, Watermarks?: any, AlbumArt?: any, Composition?: any, Captions?: any, Encryption?: any}
# --Outputs item shape: {Key?: any, ThumbnailPattern?: any, ThumbnailEncryption?: any, Rotate?: any, PresetId?: any, SegmentDuration?: any, Watermarks?: any, AlbumArt?: any, Composition?: any, Captions?: any, Encryption?: any}
# --Playlists item shape: {Name?: any, Format?: any, OutputKeys?: any, HlsContentProtection?: any, PlayReadyDrm?: any}
export def "2012-09-25-jobs create" [
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
  pipeline_id: string # The <code>Id</code> of the pipeline that you want Elastic Transcoder to use for transcoding. The pipeline determines several settings, including the Amazon S3 bucket from which Elastic Transcoder gets the files to transcode and the bucket into which Elastic Transcoder puts the transcoded files.
  --input: record # Information about the file that you're transcoding. — shape: {Key?: any, FrameRate?: any, Resolution?: any, AspectRatio?: any, Interlaced?: any, Container?: any, Encryption?: any, TimeSpan?: any, InputCaptions?: any, DetectedProperties?: any}
  --inputs: list # A section of the request body that provides information about the files that are being transcoded. — item shape: {Key?: any, FrameRate?: any, Resolution?: any, AspectRatio?: any, Interlaced?: any, Container?: any, Encryption?: any, TimeSpan?: any, InputCaptions?: any, DetectedProperties?: any}
  --output: record # The <code>CreateJobOutput</code> structure. — shape: {Key?: any, ThumbnailPattern?: any, ThumbnailEncryption?: any, Rotate?: any, PresetId?: any, SegmentDuration?: any, Watermarks?: any, AlbumArt?: any, Composition?: any, Captions?: any, Encryption?: any}
  --outputs: list #  A section of the request body that provides information about the transcoded (target) files. We recommend that you use the <code>Outputs</code> syntax instead of the <code>Output</code> syntax.  — item shape: {Key?: any, ThumbnailPattern?: any, ThumbnailEncryption?: any, Rotate?: any, PresetId?: any, SegmentDuration?: any, Watermarks?: any, AlbumArt?: any, Composition?: any, Captions?: any, Encryption?: any}
  --output-key-prefix: string # The value, if any, that you want Elastic Transcoder to prepend to the names of all files that this job creates, including output files, thumbnails, and playlists.
  --playlists: list # <p>If you specify a preset in <code>PresetId</code> for which the value of <code>Container</code> is fmp4 (Fragmented MP4) or ts (MPEG-TS), Playlists contains information about the master playlists that you want Elastic Transcoder to create.</p> <p>The maximum number of master playlists in a job is 30.</p> — item shape: {Name?: any, Format?: any, OutputKeys?: any, HlsContentProtection?: any, PlayReadyDrm?: any}
  --user-metadata: record # User-defined metadata that you want to associate with an Elastic Transcoder job. You specify metadata in <code>key/value</code> pairs, and you can add up to 10 <code>key/value</code> pairs per job. Elastic Transcoder does not guarantee that <code>key/value</code> pairs are returned in the same order in which you specify them.
]: any -> record<Job: record<Id: record, Arn: record, PipelineId: record, Input: record<Key: record, FrameRate: record, Resolution: record, AspectRatio: record, Interlaced: record, Container: record, Encryption: record, TimeSpan: record, InputCaptions: record, DetectedProperties: record>, Inputs: record, Output: record<Id: record, Key: record, ThumbnailPattern: record, ThumbnailEncryption: record, Rotate: record, PresetId: record, SegmentDuration: record, Status: record, StatusDetail: record, Duration: record, Width: record, Height: record, FrameRate: record, FileSize: record, DurationMillis: record, Watermarks: record, AlbumArt: record, Composition: record, Captions: record, Encryption: record, AppliedColorSpaceConversion: record>, Outputs: record, OutputKeyPrefix: record, Playlists: record, Status: record, UserMetadata: record, Timing: record<SubmitTimeMillis: record, StartTimeMillis: record, FinishTimeMillis: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2012-09-25/jobs")
  let body = {"PipelineId": $pipeline_id, "Input": $input, "Inputs": $inputs, "Output": $output, "Outputs": $outputs, "OutputKeyPrefix": $output_key_prefix, "Playlists": $playlists, "UserMetadata": $user_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# The CreatePipeline operation creates a pipeline with settings that you specify.
#
# POST /2012-09-25/pipelines
# operationId: CreatePipeline
# --Notifications shape: {Progressing?: any, Completed?: any, Warning?: any, Error?: any}
# --ContentConfig shape: {Bucket?: any, StorageClass?: any, Permissions?: any}
# --ThumbnailConfig shape: {Bucket?: any, StorageClass?: any, Permissions?: any}
export def "2012-09-25-pipelines create" [
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
  name: string # <p>The name of the pipeline. We recommend that the name be unique within the AWS account, but uniqueness is not enforced.</p> <p>Constraints: Maximum 40 characters.</p>
  input_bucket: string # The Amazon S3 bucket in which you saved the media files that you want to transcode.
  --output-bucket: string # <p>The Amazon S3 bucket in which you want Elastic Transcoder to save the transcoded files. (Use this, or use ContentConfig:Bucket plus ThumbnailConfig:Bucket.)</p> <p>Specify this value when all of the following are true:</p> <ul> <li> <p>You want to save transcoded files, thumbnails (if any), and playlists (if any) together in one bucket.</p> </li> <li> <p>You do not want to specify the users or groups who have access to the transcoded files, thumbnails, and playlists.</p> </li> <li> <p>You do not want to specify the permissions that Elastic Transcoder grants to the files. </p> <important> <p>When Elastic Transcoder saves files in <code>OutputBucket</code>, it grants full control over the files only to the AWS account that owns the role that is specified by <code>Role</code>.</p> </important> </li> <li> <p>You want to associate the transcoded files and thumbnails with the Amazon S3 Standard storage class.</p> </li> </ul> <p>If you want to save transcoded files and playlists in one bucket and thumbnails in another bucket, specify which users can access the transcoded files or the permissions the users have, or change the Amazon S3 storage class, omit <code>OutputBucket</code> and specify values for <code>ContentConfig</code> and <code>ThumbnailConfig</code> instead.</p>
  role: string # The IAM Amazon Resource Name (ARN) for the role that you want Elastic Transcoder to use to create the pipeline.
  --aws-kms-key-arn: string # <p>The AWS Key Management Service (AWS KMS) key that you want to use with this pipeline.</p> <p>If you use either <code>s3</code> or <code>s3-aws-kms</code> as your <code>Encryption:Mode</code>, you don't need to provide a key with your job because a default key, known as an AWS-KMS key, is created for you automatically. You need to provide an AWS-KMS key only if you want to use a non-default AWS-KMS key, or if you are using an <code>Encryption:Mode</code> of <code>aes-cbc-pkcs7</code>, <code>aes-ctr</code>, or <code>aes-gcm</code>.</p>
  --notifications: record # <p>The Amazon Simple Notification Service (Amazon SNS) topic or topics to notify in order to report job status.</p> <important> <p>To receive notifications, you must also subscribe to the new topic in the Amazon SNS console.</p> </important> — shape: {Progressing?: any, Completed?: any, Warning?: any, Error?: any}
  --content-config: record # The <code>PipelineOutputConfig</code> structure. — shape: {Bucket?: any, StorageClass?: any, Permissions?: any}
  --thumbnail-config: record # The <code>PipelineOutputConfig</code> structure. — shape: {Bucket?: any, StorageClass?: any, Permissions?: any}
]: any -> record<Pipeline: record<Id: record, Arn: record, Name: record, Status: record, InputBucket: record, OutputBucket: record, Role: record, AwsKmsKeyArn: record, Notifications: record<Progressing: record, Completed: record, Warning: record, Error: record>, ContentConfig: record<Bucket: record, StorageClass: record, Permissions: record>, ThumbnailConfig: record<Bucket: record, StorageClass: record, Permissions: record>>, Warnings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2012-09-25/pipelines")
  let body = {"Name": $name, "InputBucket": $input_bucket, "OutputBucket": $output_bucket, "Role": $role, "AwsKmsKeyArn": $aws_kms_key_arn, "Notifications": $notifications, "ContentConfig": $content_config, "ThumbnailConfig": $thumbnail_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# The ListPipelines operation gets a list of the pipelines associated with the current AWS account.
#
# GET /2012-09-25/pipelines
# operationId: ListPipelines
export def "2012-09-25-pipelines list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascending: string # To list pipelines in chronological order by the date and time that they were created, enter <code>true</code>. To list pipelines in reverse chronological order, enter <code>false</code>.
  --page-token: string # When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Pipelines: record, NextPageToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Ascending" $ascending "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2012-09-25/pipelines" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>The CreatePreset operation creates a preset with settings that you specify.</p> <important> <p>Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (<code>ValidationException</code>) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces.</p> </important> <p>Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication <i>Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services</i>.</p>
#
# POST /2012-09-25/presets
# operationId: CreatePreset
# --Video shape: {Codec?: any, CodecOptions?: any, KeyframesMaxDist?: any, FixedGOP?: any, BitRate?: any, FrameRate?: any, MaxFrameRate?: any, Resolution?: any, AspectRatio?: any, MaxWidth?: any, MaxHeight?: any, DisplayAspectRatio?: any, SizingPolicy?: any, PaddingPolicy?: any, Watermarks?: any}
# --Audio shape: {Codec?: any, SampleRate?: any, BitRate?: any, Channels?: any, AudioPackingMode?: any, CodecOptions?: any}
# --Thumbnails shape: {Format?: any, Interval?: any, Resolution?: any, AspectRatio?: any, MaxWidth?: any, MaxHeight?: any, SizingPolicy?: any, PaddingPolicy?: any}
export def "2012-09-25-presets create" [
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
  name: string # The name of the preset. We recommend that the name be unique within the AWS account, but uniqueness is not enforced.
  --description: string # A description of the preset.
  container: string # The container type for the output file. Valid values include <code>flac</code>, <code>flv</code>, <code>fmp4</code>, <code>gif</code>, <code>mp3</code>, <code>mp4</code>, <code>mpg</code>, <code>mxf</code>, <code>oga</code>, <code>ogg</code>, <code>ts</code>, and <code>webm</code>.
  --video: record # The <code>VideoParameters</code> structure. — shape: {Codec?: any, CodecOptions?: any, KeyframesMaxDist?: any, FixedGOP?: any, BitRate?: any, FrameRate?: any, MaxFrameRate?: any, Resolution?: any, AspectRatio?: any, MaxWidth?: any, MaxHeight?: any, DisplayAspectRatio?: any, SizingPolicy?: any, PaddingPolicy?: any, Watermarks?: any}
  --audio: record # Parameters required for transcoding audio. — shape: {Codec?: any, SampleRate?: any, BitRate?: any, Channels?: any, AudioPackingMode?: any, CodecOptions?: any}
  --thumbnails: record # Thumbnails for videos. — shape: {Format?: any, Interval?: any, Resolution?: any, AspectRatio?: any, MaxWidth?: any, MaxHeight?: any, SizingPolicy?: any, PaddingPolicy?: any}
]: any -> record<Preset: record<Id: record, Arn: record, Name: record, Description: record, Container: record, Audio: record<Codec: record, SampleRate: record, BitRate: record, Channels: record, AudioPackingMode: record, CodecOptions: record>, Video: record<Codec: record, CodecOptions: record, KeyframesMaxDist: record, FixedGOP: record, BitRate: record, FrameRate: record, MaxFrameRate: record, Resolution: record, AspectRatio: record, MaxWidth: record, MaxHeight: record, DisplayAspectRatio: record, SizingPolicy: record, PaddingPolicy: record, Watermarks: record>, Thumbnails: record<Format: record, Interval: record, Resolution: record, AspectRatio: record, MaxWidth: record, MaxHeight: record, SizingPolicy: record, PaddingPolicy: record>, Type: record>, Warning: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2012-09-25/presets")
  let body = {"Name": $name, "Description": $description, "Container": $container, "Video": $video, "Audio": $audio, "Thumbnails": $thumbnails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# The ListPresets operation gets a list of the default presets included with Elastic Transcoder and the presets that you've added in an AWS region.
#
# GET /2012-09-25/presets
# operationId: ListPresets
export def "2012-09-25-presets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascending: string # To list presets in chronological order by the date and time that they were created, enter <code>true</code>. To list presets in reverse chronological order, enter <code>false</code>.
  --page-token: string # When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Presets: record, NextPageToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Ascending" $ascending "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2012-09-25/presets" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>The DeletePipeline operation removes a pipeline.</p> <p> You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, <code>DeletePipeline</code> returns an error. </p>
#
# DELETE /2012-09-25/pipelines/{Id}
# operationId: DeletePipeline
export def "2012-09-25-pipelines delete" [
  id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/2012-09-25/pipelines/{id}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The ReadPipeline operation gets detailed information about a pipeline.
#
# GET /2012-09-25/pipelines/{Id}
# operationId: ReadPipeline
export def "2012-09-25-pipelines get" [
  id: string
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
]: nothing -> record<Pipeline: record<Id: record, Arn: record, Name: record, Status: record, InputBucket: record, OutputBucket: record, Role: record, AwsKmsKeyArn: record, Notifications: record<Progressing: record, Completed: record, Warning: record, Error: record>, ContentConfig: record<Bucket: record, StorageClass: record, Permissions: record>, ThumbnailConfig: record<Bucket: record, StorageClass: record, Permissions: record>>, Warnings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/2012-09-25/pipelines/{id}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p> Use the <code>UpdatePipeline</code> operation to update settings for a pipeline.</p> <important> <p>When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings. </p> </important>
#
# PUT /2012-09-25/pipelines/{Id}
# operationId: UpdatePipeline
# --Notifications shape: {Progressing?: any, Completed?: any, Warning?: any, Error?: any}
# --ContentConfig shape: {Bucket?: any, StorageClass?: any, Permissions?: any}
# --ThumbnailConfig shape: {Bucket?: any, StorageClass?: any, Permissions?: any}
export def "2012-09-25-pipelines update" [
  id: string
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
  --name: string # <p>The name of the pipeline. We recommend that the name be unique within the AWS account, but uniqueness is not enforced.</p> <p>Constraints: Maximum 40 characters</p>
  --input-bucket: string # The Amazon S3 bucket in which you saved the media files that you want to transcode and the graphics that you want to use as watermarks.
  --role: string # The IAM Amazon Resource Name (ARN) for the role that you want Elastic Transcoder to use to transcode jobs for this pipeline.
  --aws-kms-key-arn: string # <p>The AWS Key Management Service (AWS KMS) key that you want to use with this pipeline.</p> <p>If you use either <code>s3</code> or <code>s3-aws-kms</code> as your <code>Encryption:Mode</code>, you don't need to provide a key with your job because a default key, known as an AWS-KMS key, is created for you automatically. You need to provide an AWS-KMS key only if you want to use a non-default AWS-KMS key, or if you are using an <code>Encryption:Mode</code> of <code>aes-cbc-pkcs7</code>, <code>aes-ctr</code>, or <code>aes-gcm</code>.</p>
  --notifications: record # <p>The Amazon Simple Notification Service (Amazon SNS) topic or topics to notify in order to report job status.</p> <important> <p>To receive notifications, you must also subscribe to the new topic in the Amazon SNS console.</p> </important> — shape: {Progressing?: any, Completed?: any, Warning?: any, Error?: any}
  --content-config: record # The <code>PipelineOutputConfig</code> structure. — shape: {Bucket?: any, StorageClass?: any, Permissions?: any}
  --thumbnail-config: record # The <code>PipelineOutputConfig</code> structure. — shape: {Bucket?: any, StorageClass?: any, Permissions?: any}
]: any -> record<Pipeline: record<Id: record, Arn: record, Name: record, Status: record, InputBucket: record, OutputBucket: record, Role: record, AwsKmsKeyArn: record, Notifications: record<Progressing: record, Completed: record, Warning: record, Error: record>, ContentConfig: record<Bucket: record, StorageClass: record, Permissions: record>, ThumbnailConfig: record<Bucket: record, StorageClass: record, Permissions: record>>, Warnings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/2012-09-25/pipelines/{id}"))
  let body = {"Name": $name, "InputBucket": $input_bucket, "Role": $role, "AwsKmsKeyArn": $aws_kms_key_arn, "Notifications": $notifications, "ContentConfig": $content_config, "ThumbnailConfig": $thumbnail_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>The DeletePreset operation removes a preset that you've added in an AWS region.</p> <note> <p>You can't delete the default presets that are included with Elastic Transcoder.</p> </note>
#
# DELETE /2012-09-25/presets/{Id}
# operationId: DeletePreset
export def "2012-09-25-presets delete" [
  id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/2012-09-25/presets/{id}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The ReadPreset operation gets detailed information about a preset.
#
# GET /2012-09-25/presets/{Id}
# operationId: ReadPreset
export def "2012-09-25-presets get" [
  id: string
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
]: nothing -> record<Preset: record<Id: record, Arn: record, Name: record, Description: record, Container: record, Audio: record<Codec: record, SampleRate: record, BitRate: record, Channels: record, AudioPackingMode: record, CodecOptions: record>, Video: record<Codec: record, CodecOptions: record, KeyframesMaxDist: record, FixedGOP: record, BitRate: record, FrameRate: record, MaxFrameRate: record, Resolution: record, AspectRatio: record, MaxWidth: record, MaxHeight: record, DisplayAspectRatio: record, SizingPolicy: record, PaddingPolicy: record, Watermarks: record>, Thumbnails: record<Format: record, Interval: record, Resolution: record, AspectRatio: record, MaxWidth: record, MaxHeight: record, SizingPolicy: record, PaddingPolicy: record>, Type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/2012-09-25/presets/{id}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline.</p> <p>Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.</p>
#
# GET /2012-09-25/jobsByPipeline/{PipelineId}
# operationId: ListJobsByPipeline
export def "2012-09-25-jobs-by-pipeline list" [
  pipeline_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascending: string #  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  --page-token: string #  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Jobs: record, NextPageToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Ascending" $ascending "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pipeline_id: $pipeline_id} | format pattern "/2012-09-25/jobsByPipeline/{pipeline_id}") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The ListJobsByStatus operation gets a list of jobs that have a specified status. The response body contains one element for each job that satisfies the search criteria.
#
# GET /2012-09-25/jobsByStatus/{Status}
# operationId: ListJobsByStatus
export def "2012-09-25-jobs-by-status list" [
  status: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascending: string #  To list jobs in chronological order by the date and time that they were submitted, enter <code>true</code>. To list jobs in reverse chronological order, enter <code>false</code>. 
  --page-token: string #  When Elastic Transcoder returns more than one page of results, use <code>pageToken</code> in subsequent <code>GET</code> requests to get each successive page of results. 
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Jobs: record, NextPageToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Ascending" $ascending "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({status: $status} | format pattern "/2012-09-25/jobsByStatus/{status}") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>The TestRole operation tests the IAM role used to create the pipeline.</p> <p>The <code>TestRole</code> action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.</p>
#
# POST /2012-09-25/roleTests
# DEPRECATED
# operationId: TestRole
@deprecated
export def "2012-09-25-role-tests test" [
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
  role: string # The IAM Amazon Resource Name (ARN) for the role that you want Elastic Transcoder to test.
  input_bucket: string # The Amazon S3 bucket that contains media files to be transcoded. The action attempts to read from this bucket.
  output_bucket: string # The Amazon S3 bucket that Elastic Transcoder writes transcoded media files to. The action attempts to read from this bucket.
  topics: list # The ARNs of one or more Amazon Simple Notification Service (Amazon SNS) topics that you want the action to send a test notification to.
]: any -> record<Success: record, Messages: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2012-09-25/roleTests")
  let body = {"Role": $role, "InputBucket": $input_bucket, "OutputBucket": $output_bucket, "Topics": $topics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline.</p> <p>When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.</p>
#
# POST /2012-09-25/pipelines/{Id}/notifications
# operationId: UpdatePipelineNotifications
# --Notifications shape: {Progressing?: any, Completed?: any, Warning?: any, Error?: any}
export def "2012-09-25-pipelines-notifications update" [
  id: string
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
  notifications: record # <p>The Amazon Simple Notification Service (Amazon SNS) topic or topics to notify in order to report job status.</p> <important> <p>To receive notifications, you must also subscribe to the new topic in the Amazon SNS console.</p> </important> — shape: {Progressing?: any, Completed?: any, Warning?: any, Error?: any}
]: any -> record<Pipeline: record<Id: record, Arn: record, Name: record, Status: record, InputBucket: record, OutputBucket: record, Role: record, AwsKmsKeyArn: record, Notifications: record<Progressing: record, Completed: record, Warning: record, Error: record>, ContentConfig: record<Bucket: record, StorageClass: record, Permissions: record>, ThumbnailConfig: record<Bucket: record, StorageClass: record, Permissions: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/2012-09-25/pipelines/{id}/notifications"))
  let body = {"Notifications": $notifications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs.</p> <p>Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a <a>CancelJob</a> request. </p>
#
# POST /2012-09-25/pipelines/{Id}/status
# operationId: UpdatePipelineStatus
export def "2012-09-25-pipelines-status update" [
  id: string
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
  status: string # <p>The desired status of the pipeline:</p> <ul> <li> <p> <code>Active</code>: The pipeline is processing jobs.</p> </li> <li> <p> <code>Paused</code>: The pipeline is not currently processing jobs.</p> </li> </ul>
]: any -> record<Pipeline: record<Id: record, Arn: record, Name: record, Status: record, InputBucket: record, OutputBucket: record, Role: record, AwsKmsKeyArn: record, Notifications: record<Progressing: record, Completed: record, Warning: record, Error: record>, ContentConfig: record<Bucket: record, StorageClass: record, Permissions: record>, ThumbnailConfig: record<Bucket: record, StorageClass: record, Permissions: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/2012-09-25/pipelines/{id}/status"))
  let body = {"Status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
