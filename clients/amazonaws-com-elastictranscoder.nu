# Auto-generated client for Amazon Elastic Transcoder v2012-09-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/elastictranscoder/2012-09-25/openapi.json
# Auth: --token flag or $env.AMAZON_ELASTIC_TRANSCODER_TOKEN

const BASE_URL = "http://elastictranscoder.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_ELASTIC_TRANSCODER_TOKEN | default "" }
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

def base-url-completer [] { ["http://elastictranscoder.us-east-1.amazonaws.com" "http://elastictranscoder.us-east-2.amazonaws.com" "http://elastictranscoder.us-west-1.amazonaws.com" "http://elastictranscoder.us-west-2.amazonaws.com" "http://elastictranscoder.us-gov-west-1.amazonaws.com" "http://elastictranscoder.us-gov-east-1.amazonaws.com" "http://elastictranscoder.ca-central-1.amazonaws.com" "http://elastictranscoder.eu-north-1.amazonaws.com" "http://elastictranscoder.eu-west-1.amazonaws.com" "http://elastictranscoder.eu-west-2.amazonaws.com" "http://elastictranscoder.eu-west-3.amazonaws.com" "http://elastictranscoder.eu-central-1.amazonaws.com" "http://elastictranscoder.eu-south-1.amazonaws.com" "http://elastictranscoder.af-south-1.amazonaws.com" "http://elastictranscoder.ap-northeast-1.amazonaws.com" "http://elastictranscoder.ap-northeast-2.amazonaws.com" "http://elastictranscoder.ap-northeast-3.amazonaws.com" "http://elastictranscoder.ap-southeast-1.amazonaws.com" "http://elastictranscoder.ap-southeast-2.amazonaws.com" "http://elastictranscoder.ap-east-1.amazonaws.com" "http://elastictranscoder.ap-south-1.amazonaws.com" "http://elastictranscoder.sa-east-1.amazonaws.com" "http://elastictranscoder.me-south-1.amazonaws.com" "https://elastictranscoder.us-east-1.amazonaws.com" "https://elastictranscoder.us-east-2.amazonaws.com" "https://elastictranscoder.us-west-1.amazonaws.com" "https://elastictranscoder.us-west-2.amazonaws.com" "https://elastictranscoder.us-gov-west-1.amazonaws.com" "https://elastictranscoder.us-gov-east-1.amazonaws.com" "https://elastictranscoder.ca-central-1.amazonaws.com" "https://elastictranscoder.eu-north-1.amazonaws.com" "https://elastictranscoder.eu-west-1.amazonaws.com" "https://elastictranscoder.eu-west-2.amazonaws.com" "https://elastictranscoder.eu-west-3.amazonaws.com" "https://elastictranscoder.eu-central-1.amazonaws.com" "https://elastictranscoder.eu-south-1.amazonaws.com" "https://elastictranscoder.af-south-1.amazonaws.com" "https://elastictranscoder.ap-northeast-1.amazonaws.com" "https://elastictranscoder.ap-northeast-2.amazonaws.com" "https://elastictranscoder.ap-northeast-3.amazonaws.com" "https://elastictranscoder.ap-southeast-1.amazonaws.com" "https://elastictranscoder.ap-southeast-2.amazonaws.com" "https://elastictranscoder.ap-east-1.amazonaws.com" "https://elastictranscoder.ap-south-1.amazonaws.com" "https://elastictranscoder.sa-east-1.amazonaws.com" "https://elastictranscoder.me-south-1.amazonaws.com" "http://elastictranscoder.cn-north-1.amazonaws.com.cn" "http://elastictranscoder.cn-northwest-1.amazonaws.com.cn" "https://elastictranscoder.cn-north-1.amazonaws.com.cn" "https://elastictranscoder.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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

# The CancelJob operation cancels an unfinished job. You can only cancel a job that has a status of Submitted. To prevent a pipeline from starting to process a job while you're getting the job identifier, use UpdatePipelineStatus to temporarily pause the pipeline.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2012-09-25/jobs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2012-09-25/jobs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# When you create a job, Elastic Transcoder returns JSON data that includes the values that you specified plus information about the job that is created. If you have specified more than one output for your jobs (for example, one output for the Kindle Fire and another output for the Apple iPhone 4s), you currently must use the Elastic Transcoder API to list the jobs (as opposed to the AWS Console).
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  pipeline_id: string # The Id of the pipeline that you want Elastic Transcoder to use for transcoding. The pipeline determines several settings, including the Amazon S3 bucket from which Elastic Transcoder gets the files to transcode and the bucket into which Elastic Transcoder puts the transcoded files.
  --input: record # Information about the file that you're transcoding. — shape: {Key?: any, FrameRate?: any, Resolution?: any, AspectRatio?: any, Interlaced?: any, Container?: any, Encryption?: any, TimeSpan?: any, InputCaptions?: any, DetectedProperties?: any}
  --inputs: list # A section of the request body that provides information about the files that are being transcoded. — item shape: {Key?: any, FrameRate?: any, Resolution?: any, AspectRatio?: any, Interlaced?: any, Container?: any, Encryption?: any, TimeSpan?: any, InputCaptions?: any, DetectedProperties?: any}
  --output: record # The CreateJobOutput structure. — shape: {Key?: any, ThumbnailPattern?: any, ThumbnailEncryption?: any, Rotate?: any, PresetId?: any, SegmentDuration?: any, Watermarks?: any, AlbumArt?: any, Composition?: any, Captions?: any, Encryption?: any}
  --outputs: list # A section of the request body that provides information about the transcoded (target) files. We recommend that you use the Outputs syntax instead of the Output syntax. — item shape: {Key?: any, ThumbnailPattern?: any, ThumbnailEncryption?: any, Rotate?: any, PresetId?: any, SegmentDuration?: any, Watermarks?: any, AlbumArt?: any, Composition?: any, Captions?: any, Encryption?: any}
  --output-key-prefix: string # The value, if any, that you want Elastic Transcoder to prepend to the names of all files that this job creates, including output files, thumbnails, and playlists.
  --playlists: list # If you specify a preset in PresetId for which the value of Container is fmp4 (Fragmented MP4) or ts (MPEG-TS), Playlists contains information about the master playlists that you want Elastic Transcoder to create. The maximum number of master playlists in a job is 30. — item shape: {Name?: any, Format?: any, OutputKeys?: any, HlsContentProtection?: any, PlayReadyDrm?: any}
  --user-metadata: record # User-defined metadata that you want to associate with an Elastic Transcoder job. You specify metadata in key/value pairs, and you can add up to 10 key/value pairs per job. Elastic Transcoder does not guarantee that key/value pairs are returned in the same order in which you specify them.
]: any -> record<Job: record<Id: record, Arn: record, PipelineId: record, Input: record<Key: record, FrameRate: record, Resolution: record, AspectRatio: record, Interlaced: record, Container: record, Encryption: record, TimeSpan: record, InputCaptions: record, DetectedProperties: record>, Inputs: record, Output: record<Id: record, Key: record, ThumbnailPattern: record, ThumbnailEncryption: record, Rotate: record, PresetId: record, SegmentDuration: record, Status: record, StatusDetail: record, Duration: record, Width: record, Height: record, FrameRate: record, FileSize: record, DurationMillis: record, Watermarks: record, AlbumArt: record, Composition: record, Captions: record, Encryption: record, AppliedColorSpaceConversion: record>, Outputs: record, OutputKeyPrefix: record, Playlists: record, Status: record, UserMetadata: record, Timing: record<SubmitTimeMillis: record, StartTimeMillis: record, FinishTimeMillis: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2012-09-25/jobs")
  let req_body = {"PipelineId": $pipeline_id, "Input": $input, "Inputs": $inputs, "Output": $output, "Outputs": $outputs, "OutputKeyPrefix": $output_key_prefix, "Playlists": $playlists, "UserMetadata": $user_metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name of the pipeline. We recommend that the name be unique within the AWS account, but uniqueness is not enforced. Constraints: Maximum 40 characters.
  input_bucket: string # The Amazon S3 bucket in which you saved the media files that you want to transcode.
  --output-bucket: string # The Amazon S3 bucket in which you want Elastic Transcoder to save the transcoded files. (Use this, or use ContentConfig:Bucket plus ThumbnailConfig:Bucket.) Specify this value when all of the following are true: You want to save transcoded files, thumbnails (if any), and playlists (if any) together in one bucket. You do not want to specify the users or groups who have access to the transcoded files, thumbnails, and playlists. You do not want to specify the permissions that Elastic Transcoder grants to the files. When Elastic Transcoder saves files in OutputBucket, it grants full control over the files only to the AWS account that owns the role that is specified by Role. You want to associate the transcoded files and thumbnails with the Amazon S3 Standard storage class. If you want to save transcoded files and playlists in one bucket and thumbnails in another bucket, specify which users can access the transcoded files or the permissions the users have, or change the Amazon S3 storage class, omit OutputBucket and specify values for ContentConfig and ThumbnailConfig instead.
  role: string # The IAM Amazon Resource Name (ARN) for the role that you want Elastic Transcoder to use to create the pipeline.
  --aws-kms-key-arn: string # The AWS Key Management Service (AWS KMS) key that you want to use with this pipeline. If you use either s3 or s3-aws-kms as your Encryption:Mode, you don't need to provide a key with your job because a default key, known as an AWS-KMS key, is created for you automatically. You need to provide an AWS-KMS key only if you want to use a non-default AWS-KMS key, or if you are using an Encryption:Mode of aes-cbc-pkcs7, aes-ctr, or aes-gcm.
  --notifications: record # The Amazon Simple Notification Service (Amazon SNS) topic or topics to notify in order to report job status. To receive notifications, you must also subscribe to the new topic in the Amazon SNS console. — shape: {Progressing?: any, Completed?: any, Warning?: any, Error?: any}
  --content-config: record # The PipelineOutputConfig structure. — shape: {Bucket?: any, StorageClass?: any, Permissions?: any}
  --thumbnail-config: record # The PipelineOutputConfig structure. — shape: {Bucket?: any, StorageClass?: any, Permissions?: any}
]: any -> record<Pipeline: record<Id: record, Arn: record, Name: record, Status: record, InputBucket: record, OutputBucket: record, Role: record, AwsKmsKeyArn: record, Notifications: record<Progressing: record, Completed: record, Warning: record, Error: record>, ContentConfig: record<Bucket: record, StorageClass: record, Permissions: record>, ThumbnailConfig: record<Bucket: record, StorageClass: record, Permissions: record>>, Warnings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2012-09-25/pipelines")
  let req_body = {"Name": $name, "InputBucket": $input_bucket, "OutputBucket": $output_bucket, "Role": $role, "AwsKmsKeyArn": $aws_kms_key_arn, "Notifications": $notifications, "ContentConfig": $content_config, "ThumbnailConfig": $thumbnail_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascending: string # To list pipelines in chronological order by the date and time that they were created, enter true. To list pipelines in reverse chronological order, enter false.
  --page-token: string # When Elastic Transcoder returns more than one page of results, use pageToken in subsequent GET requests to get each successive page of results.
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
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Ascending": $ascending, "PageToken": $page_token} | compact), body: null}
}

# The CreatePreset operation creates a preset with settings that you specify. Elastic Transcoder checks the CreatePreset settings to ensure that they meet Elastic Transcoder requirements and to determine whether they comply with H.264 standards. If your settings are not valid for Elastic Transcoder, Elastic Transcoder returns an HTTP 400 response (ValidationException) and does not create the preset. If the settings are valid for Elastic Transcoder but aren't strictly compliant with the H.264 standard, Elastic Transcoder creates the preset and returns a warning message in the response. This helps you determine whether your settings comply with the H.264 standard while giving you greater flexibility with respect to the video that Elastic Transcoder produces. Elastic Transcoder uses the H.264 video-compression format. For more information, see the International Telecommunication Union publication Recommendation ITU-T H.264: Advanced video coding for generic audiovisual services.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  container: string # The container type for the output file. Valid values include flac, flv, fmp4, gif, mp3, mp4, mpg, mxf, oga, ogg, ts, and webm.
  --video: record # The VideoParameters structure. — shape: {Codec?: any, CodecOptions?: any, KeyframesMaxDist?: any, FixedGOP?: any, BitRate?: any, FrameRate?: any, MaxFrameRate?: any, Resolution?: any, AspectRatio?: any, MaxWidth?: any, MaxHeight?: any, DisplayAspectRatio?: any, SizingPolicy?: any, PaddingPolicy?: any, Watermarks?: any}
  --audio: record # Parameters required for transcoding audio. — shape: {Codec?: any, SampleRate?: any, BitRate?: any, Channels?: any, AudioPackingMode?: any, CodecOptions?: any}
  --thumbnails: record # Thumbnails for videos. — shape: {Format?: any, Interval?: any, Resolution?: any, AspectRatio?: any, MaxWidth?: any, MaxHeight?: any, SizingPolicy?: any, PaddingPolicy?: any}
]: any -> record<Preset: record<Id: record, Arn: record, Name: record, Description: record, Container: record, Audio: record<Codec: record, SampleRate: record, BitRate: record, Channels: record, AudioPackingMode: record, CodecOptions: record>, Video: record<Codec: record, CodecOptions: record, KeyframesMaxDist: record, FixedGOP: record, BitRate: record, FrameRate: record, MaxFrameRate: record, Resolution: record, AspectRatio: record, MaxWidth: record, MaxHeight: record, DisplayAspectRatio: record, SizingPolicy: record, PaddingPolicy: record, Watermarks: record>, Thumbnails: record<Format: record, Interval: record, Resolution: record, AspectRatio: record, MaxWidth: record, MaxHeight: record, SizingPolicy: record, PaddingPolicy: record>, Type: record>, Warning: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2012-09-25/presets")
  let req_body = {"Name": $name, "Description": $description, "Container": $container, "Video": $video, "Audio": $audio, "Thumbnails": $thumbnails} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascending: string # To list presets in chronological order by the date and time that they were created, enter true. To list presets in reverse chronological order, enter false.
  --page-token: string # When Elastic Transcoder returns more than one page of results, use pageToken in subsequent GET requests to get each successive page of results.
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
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Ascending": $ascending, "PageToken": $page_token} | compact), body: null}
}

# The DeletePipeline operation removes a pipeline. You can only delete a pipeline that has never been used or that is not currently in use (doesn't contain any active jobs). If the pipeline is currently in use, DeletePipeline returns an error.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2012-09-25/pipelines/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2012-09-25/pipelines/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Use the UpdatePipeline operation to update settings for a pipeline. When you change pipeline settings, your changes take effect immediately. Jobs that you have already submitted and that Elastic Transcoder has not started to process are affected in addition to jobs that you submit after you change settings.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --name: string # The name of the pipeline. We recommend that the name be unique within the AWS account, but uniqueness is not enforced. Constraints: Maximum 40 characters
  --input-bucket: string # The Amazon S3 bucket in which you saved the media files that you want to transcode and the graphics that you want to use as watermarks.
  --role: string # The IAM Amazon Resource Name (ARN) for the role that you want Elastic Transcoder to use to transcode jobs for this pipeline.
  --aws-kms-key-arn: string # The AWS Key Management Service (AWS KMS) key that you want to use with this pipeline. If you use either s3 or s3-aws-kms as your Encryption:Mode, you don't need to provide a key with your job because a default key, known as an AWS-KMS key, is created for you automatically. You need to provide an AWS-KMS key only if you want to use a non-default AWS-KMS key, or if you are using an Encryption:Mode of aes-cbc-pkcs7, aes-ctr, or aes-gcm.
  --notifications: record # The Amazon Simple Notification Service (Amazon SNS) topic or topics to notify in order to report job status. To receive notifications, you must also subscribe to the new topic in the Amazon SNS console. — shape: {Progressing?: any, Completed?: any, Warning?: any, Error?: any}
  --content-config: record # The PipelineOutputConfig structure. — shape: {Bucket?: any, StorageClass?: any, Permissions?: any}
  --thumbnail-config: record # The PipelineOutputConfig structure. — shape: {Bucket?: any, StorageClass?: any, Permissions?: any}
]: any -> record<Pipeline: record<Id: record, Arn: record, Name: record, Status: record, InputBucket: record, OutputBucket: record, Role: record, AwsKmsKeyArn: record, Notifications: record<Progressing: record, Completed: record, Warning: record, Error: record>, ContentConfig: record<Bucket: record, StorageClass: record, Permissions: record>, ThumbnailConfig: record<Bucket: record, StorageClass: record, Permissions: record>>, Warnings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2012-09-25/pipelines/{id}"))
  let req_body = {"Name": $name, "InputBucket": $input_bucket, "Role": $role, "AwsKmsKeyArn": $aws_kms_key_arn, "Notifications": $notifications, "ContentConfig": $content_config, "ThumbnailConfig": $thumbnail_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The DeletePreset operation removes a preset that you've added in an AWS region. You can't delete the default presets that are included with Elastic Transcoder.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2012-09-25/presets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2012-09-25/presets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# The ListJobsByPipeline operation gets a list of the jobs currently in a pipeline. Elastic Transcoder returns all of the jobs currently in the specified pipeline. The response body contains one element for each job that satisfies the search criteria.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascending: string # To list jobs in chronological order by the date and time that they were submitted, enter true. To list jobs in reverse chronological order, enter false.
  --page-token: string # When Elastic Transcoder returns more than one page of results, use pageToken in subsequent GET requests to get each successive page of results.
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
  if ($pipeline_id | is-empty) { error make --unspanned { msg: "path parameter 'PipelineId' must be non-empty" } }
  let qp = [(serialize-qp "Ascending" $ascending "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pipeline_id: (encode-path-segment $pipeline_id)} | format pattern "/2012-09-25/jobsByPipeline/{pipeline_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Ascending": $ascending, "PageToken": $page_token} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascending: string # To list jobs in chronological order by the date and time that they were submitted, enter true. To list jobs in reverse chronological order, enter false.
  --page-token: string # When Elastic Transcoder returns more than one page of results, use pageToken in subsequent GET requests to get each successive page of results.
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
  if ($status | is-empty) { error make --unspanned { msg: "path parameter 'Status' must be non-empty" } }
  let qp = [(serialize-qp "Ascending" $ascending "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({status: (encode-path-segment $status)} | format pattern "/2012-09-25/jobsByStatus/{status}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Ascending": $ascending, "PageToken": $page_token} | compact), body: null}
}

# The TestRole operation tests the IAM role used to create the pipeline. The TestRole action lets you determine whether the IAM role you are using has sufficient permissions to let Elastic Transcoder perform tasks associated with the transcoding process. The action attempts to assume the specified IAM role, checks read access to the input and output buckets, and tries to send a test notification to Amazon SNS topics that you specify.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  topics: list<string> # The ARNs of one or more Amazon Simple Notification Service (Amazon SNS) topics that you want the action to send a test notification to.
]: any -> record<Success: record, Messages: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2012-09-25/roleTests")
  let req_body = {"Role": $role, "InputBucket": $input_bucket, "OutputBucket": $output_bucket, "Topics": $topics} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# With the UpdatePipelineNotifications operation, you can update Amazon Simple Notification Service (Amazon SNS) notifications for a pipeline. When you update notifications for a pipeline, Elastic Transcoder returns the values that you specified in the request.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  notifications: record # The Amazon Simple Notification Service (Amazon SNS) topic or topics to notify in order to report job status. To receive notifications, you must also subscribe to the new topic in the Amazon SNS console. — shape: {Progressing?: any, Completed?: any, Warning?: any, Error?: any}
]: any -> record<Pipeline: record<Id: record, Arn: record, Name: record, Status: record, InputBucket: record, OutputBucket: record, Role: record, AwsKmsKeyArn: record, Notifications: record<Progressing: record, Completed: record, Warning: record, Error: record>, ContentConfig: record<Bucket: record, StorageClass: record, Permissions: record>, ThumbnailConfig: record<Bucket: record, StorageClass: record, Permissions: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2012-09-25/pipelines/{id}/notifications"))
  let req_body = {"Notifications": $notifications} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The UpdatePipelineStatus operation pauses or reactivates a pipeline, so that the pipeline stops or restarts the processing of jobs. Changing the pipeline status is useful if you want to cancel one or more jobs. You can't cancel jobs after Elastic Transcoder has started processing them; if you pause the pipeline to which you submitted the jobs, you have more time to get the job IDs for the jobs that you want to cancel, and to send a CancelJob request.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  status: string # The desired status of the pipeline: Active: The pipeline is processing jobs. Paused: The pipeline is not currently processing jobs.
]: any -> record<Pipeline: record<Id: record, Arn: record, Name: record, Status: record, InputBucket: record, OutputBucket: record, Role: record, AwsKmsKeyArn: record, Notifications: record<Progressing: record, Completed: record, Warning: record, Error: record>, ContentConfig: record<Bucket: record, StorageClass: record, Permissions: record>, ThumbnailConfig: record<Bucket: record, StorageClass: record, Permissions: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/2012-09-25/pipelines/{id}/status"))
  let req_body = {"Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
