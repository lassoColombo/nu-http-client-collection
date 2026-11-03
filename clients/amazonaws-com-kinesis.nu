# Auto-generated client for Amazon Kinesis v2013-12-02
# Source: https://api.apis.guru/v2/specs/amazonaws.com/kinesis/2013-12-02/openapi.json
# Auth: --token flag or $env.AMAZON_KINESIS_TOKEN

const BASE_URL = "http://kinesis.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_KINESIS_TOKEN | default "" }
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

def base-url-completer [] { ["http://kinesis.us-east-1.amazonaws.com" "http://kinesis.us-east-2.amazonaws.com" "http://kinesis.us-west-1.amazonaws.com" "http://kinesis.us-west-2.amazonaws.com" "http://kinesis.us-gov-west-1.amazonaws.com" "http://kinesis.us-gov-east-1.amazonaws.com" "http://kinesis.ca-central-1.amazonaws.com" "http://kinesis.eu-north-1.amazonaws.com" "http://kinesis.eu-west-1.amazonaws.com" "http://kinesis.eu-west-2.amazonaws.com" "http://kinesis.eu-west-3.amazonaws.com" "http://kinesis.eu-central-1.amazonaws.com" "http://kinesis.eu-south-1.amazonaws.com" "http://kinesis.af-south-1.amazonaws.com" "http://kinesis.ap-northeast-1.amazonaws.com" "http://kinesis.ap-northeast-2.amazonaws.com" "http://kinesis.ap-northeast-3.amazonaws.com" "http://kinesis.ap-southeast-1.amazonaws.com" "http://kinesis.ap-southeast-2.amazonaws.com" "http://kinesis.ap-east-1.amazonaws.com" "http://kinesis.ap-south-1.amazonaws.com" "http://kinesis.sa-east-1.amazonaws.com" "http://kinesis.me-south-1.amazonaws.com" "https://kinesis.us-east-1.amazonaws.com" "https://kinesis.us-east-2.amazonaws.com" "https://kinesis.us-west-1.amazonaws.com" "https://kinesis.us-west-2.amazonaws.com" "https://kinesis.us-gov-west-1.amazonaws.com" "https://kinesis.us-gov-east-1.amazonaws.com" "https://kinesis.ca-central-1.amazonaws.com" "https://kinesis.eu-north-1.amazonaws.com" "https://kinesis.eu-west-1.amazonaws.com" "https://kinesis.eu-west-2.amazonaws.com" "https://kinesis.eu-west-3.amazonaws.com" "https://kinesis.eu-central-1.amazonaws.com" "https://kinesis.eu-south-1.amazonaws.com" "https://kinesis.af-south-1.amazonaws.com" "https://kinesis.ap-northeast-1.amazonaws.com" "https://kinesis.ap-northeast-2.amazonaws.com" "https://kinesis.ap-northeast-3.amazonaws.com" "https://kinesis.ap-southeast-1.amazonaws.com" "https://kinesis.ap-southeast-2.amazonaws.com" "https://kinesis.ap-east-1.amazonaws.com" "https://kinesis.ap-south-1.amazonaws.com" "https://kinesis.sa-east-1.amazonaws.com" "https://kinesis.me-south-1.amazonaws.com" "http://kinesis.cn-north-1.amazonaws.com.cn" "http://kinesis.cn-northwest-1.amazonaws.com.cn" "https://kinesis.cn-north-1.amazonaws.com.cn" "https://kinesis.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["Kinesis_20131202.AddTagsToStream"] }
def x-amz-target-completer-1 [] { ["Kinesis_20131202.CreateStream"] }
def x-amz-target-completer-2 [] { ["Kinesis_20131202.DecreaseStreamRetentionPeriod"] }
def x-amz-target-completer-3 [] { ["Kinesis_20131202.DeleteStream"] }
def x-amz-target-completer-4 [] { ["Kinesis_20131202.DeregisterStreamConsumer"] }
def x-amz-target-completer-5 [] { ["Kinesis_20131202.DescribeLimits"] }
def x-amz-target-completer-6 [] { ["Kinesis_20131202.DescribeStream"] }
def x-amz-target-completer-7 [] { ["Kinesis_20131202.DescribeStreamConsumer"] }
def x-amz-target-completer-8 [] { ["Kinesis_20131202.DescribeStreamSummary"] }
def x-amz-target-completer-9 [] { ["Kinesis_20131202.DisableEnhancedMonitoring"] }
def x-amz-target-completer-10 [] { ["Kinesis_20131202.EnableEnhancedMonitoring"] }
def x-amz-target-completer-11 [] { ["Kinesis_20131202.GetRecords"] }
def shard-iterator-type-completer [] { ["AFTER_SEQUENCE_NUMBER" "AT_SEQUENCE_NUMBER" "AT_TIMESTAMP" "LATEST" "TRIM_HORIZON"] }
def x-amz-target-completer-12 [] { ["Kinesis_20131202.GetShardIterator"] }
def x-amz-target-completer-13 [] { ["Kinesis_20131202.IncreaseStreamRetentionPeriod"] }
def x-amz-target-completer-14 [] { ["Kinesis_20131202.ListShards"] }
def x-amz-target-completer-15 [] { ["Kinesis_20131202.ListStreamConsumers"] }
def x-amz-target-completer-16 [] { ["Kinesis_20131202.ListStreams"] }
def x-amz-target-completer-17 [] { ["Kinesis_20131202.ListTagsForStream"] }
def x-amz-target-completer-18 [] { ["Kinesis_20131202.MergeShards"] }
def x-amz-target-completer-19 [] { ["Kinesis_20131202.PutRecord"] }
def x-amz-target-completer-20 [] { ["Kinesis_20131202.PutRecords"] }
def x-amz-target-completer-21 [] { ["Kinesis_20131202.RegisterStreamConsumer"] }
def x-amz-target-completer-22 [] { ["Kinesis_20131202.RemoveTagsFromStream"] }
def x-amz-target-completer-23 [] { ["Kinesis_20131202.SplitShard"] }
def encryption-type-completer [] { ["KMS" "NONE"] }
def x-amz-target-completer-24 [] { ["Kinesis_20131202.StartStreamEncryption"] }
def x-amz-target-completer-25 [] { ["Kinesis_20131202.StopStreamEncryption"] }
def scaling-type-completer [] { ["UNIFORM_SCALING"] }
def x-amz-target-completer-26 [] { ["Kinesis_20131202.UpdateShardCount"] }
def x-amz-target-completer-27 [] { ["Kinesis_20131202.UpdateStreamMode"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "add-tags-to-stream" } } | get name | first)
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

# Adds or updates tags for the specified Kinesis data stream. You can assign up to 50 tags to a data stream. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. If tags have already been assigned to the stream, AddTagsToStream overwrites any existing tags that correspond to the specified tag keys. AddTagsToStream has a limit of five transactions per second per account.
#
# POST /
# operationId: AddTagsToStream
export def "add-tags-to-stream" [
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
  --stream-name: string # The name of the stream.
  tags: record # A set of up to 10 key-value pairs to use to create the tags.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.AddTagsToStream")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "Tags": $tags, "StreamARN": $stream_arn} | compact
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

# Creates a Kinesis data stream. A stream captures and transports data records that are continuously emitted from different data sources or producers. Scale-out within a stream is explicitly supported by means of shards, which are uniquely identified groups of data records in a stream. You can create your data stream using either on-demand or provisioned capacity mode. Data streams with an on-demand mode require no capacity planning and automatically scale to handle gigabytes of write and read throughput per minute. With the on-demand mode, Kinesis Data Streams automatically manages the shards in order to provide the necessary throughput. For the data streams with a provisioned mode, you must specify the number of shards for the data stream. Each shard can support reads up to five transactions per second, up to a maximum data read total of 2 MiB per second. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MiB per second. If the amount of data input increases or decreases, you can add or remove shards. The stream name identifies the stream. The name is scoped to the Amazon Web Services account used by the application. It is also scoped by Amazon Web Services Region. That is, two streams in two different accounts can have the same name, and two streams in the same account, but in two different Regions, can have the same name. CreateStream is an asynchronous operation. Upon receiving a CreateStream request, Kinesis Data Streams immediately returns and sets the stream status to CREATING. After the stream is created, Kinesis Data Streams sets the stream status to ACTIVE. You should perform read and write operations only on an ACTIVE stream. You receive a LimitExceededException when making a CreateStream request when you try to do one of the following: Have more than five streams in the CREATING state at any point in time. Create more shards than are authorized for your account. For the default shard limit for an Amazon Web Services account, see Amazon Kinesis Data Streams Limits (https://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html) in the Amazon Kinesis Data Streams Developer Guide. To increase this limit, contact Amazon Web Services Support (https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html). You can use DescribeStreamSummary to check the stream status, which is returned in StreamStatus. CreateStream has a limit of five transactions per second per account.
#
# POST /
# operationId: CreateStream
# --StreamModeDetails shape: {StreamMode: "PROVISIONED"|"ON_DEMAND"}
export def "create-stream" [
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
  stream_name: string # A name to identify the stream. The stream name is scoped to the Amazon Web Services account used by the application that creates the stream. It is also scoped by Amazon Web Services Region. That is, two streams in two different Amazon Web Services accounts can have the same name. Two streams in the same Amazon Web Services account but in two different Regions can also have the same name.
  --shard-count: int # The number of shards that the stream will use. The throughput of the stream is a function of the number of shards; more shards are required for greater provisioned throughput.
  --stream-mode-details: record # Specifies the capacity mode to which you want to set your data stream. Currently, in Kinesis Data Streams, you can choose between an on-demand capacity mode and a provisioned capacity mode for your data streams. — shape: {StreamMode: "PROVISIONED"|"ON_DEMAND"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.CreateStream")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "ShardCount": $shard_count, "StreamModeDetails": $stream_mode_details} | compact
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

# Decreases the Kinesis data stream's retention period, which is the length of time data records are accessible after they are added to the stream. The minimum value of a stream's retention period is 24 hours. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. This operation may result in lost data. For example, if the stream's retention period is 48 hours and is decreased to 24 hours, any data already in the stream that is older than 24 hours is inaccessible.
#
# POST /
# operationId: DecreaseStreamRetentionPeriod
export def "decrease-stream-retention-period" [
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
  --stream-name: string # The name of the stream to modify.
  retention_period_hours: int # The new retention period of the stream, in hours. Must be less than the current retention period.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.DecreaseStreamRetentionPeriod")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "RetentionPeriodHours": $retention_period_hours, "StreamARN": $stream_arn} | compact
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

# Deletes a Kinesis data stream and all its shards and data. You must shut down any applications that are operating on the stream before you delete the stream. If an application attempts to operate on a deleted stream, it receives the exception ResourceNotFoundException. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. If the stream is in the ACTIVE state, you can delete it. After a DeleteStream request, the specified stream is in the DELETING state until Kinesis Data Streams completes the deletion. Note: Kinesis Data Streams might continue to accept data read and write operations, such as PutRecord, PutRecords, and GetRecords, on a stream in the DELETING state until the stream deletion is complete. When you delete a stream, any shards in that stream are also deleted, and any tags are dissociated from the stream. You can use the DescribeStreamSummary operation to check the state of the stream, which is returned in StreamStatus. DeleteStream has a limit of five transactions per second per account.
#
# POST /
# operationId: DeleteStream
export def "delete-stream" [
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
  --stream-name: string # The name of the stream to delete.
  --enforce-consumer-deletion: oneof<nothing, bool> # If this parameter is unset (null) or if you set it to false, and the stream has registered consumers, the call to DeleteStream fails with a ResourceInUseException.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.DeleteStream")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "EnforceConsumerDeletion": $enforce_consumer_deletion, "StreamARN": $stream_arn} | compact
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

# To deregister a consumer, provide its ARN. Alternatively, you can provide the ARN of the data stream and the name you gave the consumer when you registered it. You may also provide all three parameters, as long as they don't conflict with each other. If you don't know the name or ARN of the consumer that you want to deregister, you can use the ListStreamConsumers operation to get a list of the descriptions of all the consumers that are currently registered with a given data stream. The description of a consumer contains its name and ARN. This operation has a limit of five transactions per second per stream.
#
# POST /
# operationId: DeregisterStreamConsumer
export def "deregister-stream-consumer" [
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
  --stream-arn: string # The ARN of the Kinesis data stream that the consumer is registered with. For more information, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-kinesis-streams).
  --consumer-name: string # The name that you gave to the consumer.
  --consumer-arn: string # The ARN returned by Kinesis Data Streams when you registered the consumer. If you don't know the ARN of the consumer that you want to deregister, you can use the ListStreamConsumers operation to get a list of the descriptions of all the consumers that are currently registered with a given data stream. The description of a consumer contains its ARN.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.DeregisterStreamConsumer")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamARN": $stream_arn, "ConsumerName": $consumer_name, "ConsumerARN": $consumer_arn} | compact
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

# Describes the shard limits and usage for the account. If you update your account limits, the old limits might be returned for a few minutes. This operation has a limit of one transaction per second per account.
#
# POST /
# operationId: DescribeLimits
export def "describe-limits" [
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
  --body: record
]: any -> record<ShardLimit: int, OpenShardCount: int, OnDemandStreamCount: int, OnDemandStreamCountLimit: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.DescribeLimits")
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

# Describes the specified Kinesis data stream. This API has been revised. It's highly recommended that you use the DescribeStreamSummary API to get a summarized description of the specified Kinesis data stream and the ListShards API to list the shards in a specified data stream and obtain information about each shard. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. The information returned includes the stream name, Amazon Resource Name (ARN), creation time, enhanced metric configuration, and shard map. The shard map is an array of shard objects. For each shard object, there is the hash key and sequence number ranges that the shard spans, and the IDs of any earlier shards that played in a role in creating the shard. Every record ingested in the stream is identified by a sequence number, which is assigned when the record is put into the stream. You can limit the number of shards returned by each call. For more information, see Retrieving Shards from a Stream (https://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-retrieve-shards.html) in the Amazon Kinesis Data Streams Developer Guide. There are no guarantees about the chronological order shards returned. To process shards in chronological order, use the ID of the parent shard to track the lineage to the oldest shard. This operation has a limit of 10 transactions per second per account.
#
# POST /
# operationId: DescribeStream
export def "describe-stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --exclusive-start-shard-id: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-6 # required
  --stream-name: string # The name of the stream to describe.
  --limit-body: int # The maximum number of shards to return in a single call. The default value is 100. If you specify a value greater than 100, at most 100 results are returned. (body field)
  --exclusive-start-shard-id-body: string # The shard ID of the shard to start with. Specify this parameter to indicate that you want to describe the stream starting with the shard whose ID immediately follows ExclusiveStartShardId. If you don't specify this parameter, the default behavior for DescribeStream is to describe the stream starting with the first shard in the stream. (body field)
  --stream-arn: string # The ARN of the stream.
]: any -> record<StreamDescription: record<StreamName: string, StreamARN: string, StreamStatus: string, StreamModeDetails: record<StreamMode: string>, Shards: list<record>, HasMoreShards: bool, RetentionPeriodHours: int, StreamCreationTimestamp: string, EnhancedMonitoring: list<record>, EncryptionType: string, KeyId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.DescribeStream")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "ExclusiveStartShardId" $exclusive_start_shard_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"StreamName": $stream_name, "Limit": $limit_body, "ExclusiveStartShardId": $exclusive_start_shard_id_body, "StreamARN": $stream_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "ExclusiveStartShardId": $exclusive_start_shard_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# To get the description of a registered consumer, provide the ARN of the consumer. Alternatively, you can provide the ARN of the data stream and the name you gave the consumer when you registered it. You may also provide all three parameters, as long as they don't conflict with each other. If you don't know the name or ARN of the consumer that you want to describe, you can use the ListStreamConsumers operation to get a list of the descriptions of all the consumers that are currently registered with a given data stream. This operation has a limit of 20 transactions per second per stream.
#
# POST /
# operationId: DescribeStreamConsumer
export def "describe-stream-consumer" [
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
  --stream-arn: string # The ARN of the Kinesis data stream that the consumer is registered with. For more information, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-kinesis-streams).
  --consumer-name: string # The name that you gave to the consumer.
  --consumer-arn: string # The ARN returned by Kinesis Data Streams when you registered the consumer.
]: any -> record<ConsumerDescription: record<ConsumerName: string, ConsumerARN: string, ConsumerStatus: string, ConsumerCreationTimestamp: string, StreamARN: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.DescribeStreamConsumer")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamARN": $stream_arn, "ConsumerName": $consumer_name, "ConsumerARN": $consumer_arn} | compact
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

# Provides a summarized description of the specified Kinesis data stream without the shard list. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. The information returned includes the stream name, Amazon Resource Name (ARN), status, record retention period, approximate creation time, monitoring, encryption details, and open shard count. DescribeStreamSummary has a limit of 20 transactions per second per account.
#
# POST /
# operationId: DescribeStreamSummary
export def "describe-stream-summary" [
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
  --stream-name: string # The name of the stream to describe.
  --stream-arn: string # The ARN of the stream.
]: any -> record<StreamDescriptionSummary: record<StreamName: string, StreamARN: string, StreamStatus: string, StreamModeDetails: record<StreamMode: string>, RetentionPeriodHours: int, StreamCreationTimestamp: string, EnhancedMonitoring: list<record>, EncryptionType: string, KeyId: string, OpenShardCount: int, ConsumerCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.DescribeStreamSummary")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "StreamARN": $stream_arn} | compact
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

# Disables enhanced monitoring. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter.
#
# POST /
# operationId: DisableEnhancedMonitoring
export def "disable-enhanced-monitoring" [
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
  --stream-name: string # The name of the Kinesis data stream for which to disable enhanced monitoring.
  shard_level_metrics: list<string> # List of shard-level metrics to disable. The following are the valid shard-level metrics. The value "ALL" disables every metric. IncomingBytes IncomingRecords OutgoingBytes OutgoingRecords WriteProvisionedThroughputExceeded ReadProvisionedThroughputExceeded IteratorAgeMilliseconds ALL For more information, see Monitoring the Amazon Kinesis Data Streams Service with Amazon CloudWatch (https://docs.aws.amazon.com/kinesis/latest/dev/monitoring-with-cloudwatch.html) in the Amazon Kinesis Data Streams Developer Guide.
  --stream-arn: string # The ARN of the stream.
]: any -> record<StreamName: string, CurrentShardLevelMetrics: list<string>, DesiredShardLevelMetrics: list<string>, StreamARN: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.DisableEnhancedMonitoring")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "ShardLevelMetrics": $shard_level_metrics, "StreamARN": $stream_arn} | compact
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

# Enables enhanced Kinesis data stream monitoring for shard-level metrics. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter.
#
# POST /
# operationId: EnableEnhancedMonitoring
export def "enable-enhanced-monitoring" [
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
  --stream-name: string # The name of the stream for which to enable enhanced monitoring.
  shard_level_metrics: list<string> # List of shard-level metrics to enable. The following are the valid shard-level metrics. The value "ALL" enables every metric. IncomingBytes IncomingRecords OutgoingBytes OutgoingRecords WriteProvisionedThroughputExceeded ReadProvisionedThroughputExceeded IteratorAgeMilliseconds ALL For more information, see Monitoring the Amazon Kinesis Data Streams Service with Amazon CloudWatch (https://docs.aws.amazon.com/kinesis/latest/dev/monitoring-with-cloudwatch.html) in the Amazon Kinesis Data Streams Developer Guide.
  --stream-arn: string # The ARN of the stream.
]: any -> record<StreamName: string, CurrentShardLevelMetrics: list<string>, DesiredShardLevelMetrics: list<string>, StreamARN: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.EnableEnhancedMonitoring")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "ShardLevelMetrics": $shard_level_metrics, "StreamARN": $stream_arn} | compact
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

# Gets data records from a Kinesis data stream's shard. When invoking this API, it is recommended you use the StreamARN input parameter in addition to the ShardIterator parameter. Specify a shard iterator using the ShardIterator parameter. The shard iterator specifies the position in the shard from which you want to start reading data records sequentially. If there are no records available in the portion of the shard that the iterator points to, GetRecords returns an empty list. It might take multiple calls to get to a portion of the shard that contains records. You can scale by provisioning multiple shards per stream while considering service limits (for more information, see Amazon Kinesis Data Streams Limits (https://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html) in the Amazon Kinesis Data Streams Developer Guide). Your application should have one thread per shard, each reading continuously from its stream. To read from a stream continually, call GetRecords in a loop. Use GetShardIterator to get the shard iterator to specify in the first GetRecords call. GetRecords returns a new shard iterator in NextShardIterator. Specify the shard iterator returned in NextShardIterator in subsequent calls to GetRecords. If the shard has been closed, the shard iterator can't return more data and GetRecords returns null in NextShardIterator. You can terminate the loop when the shard is closed, or when the shard iterator reaches the record with the sequence number or other attribute that marks it as the last record to process. Each data record can be up to 1 MiB in size, and each shard can read up to 2 MiB per second. You can ensure that your calls don't exceed the maximum supported size or throughput by using the Limit parameter to specify the maximum number of records that GetRecords can return. Consider your average record size when determining this limit. The maximum number of records that can be returned per call is 10,000. The size of the data returned by GetRecords varies depending on the utilization of the shard. It is recommended that consumer applications retrieve records via the GetRecords command using the 5 TPS limit to remain caught up. Retrieving records less frequently can lead to consumer applications falling behind. The maximum size of data that GetRecords can return is 10 MiB. If a call returns this amount of data, subsequent calls made within the next 5 seconds throw ProvisionedThroughputExceededException. If there is insufficient provisioned throughput on the stream, subsequent calls made within the next 1 second throw ProvisionedThroughputExceededException. GetRecords doesn't return any data when it throws an exception. For this reason, we recommend that you wait 1 second between calls to GetRecords. However, it's possible that the application will get exceptions for longer than 1 second. To detect whether the application is falling behind in processing, you can use the MillisBehindLatest response attribute. You can also monitor the stream using CloudWatch metrics and other mechanisms (see Monitoring (https://docs.aws.amazon.com/kinesis/latest/dev/monitoring.html) in the Amazon Kinesis Data Streams Developer Guide). Each Amazon Kinesis record includes a value, ApproximateArrivalTimestamp, that is set when a stream successfully receives and stores a record. This is commonly referred to as a server-side time stamp, whereas a client-side time stamp is set when a data producer creates or sends the record to a stream (a data producer is any data source putting data records into a stream, for example with PutRecords). The time stamp has millisecond precision. There are no guarantees about the time stamp accuracy, or that the time stamp is always increasing. For example, records in a shard or across a stream might have time stamps that are out of order. This operation has a limit of five transactions per second per shard.
#
# POST /
# operationId: GetRecords
export def "get-records" [
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
  shard_iterator: string # The position in the shard from which you want to start sequentially reading data records. A shard iterator specifies this position using the sequence number of a data record in the shard.
  --limit: int # The maximum number of records to return. Specify a value of up to 10,000. If you specify a value that is greater than 10,000, GetRecords throws InvalidArgumentException. The default value is 10,000.
  --stream-arn: string # The ARN of the stream.
]: any -> record<Records: table<SequenceNumber: string, ApproximateArrivalTimestamp: string, Data: string, PartitionKey: string, EncryptionType: string>, NextShardIterator: string, MillisBehindLatest: int, ChildShards: table<ShardId: string, ParentShards: list, HashKeyRange: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.GetRecords")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ShardIterator": $shard_iterator, "Limit": $limit, "StreamARN": $stream_arn} | compact
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

# Gets an Amazon Kinesis shard iterator. A shard iterator expires 5 minutes after it is returned to the requester. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. A shard iterator specifies the shard position from which to start reading data records sequentially. The position is specified using the sequence number of a data record in a shard. A sequence number is the identifier associated with every record ingested in the stream, and is assigned when a record is put into the stream. Each stream has one or more shards. You must specify the shard iterator type. For example, you can set the ShardIteratorType parameter to read exactly from the position denoted by a specific sequence number by using the AT_SEQUENCE_NUMBER shard iterator type. Alternatively, the parameter can read right after the sequence number by using the AFTER_SEQUENCE_NUMBER shard iterator type, using sequence numbers returned by earlier calls to PutRecord, PutRecords, GetRecords, or DescribeStream. In the request, you can specify the shard iterator type AT_TIMESTAMP to read records from an arbitrary point in time, TRIM_HORIZON to cause ShardIterator to point to the last untrimmed record in the shard in the system (the oldest data record in the shard), or LATEST so that you always read the most recent data in the shard. When you read repeatedly from a stream, use a GetShardIterator request to get the first shard iterator for use in your first GetRecords request and for subsequent reads use the shard iterator returned by the GetRecords request in NextShardIterator. A new shard iterator is returned by every GetRecords request in NextShardIterator, which you use in the ShardIterator parameter of the next GetRecords request. If a GetShardIterator request is made too often, you receive a ProvisionedThroughputExceededException. For more information about throughput limits, see GetRecords, and Streams Limits (https://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html) in the Amazon Kinesis Data Streams Developer Guide. If the shard is closed, GetShardIterator returns a valid iterator for the last sequence number of the shard. A shard can be closed as a result of using SplitShard or MergeShards. GetShardIterator has a limit of five transactions per second per account per open shard.
#
# POST /
# operationId: GetShardIterator
export def "get-shard-iterator" [
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
  --stream-name: string # The name of the Amazon Kinesis data stream.
  shard_id: string # The shard ID of the Kinesis Data Streams shard to get the iterator for.
  shard_iterator_type: string@shard-iterator-type-completer # Determines how the shard iterator is used to start reading data records from the shard. The following are the valid Amazon Kinesis shard iterator types: AT_SEQUENCE_NUMBER - Start reading from the position denoted by a specific sequence number, provided in the value StartingSequenceNumber. AFTER_SEQUENCE_NUMBER - Start reading right after the position denoted by a specific sequence number, provided in the value StartingSequenceNumber. AT_TIMESTAMP - Start reading from the position denoted by a specific time stamp, provided in the value Timestamp. TRIM_HORIZON - Start reading at the last untrimmed record in the shard in the system, which is the oldest data record in the shard. LATEST - Start reading just after the most recent record in the shard, so that you always read the most recent data in the shard.
  --starting-sequence-number: string # The sequence number of the data record in the shard from which to start reading. Used with shard iterator type AT_SEQUENCE_NUMBER and AFTER_SEQUENCE_NUMBER.
  --timestamp: string # The time stamp of the data record from which to start reading. Used with shard iterator type AT_TIMESTAMP. A time stamp is the Unix epoch date with precision in milliseconds. For example, 2016-04-04T19:58:46.480-00:00 or 1459799926.480. If a record with this exact time stamp does not exist, the iterator returned is for the next (later) record. If the time stamp is older than the current trim horizon, the iterator returned is for the oldest untrimmed data record (TRIM_HORIZON). (format: date-time)
  --stream-arn: string # The ARN of the stream.
]: any -> record<ShardIterator: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.GetShardIterator")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "ShardId": $shard_id, "ShardIteratorType": $shard_iterator_type, "StartingSequenceNumber": $starting_sequence_number, "Timestamp": $timestamp, "StreamARN": $stream_arn} | compact
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

# Increases the Kinesis data stream's retention period, which is the length of time data records are accessible after they are added to the stream. The maximum value of a stream's retention period is 8760 hours (365 days). When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. If you choose a longer stream retention period, this operation increases the time period during which records that have not yet expired are accessible. However, it does not make previous, expired data (older than the stream's previous retention period) accessible after the operation has been called. For example, if a stream's retention period is set to 24 hours and is increased to 168 hours, any data that is older than 24 hours remains inaccessible to consumer applications.
#
# POST /
# operationId: IncreaseStreamRetentionPeriod
export def "increase-stream-retention-period" [
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
  --stream-name: string # The name of the stream to modify.
  retention_period_hours: int # The new retention period of the stream, in hours. Must be more than the current retention period.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.IncreaseStreamRetentionPeriod")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "RetentionPeriodHours": $retention_period_hours, "StreamARN": $stream_arn} | compact
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

# Lists the shards in a stream and provides information about each shard. This operation has a limit of 1000 transactions per second per data stream. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. This action does not list expired shards. For information about expired shards, see Data Routing, Data Persistence, and Shard State after a Reshard (https://docs.aws.amazon.com/streams/latest/dev/kinesis-using-sdk-java-after-resharding.html#kinesis-using-sdk-java-resharding-data-routing). This API is a new operation that is used by the Amazon Kinesis Client Library (KCL). If you have a fine-grained IAM policy that only allows specific operations, you must update your policy to allow calls to this API. For more information, see Controlling Access to Amazon Kinesis Data Streams Resources Using IAM (https://docs.aws.amazon.com/streams/latest/dev/controlling-access.html).
#
# POST /
# operationId: ListShards
# --ShardFilter shape: {Type: "AFTER_SHARD_ID"|"AT_TRIM_HORIZON"|"FROM_TRIM_HORIZON"|"AT_LATEST"|"AT_TIMESTAMP"|"FROM_TIMESTAMP", ShardId?: string, Timestamp?: string}
export def "list-shards" [
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
  --stream-name: string # The name of the data stream whose shards you want to list. You cannot specify this parameter if you specify the NextToken parameter.
  --next-token: string # When the number of shards in the data stream is greater than the default value for the MaxResults parameter, or if you explicitly specify a value for MaxResults that is less than the number of shards in the data stream, the response includes a pagination token named NextToken. You can specify this NextToken value in a subsequent call to ListShards to list the next set of shards. Don't specify StreamName or StreamCreationTimestamp if you specify NextToken because the latter unambiguously identifies the stream. You can optionally specify a value for the MaxResults parameter when you specify NextToken. If you specify a MaxResults value that is less than the number of shards that the operation returns if you don't specify MaxResults, the response will contain a new NextToken value. You can use the new NextToken value in a subsequent call to the ListShards operation. Tokens expire after 300 seconds. When you obtain a value for NextToken in the response to a call to ListShards, you have 300 seconds to use that value. If you specify an expired token in a call to ListShards, you get ExpiredNextTokenException.
  --exclusive-start-shard-id: string # Specify this parameter to indicate that you want to list the shards starting with the shard whose ID immediately follows ExclusiveStartShardId. If you don't specify this parameter, the default behavior is for ListShards to list the shards starting with the first one in the stream. You cannot specify this parameter if you specify NextToken.
  --max-results: int # The maximum number of shards to return in a single call to ListShards. The maximum number of shards to return in a single call. The default value is 1000. If you specify a value greater than 1000, at most 1000 results are returned. When the number of shards to be listed is greater than the value of MaxResults, the response contains a NextToken value that you can use in a subsequent call to ListShards to list the next set of shards.
  --stream-creation-timestamp: string # Specify this input parameter to distinguish data streams that have the same name. For example, if you create a data stream and then delete it, and you later create another data stream with the same name, you can use this input parameter to specify which of the two streams you want to list the shards for. You cannot specify this parameter if you specify the NextToken parameter. (format: date-time)
  --shard-filter: record # The request parameter used to filter out the response of the ListShards API. — shape: {Type: "AFTER_SHARD_ID"|"AT_TRIM_HORIZON"|"FROM_TRIM_HORIZON"|"AT_LATEST"|"AT_TIMESTAMP"|"FROM_TIMESTAMP", ShardId?: string, Timestamp?: string}
  --stream-arn: string # The ARN of the stream.
]: any -> record<Shards: table<ShardId: string, ParentShardId: string, AdjacentParentShardId: string, HashKeyRange: record, SequenceNumberRange: record>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.ListShards")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "NextToken": $next_token, "ExclusiveStartShardId": $exclusive_start_shard_id, "MaxResults": $max_results, "StreamCreationTimestamp": $stream_creation_timestamp, "ShardFilter": $shard_filter, "StreamARN": $stream_arn} | compact
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

# Lists the consumers registered to receive data from a stream using enhanced fan-out, and provides information about each consumer. This operation has a limit of 5 transactions per second per stream.
#
# POST /
# operationId: ListStreamConsumers
export def "list-stream-consumers" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  stream_arn: string # The ARN of the Kinesis data stream for which you want to list the registered consumers. For more information, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-kinesis-streams).
  --next-token-body: string # When the number of consumers that are registered with the data stream is greater than the default value for the MaxResults parameter, or if you explicitly specify a value for MaxResults that is less than the number of consumers that are registered with the data stream, the response includes a pagination token named NextToken. You can specify this NextToken value in a subsequent call to ListStreamConsumers to list the next set of registered consumers. Don't specify StreamName or StreamCreationTimestamp if you specify NextToken because the latter unambiguously identifies the stream. You can optionally specify a value for the MaxResults parameter when you specify NextToken. If you specify a MaxResults value that is less than the number of consumers that the operation returns if you don't specify MaxResults, the response will contain a new NextToken value. You can use the new NextToken value in a subsequent call to the ListStreamConsumers operation to list the next set of consumers. Tokens expire after 300 seconds. When you obtain a value for NextToken in the response to a call to ListStreamConsumers, you have 300 seconds to use that value. If you specify an expired token in a call to ListStreamConsumers, you get ExpiredNextTokenException. (body field)
  --max-results-body: int # The maximum number of consumers that you want a single call of ListStreamConsumers to return. The default value is 100. If you specify a value greater than 100, at most 100 results are returned. (body field)
  --stream-creation-timestamp: string # Specify this input parameter to distinguish data streams that have the same name. For example, if you create a data stream and then delete it, and you later create another data stream with the same name, you can use this input parameter to specify which of the two streams you want to list the consumers for. You can't specify this parameter if you specify the NextToken parameter. (format: date-time)
]: any -> record<Consumers: table<ConsumerName: string, ConsumerARN: string, ConsumerStatus: string, ConsumerCreationTimestamp: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.ListStreamConsumers")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"StreamARN": $stream_arn, "NextToken": $next_token_body, "MaxResults": $max_results_body, "StreamCreationTimestamp": $stream_creation_timestamp} | compact
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

# Lists your Kinesis data streams. The number of streams may be too large to return from a single call to ListStreams. You can limit the number of returned streams using the Limit parameter. If you do not specify a value for the Limit parameter, Kinesis Data Streams uses the default limit, which is currently 100. You can detect if there are more streams available to list by using the HasMoreStreams flag from the returned output. If there are more streams available, you can request more streams by using the name of the last stream returned by the ListStreams request in the ExclusiveStartStreamName parameter in a subsequent request to ListStreams. The group of stream names returned by the subsequent request is then added to the list. You can continue this process until all the stream names have been collected in the list. ListStreams has a limit of five transactions per second per account.
#
# POST /
# operationId: ListStreams
export def "list-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16 # required
  --limit-body: int # The maximum number of streams to list. The default value is 100. If you specify a value greater than 100, at most 100 results are returned. (body field)
  --exclusive-start-stream-name: string # The name of the stream to start the list with.
  --next-token-body: string # (body field)
]: any -> record<StreamNames: list<string>, HasMoreStreams: bool, NextToken: string, StreamSummaries: table<StreamName: string, StreamARN: string, StreamStatus: string, StreamModeDetails: record, StreamCreationTimestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.ListStreams")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Limit": $limit_body, "ExclusiveStartStreamName": $exclusive_start_stream_name, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the tags for the specified Kinesis data stream. This operation has a limit of five transactions per second per account. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter.
#
# POST /
# operationId: ListTagsForStream
export def "list-tags-for-stream" [
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
  --stream-name: string # The name of the stream.
  --exclusive-start-tag-key: string # The key to use as the starting point for the list of tags. If this parameter is set, ListTagsForStream gets all tags that occur after ExclusiveStartTagKey.
  --limit: int # The number of tags to return. If this number is less than the total number of tags associated with the stream, HasMoreTags is set to true. To list additional tags, set ExclusiveStartTagKey to the last key in the response.
  --stream-arn: string # The ARN of the stream.
]: any -> record<Tags: table<Key: string, Value: string>, HasMoreTags: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.ListTagsForStream")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "ExclusiveStartTagKey": $exclusive_start_tag_key, "Limit": $limit, "StreamARN": $stream_arn} | compact
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

# Merges two adjacent shards in a Kinesis data stream and combines them into a single shard to reduce the stream's capacity to ingest and transport data. This API is only supported for the data streams with the provisioned capacity mode. Two shards are considered adjacent if the union of the hash key ranges for the two shards form a contiguous set with no gaps. For example, if you have two shards, one with a hash key range of 276...381 and the other with a hash key range of 382...454, then you could merge these two shards into a single shard that would have a hash key range of 276...454. After the merge, the single child shard receives data for all hash key values covered by the two parent shards. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. MergeShards is called when there is a need to reduce the overall capacity of a stream because of excess capacity that is not being used. You must specify the shard to be merged and the adjacent shard for a stream. For more information about merging shards, see Merge Two Shards (https://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-resharding-merge.html) in the Amazon Kinesis Data Streams Developer Guide. If the stream is in the ACTIVE state, you can call MergeShards. If a stream is in the CREATING, UPDATING, or DELETING state, MergeShards returns a ResourceInUseException. If the specified stream does not exist, MergeShards returns a ResourceNotFoundException. You can use DescribeStreamSummary to check the state of the stream, which is returned in StreamStatus. MergeShards is an asynchronous operation. Upon receiving a MergeShards request, Amazon Kinesis Data Streams immediately returns a response and sets the StreamStatus to UPDATING. After the operation is completed, Kinesis Data Streams sets the StreamStatus to ACTIVE. Read and write operations continue to work while the stream is in the UPDATING state. You use DescribeStreamSummary and the ListShards APIs to determine the shard IDs that are specified in the MergeShards request. If you try to operate on too many streams in parallel using CreateStream, DeleteStream, MergeShards, or SplitShard, you receive a LimitExceededException. MergeShards has a limit of five transactions per second per account.
#
# POST /
# operationId: MergeShards
export def "merge-shards" [
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
  --stream-name: string # The name of the stream for the merge.
  shard_to_merge: string # The shard ID of the shard to combine with the adjacent shard for the merge.
  adjacent_shard_to_merge: string # The shard ID of the adjacent shard for the merge.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.MergeShards")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "ShardToMerge": $shard_to_merge, "AdjacentShardToMerge": $adjacent_shard_to_merge, "StreamARN": $stream_arn} | compact
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

# Writes a single data record into an Amazon Kinesis data stream. Call PutRecord to send data into the stream for real-time ingestion and subsequent processing, one record at a time. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MiB per second. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. You must specify the name of the stream that captures, stores, and transports the data; a partition key; and the data blob itself. The data blob can be any type of data; for example, a segment from a log file, geographic/location data, website clickstream data, and so on. The partition key is used by Kinesis Data Streams to distribute data across shards. Kinesis Data Streams segregates the data records that belong to a stream into multiple shards, using the partition key associated with each data record to determine the shard to which a given data record belongs. Partition keys are Unicode strings, with a maximum length limit of 256 characters for each key. An MD5 hash function is used to map partition keys to 128-bit integer values and to map associated data records to shards using the hash key ranges of the shards. You can override hashing the partition key to determine the shard by explicitly specifying a hash value using the ExplicitHashKey parameter. For more information, see Adding Data to a Stream (https://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream) in the Amazon Kinesis Data Streams Developer Guide. PutRecord returns the shard ID of where the data record was placed and the sequence number that was assigned to the data record. Sequence numbers increase over time and are specific to a shard within a stream, not across all shards within a stream. To guarantee strictly increasing ordering, write serially to a shard and use the SequenceNumberForOrdering parameter. For more information, see Adding Data to a Stream (https://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream) in the Amazon Kinesis Data Streams Developer Guide. After you write a record to a stream, you cannot modify that record or its order within the stream. If a PutRecord request cannot be processed because of insufficient provisioned throughput on the shard involved in the request, PutRecord throws ProvisionedThroughputExceededException. By default, data records are accessible for 24 hours from the time that they are added to a stream. You can use IncreaseStreamRetentionPeriod or DecreaseStreamRetentionPeriod to modify this retention period.
#
# POST /
# operationId: PutRecord
export def "put-record" [
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
  --stream-name: string # The name of the stream to put the data record into.
  data: string # The data blob to put into the record, which is base64-encoded when the blob is serialized. When the data blob (the payload before base64-encoding) is added to the partition key size, the total size must not exceed the maximum record size (1 MiB).
  partition_key: string # Determines which shard in the stream the data record is assigned to. Partition keys are Unicode strings with a maximum length limit of 256 characters for each key. Amazon Kinesis Data Streams uses the partition key as input to a hash function that maps the partition key and associated data to a specific shard. Specifically, an MD5 hash function is used to map partition keys to 128-bit integer values and to map associated data records to shards. As a result of this hashing mechanism, all data records with the same partition key map to the same shard within the stream.
  --explicit-hash-key: string # The hash value used to explicitly determine the shard the data record is assigned to by overriding the partition key hash.
  --sequence-number-for-ordering: string # Guarantees strictly increasing sequence numbers, for puts from the same client and to the same partition key. Usage: set the SequenceNumberForOrdering of record n to the sequence number of record n-1 (as returned in the result when putting record n-1). If this parameter is not set, records are coarsely ordered based on arrival time.
  --stream-arn: string # The ARN of the stream.
]: any -> record<ShardId: string, SequenceNumber: string, EncryptionType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.PutRecord")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "Data": $data, "PartitionKey": $partition_key, "ExplicitHashKey": $explicit_hash_key, "SequenceNumberForOrdering": $sequence_number_for_ordering, "StreamARN": $stream_arn} | compact
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

# Writes multiple data records into a Kinesis data stream in a single call (also referred to as a PutRecords request). Use this operation to send data into the stream for data ingestion and processing. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. Each PutRecords request can support up to 500 records. Each record in the request can be as large as 1 MiB, up to a limit of 5 MiB for the entire request, including partition keys. Each shard can support writes up to 1,000 records per second, up to a maximum data write total of 1 MiB per second. You must specify the name of the stream that captures, stores, and transports the data; and an array of request Records, with each record in the array requiring a partition key and data blob. The record size limit applies to the total size of the partition key and data blob. The data blob can be any type of data; for example, a segment from a log file, geographic/location data, website clickstream data, and so on. The partition key is used by Kinesis Data Streams as input to a hash function that maps the partition key and associated data to a specific shard. An MD5 hash function is used to map partition keys to 128-bit integer values and to map associated data records to shards. As a result of this hashing mechanism, all data records with the same partition key map to the same shard within the stream. For more information, see Adding Data to a Stream (https://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-add-data-to-stream) in the Amazon Kinesis Data Streams Developer Guide. Each record in the Records array may include an optional parameter, ExplicitHashKey, which overrides the partition key to shard mapping. This parameter allows a data producer to determine explicitly the shard where the record is stored. For more information, see Adding Multiple Records with PutRecords (https://docs.aws.amazon.com/kinesis/latest/dev/developing-producers-with-sdk.html#kinesis-using-sdk-java-putrecords) in the Amazon Kinesis Data Streams Developer Guide. The PutRecords response includes an array of response Records. Each record in the response array directly correlates with a record in the request array using natural ordering, from the top to the bottom of the request and response. The response Records array always includes the same number of records as the request array. The response Records array includes both successfully and unsuccessfully processed records. Kinesis Data Streams attempts to process all records in each PutRecords request. A single record failure does not stop the processing of subsequent records. As a result, PutRecords doesn't guarantee the ordering of records. If you need to read records in the same order they are written to the stream, use PutRecord instead of PutRecords, and write to the same shard. A successfully processed record includes ShardId and SequenceNumber values. The ShardId parameter identifies the shard in the stream where the record is stored. The SequenceNumber parameter is an identifier assigned to the put record, unique to all records in the stream. An unsuccessfully processed record includes ErrorCode and ErrorMessage values. ErrorCode reflects the type of error and can be one of the following values: ProvisionedThroughputExceededException or InternalFailure. ErrorMessage provides more detailed information about the ProvisionedThroughputExceededException exception including the account ID, stream name, and shard ID of the record that was throttled. For more information about partially successful responses, see Adding Multiple Records with PutRecords (https://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-add-data-to-stream.html#kinesis-using-sdk-java-putrecords) in the Amazon Kinesis Data Streams Developer Guide. After you write a record to a stream, you cannot modify that record or its order within the stream. By default, data records are accessible for 24 hours from the time that they are added to a stream. You can use IncreaseStreamRetentionPeriod or DecreaseStreamRetentionPeriod to modify this retention period.
#
# POST /
# operationId: PutRecords
# --Records item shape: {Data: string, ExplicitHashKey?: string, PartitionKey: string}
export def "put-records" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  records: list # The records associated with the request. — item shape: {Data: string, ExplicitHashKey?: string, PartitionKey: string}
  --stream-name: string # The stream name associated with the request.
  --stream-arn: string # The ARN of the stream.
]: any -> record<FailedRecordCount: int, Records: table<SequenceNumber: string, ShardId: string, ErrorCode: string, ErrorMessage: string>, EncryptionType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.PutRecords")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Records": $records, "StreamName": $stream_name, "StreamARN": $stream_arn} | compact
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

# Registers a consumer with a Kinesis data stream. When you use this operation, the consumer you register can then call SubscribeToShard to receive data from the stream using enhanced fan-out, at a rate of up to 2 MiB per second for every shard you subscribe to. This rate is unaffected by the total number of consumers that read from the same stream. You can register up to 20 consumers per stream. A given consumer can only be registered with one stream at a time. For an example of how to use this operations, see Enhanced Fan-Out Using the Kinesis Data Streams API (/streams/latest/dev/building-enhanced-consumers-api.html). The use of this operation has a limit of five transactions per second per account. Also, only 5 consumers can be created simultaneously. In other words, you cannot have more than 5 consumers in a CREATING status at the same time. Registering a 6th consumer while there are 5 in a CREATING status results in a LimitExceededException.
#
# POST /
# operationId: RegisterStreamConsumer
export def "register-stream-consumer" [
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
  stream_arn: string # The ARN of the Kinesis data stream that you want to register the consumer with. For more info, see Amazon Resource Names (ARNs) and Amazon Web Services Service Namespaces (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-kinesis-streams).
  consumer_name: string # For a given Kinesis data stream, each consumer must have a unique name. However, consumer names don't have to be unique across data streams.
]: any -> record<Consumer: record<ConsumerName: string, ConsumerARN: string, ConsumerStatus: string, ConsumerCreationTimestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.RegisterStreamConsumer")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamARN": $stream_arn, "ConsumerName": $consumer_name} | compact
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

# Removes tags from the specified Kinesis data stream. Removed tags are deleted and cannot be recovered after this operation successfully completes. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. If you specify a tag that does not exist, it is ignored. RemoveTagsFromStream has a limit of five transactions per second per account.
#
# POST /
# operationId: RemoveTagsFromStream
export def "remove-tags-from-stream" [
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
  --stream-name: string # The name of the stream.
  tag_keys: list<string> # A list of tag keys. Each corresponding tag is removed from the stream.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.RemoveTagsFromStream")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "TagKeys": $tag_keys, "StreamARN": $stream_arn} | compact
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

# Splits a shard into two new shards in the Kinesis data stream, to increase the stream's capacity to ingest and transport data. SplitShard is called when there is a need to increase the overall capacity of a stream because of an expected increase in the volume of data records being ingested. This API is only supported for the data streams with the provisioned capacity mode. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. You can also use SplitShard when a shard appears to be approaching its maximum utilization; for example, the producers sending data into the specific shard are suddenly sending more than previously anticipated. You can also call SplitShard to increase stream capacity, so that more Kinesis Data Streams applications can simultaneously read data from the stream for real-time processing. You must specify the shard to be split and the new hash key, which is the position in the shard where the shard gets split in two. In many cases, the new hash key might be the average of the beginning and ending hash key, but it can be any hash key value in the range being mapped into the shard. For more information, see Split a Shard (https://docs.aws.amazon.com/kinesis/latest/dev/kinesis-using-sdk-java-resharding-split.html) in the Amazon Kinesis Data Streams Developer Guide. You can use DescribeStreamSummary and the ListShards APIs to determine the shard ID and hash key values for the ShardToSplit and NewStartingHashKey parameters that are specified in the SplitShard request. SplitShard is an asynchronous operation. Upon receiving a SplitShard request, Kinesis Data Streams immediately returns a response and sets the stream status to UPDATING. After the operation is completed, Kinesis Data Streams sets the stream status to ACTIVE. Read and write operations continue to work while the stream is in the UPDATING state. You can use DescribeStreamSummary to check the status of the stream, which is returned in StreamStatus. If the stream is in the ACTIVE state, you can call SplitShard. If the specified stream does not exist, DescribeStreamSummary returns a ResourceNotFoundException. If you try to create more shards than are authorized for your account, you receive a LimitExceededException. For the default shard limit for an Amazon Web Services account, see Kinesis Data Streams Limits (https://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html) in the Amazon Kinesis Data Streams Developer Guide. To increase this limit, contact Amazon Web Services Support (https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html). If you try to operate on too many streams simultaneously using CreateStream, DeleteStream, MergeShards, and/or SplitShard, you receive a LimitExceededException. SplitShard has a limit of five transactions per second per account.
#
# POST /
# operationId: SplitShard
export def "split-shard" [
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
  --stream-name: string # The name of the stream for the shard split.
  shard_to_split: string # The shard ID of the shard to split.
  new_starting_hash_key: string # A hash key value for the starting hash key of one of the child shards created by the split. The hash key range for a given shard constitutes a set of ordered contiguous positive integers. The value for NewStartingHashKey must be in the range of hash keys being mapped into the shard. The NewStartingHashKey hash key value and all higher hash key values in hash key range are distributed to one of the child shards. All the lower hash key values in the range are distributed to the other child shard.
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.SplitShard")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "ShardToSplit": $shard_to_split, "NewStartingHashKey": $new_starting_hash_key, "StreamARN": $stream_arn} | compact
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

# Enables or updates server-side encryption using an Amazon Web Services KMS key for a specified stream. Starting encryption is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to UPDATING. After the update is complete, Kinesis Data Streams sets the status of the stream back to ACTIVE. Updating or applying encryption normally takes a few seconds to complete, but it can take minutes. You can continue to read and write data to your stream while its status is UPDATING. Once the status of the stream is ACTIVE, encryption begins for records written to the stream. API Limits: You can successfully apply a new Amazon Web Services KMS key for server-side encryption 25 times in a rolling 24-hour period. Note: It can take up to 5 seconds after the stream is in an ACTIVE status before all records written to the stream are encrypted. After you enable encryption, you can verify that encryption is applied by inspecting the API response from PutRecord or PutRecords. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter.
#
# POST /
# operationId: StartStreamEncryption
export def "start-stream-encryption" [
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
  --stream-name: string # The name of the stream for which to start encrypting records.
  encryption_type: string@encryption-type-completer # The encryption type to use. The only valid value is KMS.
  key_id: string # The GUID for the customer-managed Amazon Web Services KMS key to use for encryption. This value can be a globally unique identifier, a fully specified Amazon Resource Name (ARN) to either an alias or a key, or an alias name prefixed by "alias/".You can also use a master key owned by Kinesis Data Streams by specifying the alias aws/kinesis. Key ARN example: arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012 Alias ARN example: arn:aws:kms:us-east-1:123456789012:alias/MyAliasName Globally unique key ID example: 12345678-1234-1234-1234-123456789012 Alias name example: alias/MyAliasName Master key owned by Kinesis Data Streams: alias/aws/kinesis
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.StartStreamEncryption")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "EncryptionType": $encryption_type, "KeyId": $key_id, "StreamARN": $stream_arn} | compact
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

# Disables server-side encryption for a specified stream. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. Stopping encryption is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to UPDATING. After the update is complete, Kinesis Data Streams sets the status of the stream back to ACTIVE. Stopping encryption normally takes a few seconds to complete, but it can take minutes. You can continue to read and write data to your stream while its status is UPDATING. Once the status of the stream is ACTIVE, records written to the stream are no longer encrypted by Kinesis Data Streams. API Limits: You can successfully disable server-side encryption 25 times in a rolling 24-hour period. Note: It can take up to 5 seconds after the stream is in an ACTIVE status before all records written to the stream are no longer subject to encryption. After you disabled encryption, you can verify that encryption is not applied by inspecting the API response from PutRecord or PutRecords.
#
# POST /
# operationId: StopStreamEncryption
export def "stop-stream-encryption" [
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
  --stream-name: string # The name of the stream on which to stop encrypting records.
  encryption_type: string@encryption-type-completer # The encryption type. The only valid value is KMS.
  key_id: string # The GUID for the customer-managed Amazon Web Services KMS key to use for encryption. This value can be a globally unique identifier, a fully specified Amazon Resource Name (ARN) to either an alias or a key, or an alias name prefixed by "alias/".You can also use a master key owned by Kinesis Data Streams by specifying the alias aws/kinesis. Key ARN example: arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012 Alias ARN example: arn:aws:kms:us-east-1:123456789012:alias/MyAliasName Globally unique key ID example: 12345678-1234-1234-1234-123456789012 Alias name example: alias/MyAliasName Master key owned by Kinesis Data Streams: alias/aws/kinesis
  --stream-arn: string # The ARN of the stream.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.StopStreamEncryption")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "EncryptionType": $encryption_type, "KeyId": $key_id, "StreamARN": $stream_arn} | compact
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

# Updates the shard count of the specified stream to the specified number of shards. This API is only supported for the data streams with the provisioned capacity mode. When invoking this API, it is recommended you use the StreamARN input parameter rather than the StreamName input parameter. Updating the shard count is an asynchronous operation. Upon receiving the request, Kinesis Data Streams returns immediately and sets the status of the stream to UPDATING. After the update is complete, Kinesis Data Streams sets the status of the stream back to ACTIVE. Depending on the size of the stream, the scaling action could take a few minutes to complete. You can continue to read and write data to your stream while its status is UPDATING. To update the shard count, Kinesis Data Streams performs splits or merges on individual shards. This can cause short-lived shards to be created, in addition to the final shards. These short-lived shards count towards your total shard limit for your account in the Region. When using this operation, we recommend that you specify a target shard count that is a multiple of 25% (25%, 50%, 75%, 100%). You can specify any target value within your shard limit. However, if you specify a target that isn't a multiple of 25%, the scaling action might take longer to complete. This operation has the following default limits. By default, you cannot do the following: Scale more than ten times per rolling 24-hour period per stream Scale up to more than double your current shard count for a stream Scale down below half your current shard count for a stream Scale up to more than 10000 shards in a stream Scale a stream with more than 10000 shards down unless the result is less than 10000 shards Scale up to more than the shard limit for your account For the default limits for an Amazon Web Services account, see Streams Limits (https://docs.aws.amazon.com/kinesis/latest/dev/service-sizes-and-limits.html) in the Amazon Kinesis Data Streams Developer Guide. To request an increase in the call rate limit, the shard limit for this API, or your overall shard limit, use the limits form (https://console.aws.amazon.com/support/v1#/case/create?issueType=service-limit-increase&limitType=service-code-kinesis).
#
# POST /
# operationId: UpdateShardCount
export def "update-shard-count" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  --stream-name: string # The name of the stream.
  target_shard_count: int # The new number of shards. This value has the following default limits. By default, you cannot do the following: Set this value to more than double your current shard count for a stream. Set this value below half your current shard count for a stream. Set this value to more than 10000 shards in a stream (the default limit for shard count per stream is 10000 per account per region), unless you request a limit increase. Scale a stream with more than 10000 shards down unless you set this value to less than 10000 shards.
  scaling_type: string@scaling-type-completer # The scaling type. Uniform scaling creates shards of equal size.
  --stream-arn: string # The ARN of the stream.
]: any -> record<StreamName: string, CurrentShardCount: int, TargetShardCount: int, StreamARN: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.UpdateShardCount")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamName": $stream_name, "TargetShardCount": $target_shard_count, "ScalingType": $scaling_type, "StreamARN": $stream_arn} | compact
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

# Updates the capacity mode of the data stream. Currently, in Kinesis Data Streams, you can choose between an on-demand capacity mode and a provisioned capacity mode for your data stream.
#
# POST /
# operationId: UpdateStreamMode
# --StreamModeDetails shape: {StreamMode: "PROVISIONED"|"ON_DEMAND"}
export def "update-stream-mode" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  stream_arn: string # Specifies the ARN of the data stream whose capacity mode you want to update.
  stream_mode_details: record # Specifies the capacity mode to which you want to set your data stream. Currently, in Kinesis Data Streams, you can choose between an on-demand capacity mode and a provisioned capacity mode for your data streams. — shape: {StreamMode: "PROVISIONED"|"ON_DEMAND"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "Kinesis_20131202.UpdateStreamMode")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StreamARN": $stream_arn, "StreamModeDetails": $stream_mode_details} | compact
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
