# Auto-generated client for Amazon Kinesis Analytics v2018-05-23
# Source: https://api.apis.guru/v2/specs/amazonaws.com/kinesisanalyticsv2/2018-05-23/openapi.json
# Auth: --token flag or $env.AMAZON_KINESIS_ANALYTICS_TOKEN

const BASE_URL = "http://kinesisanalytics.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_KINESIS_ANALYTICS_TOKEN | default "" }
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

def base-url-completer [] { ["http://kinesisanalytics.us-east-1.amazonaws.com" "http://kinesisanalytics.us-east-2.amazonaws.com" "http://kinesisanalytics.us-west-1.amazonaws.com" "http://kinesisanalytics.us-west-2.amazonaws.com" "http://kinesisanalytics.us-gov-west-1.amazonaws.com" "http://kinesisanalytics.us-gov-east-1.amazonaws.com" "http://kinesisanalytics.ca-central-1.amazonaws.com" "http://kinesisanalytics.eu-north-1.amazonaws.com" "http://kinesisanalytics.eu-west-1.amazonaws.com" "http://kinesisanalytics.eu-west-2.amazonaws.com" "http://kinesisanalytics.eu-west-3.amazonaws.com" "http://kinesisanalytics.eu-central-1.amazonaws.com" "http://kinesisanalytics.eu-south-1.amazonaws.com" "http://kinesisanalytics.af-south-1.amazonaws.com" "http://kinesisanalytics.ap-northeast-1.amazonaws.com" "http://kinesisanalytics.ap-northeast-2.amazonaws.com" "http://kinesisanalytics.ap-northeast-3.amazonaws.com" "http://kinesisanalytics.ap-southeast-1.amazonaws.com" "http://kinesisanalytics.ap-southeast-2.amazonaws.com" "http://kinesisanalytics.ap-east-1.amazonaws.com" "http://kinesisanalytics.ap-south-1.amazonaws.com" "http://kinesisanalytics.sa-east-1.amazonaws.com" "http://kinesisanalytics.me-south-1.amazonaws.com" "https://kinesisanalytics.us-east-1.amazonaws.com" "https://kinesisanalytics.us-east-2.amazonaws.com" "https://kinesisanalytics.us-west-1.amazonaws.com" "https://kinesisanalytics.us-west-2.amazonaws.com" "https://kinesisanalytics.us-gov-west-1.amazonaws.com" "https://kinesisanalytics.us-gov-east-1.amazonaws.com" "https://kinesisanalytics.ca-central-1.amazonaws.com" "https://kinesisanalytics.eu-north-1.amazonaws.com" "https://kinesisanalytics.eu-west-1.amazonaws.com" "https://kinesisanalytics.eu-west-2.amazonaws.com" "https://kinesisanalytics.eu-west-3.amazonaws.com" "https://kinesisanalytics.eu-central-1.amazonaws.com" "https://kinesisanalytics.eu-south-1.amazonaws.com" "https://kinesisanalytics.af-south-1.amazonaws.com" "https://kinesisanalytics.ap-northeast-1.amazonaws.com" "https://kinesisanalytics.ap-northeast-2.amazonaws.com" "https://kinesisanalytics.ap-northeast-3.amazonaws.com" "https://kinesisanalytics.ap-southeast-1.amazonaws.com" "https://kinesisanalytics.ap-southeast-2.amazonaws.com" "https://kinesisanalytics.ap-east-1.amazonaws.com" "https://kinesisanalytics.ap-south-1.amazonaws.com" "https://kinesisanalytics.sa-east-1.amazonaws.com" "https://kinesisanalytics.me-south-1.amazonaws.com" "http://kinesisanalytics.cn-north-1.amazonaws.com.cn" "http://kinesisanalytics.cn-northwest-1.amazonaws.com.cn" "https://kinesisanalytics.cn-north-1.amazonaws.com.cn" "https://kinesisanalytics.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["KinesisAnalytics_20180523.AddApplicationCloudWatchLoggingOption"] }
def x-amz-target-completer-1 [] { ["KinesisAnalytics_20180523.AddApplicationInput"] }
def x-amz-target-completer-2 [] { ["KinesisAnalytics_20180523.AddApplicationInputProcessingConfiguration"] }
def x-amz-target-completer-3 [] { ["KinesisAnalytics_20180523.AddApplicationOutput"] }
def x-amz-target-completer-4 [] { ["KinesisAnalytics_20180523.AddApplicationReferenceDataSource"] }
def x-amz-target-completer-5 [] { ["KinesisAnalytics_20180523.AddApplicationVpcConfiguration"] }
def runtime-environment-completer [] { ["FLINK-1_11" "FLINK-1_13" "FLINK-1_15" "FLINK-1_6" "FLINK-1_8" "SQL-1_0" "ZEPPELIN-FLINK-1_0" "ZEPPELIN-FLINK-2_0"] }
def application-mode-completer [] { ["INTERACTIVE" "STREAMING"] }
def x-amz-target-completer-6 [] { ["KinesisAnalytics_20180523.CreateApplication"] }
def url-type-completer [] { ["FLINK_DASHBOARD_URL" "ZEPPELIN_UI_URL"] }
def x-amz-target-completer-7 [] { ["KinesisAnalytics_20180523.CreateApplicationPresignedUrl"] }
def x-amz-target-completer-8 [] { ["KinesisAnalytics_20180523.CreateApplicationSnapshot"] }
def x-amz-target-completer-9 [] { ["KinesisAnalytics_20180523.DeleteApplication"] }
def x-amz-target-completer-10 [] { ["KinesisAnalytics_20180523.DeleteApplicationCloudWatchLoggingOption"] }
def x-amz-target-completer-11 [] { ["KinesisAnalytics_20180523.DeleteApplicationInputProcessingConfiguration"] }
def x-amz-target-completer-12 [] { ["KinesisAnalytics_20180523.DeleteApplicationOutput"] }
def x-amz-target-completer-13 [] { ["KinesisAnalytics_20180523.DeleteApplicationReferenceDataSource"] }
def x-amz-target-completer-14 [] { ["KinesisAnalytics_20180523.DeleteApplicationSnapshot"] }
def x-amz-target-completer-15 [] { ["KinesisAnalytics_20180523.DeleteApplicationVpcConfiguration"] }
def x-amz-target-completer-16 [] { ["KinesisAnalytics_20180523.DescribeApplication"] }
def x-amz-target-completer-17 [] { ["KinesisAnalytics_20180523.DescribeApplicationSnapshot"] }
def x-amz-target-completer-18 [] { ["KinesisAnalytics_20180523.DescribeApplicationVersion"] }
def x-amz-target-completer-19 [] { ["KinesisAnalytics_20180523.DiscoverInputSchema"] }
def x-amz-target-completer-20 [] { ["KinesisAnalytics_20180523.ListApplicationSnapshots"] }
def x-amz-target-completer-21 [] { ["KinesisAnalytics_20180523.ListApplicationVersions"] }
def x-amz-target-completer-22 [] { ["KinesisAnalytics_20180523.ListApplications"] }
def x-amz-target-completer-23 [] { ["KinesisAnalytics_20180523.ListTagsForResource"] }
def x-amz-target-completer-24 [] { ["KinesisAnalytics_20180523.RollbackApplication"] }
def x-amz-target-completer-25 [] { ["KinesisAnalytics_20180523.StartApplication"] }
def x-amz-target-completer-26 [] { ["KinesisAnalytics_20180523.StopApplication"] }
def x-amz-target-completer-27 [] { ["KinesisAnalytics_20180523.TagResource"] }
def x-amz-target-completer-28 [] { ["KinesisAnalytics_20180523.UntagResource"] }
def x-amz-target-completer-29 [] { ["KinesisAnalytics_20180523.UpdateApplication"] }
def x-amz-target-completer-30 [] { ["KinesisAnalytics_20180523.UpdateApplicationMaintenanceConfiguration"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "add-application-cloud-watch-logging-option" } } | get name | first)
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

# Adds an Amazon CloudWatch log stream to monitor application configuration errors.
#
# POST /
# operationId: AddApplicationCloudWatchLoggingOption
# --CloudWatchLoggingOption shape: {LogStreamARN: string}
export def "add-application-cloud-watch-logging-option" [
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
  application_name: string # The Kinesis Data Analytics application name.
  --current-application-version-id: int # The version ID of the Kinesis Data Analytics application. You must provide the CurrentApplicationVersionId or the ConditionalToken.You can retrieve the application version ID using DescribeApplication. For better concurrency support, use the ConditionalToken parameter instead of CurrentApplicationVersionId.
  cloud_watch_logging_option: record # Provides a description of Amazon CloudWatch logging options, including the log stream Amazon Resource Name (ARN). — shape: {LogStreamARN: string}
  --conditional-token: string # A value you use to implement strong concurrency for application updates. You must provide the CurrentApplicationVersionId or the ConditionalToken. You get the application's current ConditionalToken using DescribeApplication. For better concurrency support, use the ConditionalToken parameter instead of CurrentApplicationVersionId.
]: any -> record<ApplicationARN: string, ApplicationVersionId: int, CloudWatchLoggingOptionDescriptions: table<CloudWatchLoggingOptionId: string, LogStreamARN: string, RoleARN: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.AddApplicationCloudWatchLoggingOption")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CurrentApplicationVersionId": $current_application_version_id, "CloudWatchLoggingOption": $cloud_watch_logging_option, "ConditionalToken": $conditional_token} | compact
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

# Adds a streaming source to your SQL-based Kinesis Data Analytics application. You can add a streaming source when you create an application, or you can use this operation to add a streaming source after you create an application. For more information, see CreateApplication. Any configuration update, including adding a streaming source using this operation, results in a new version of the application. You can use the DescribeApplication operation to find the current application version.
#
# POST /
# operationId: AddApplicationInput
# --Input shape: {NamePrefix: string, InputProcessingConfiguration?: record, KinesisStreamsInput?: record, KinesisFirehoseInput?: record, InputParallelism?: record, InputSchema: record}
export def "add-application-input" [
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
  application_name: string # The name of your existing application to which you want to add the streaming source.
  current_application_version_id: int # The current version of your application. You must provide the ApplicationVersionID or the ConditionalToken.You can use the DescribeApplication operation to find the current application version.
  --body-input: record # When you configure the application input for a SQL-based Kinesis Data Analytics application, you specify the streaming source, the in-application stream name that is created, and the mapping between the two. — shape: {NamePrefix: string, InputProcessingConfiguration?: record, KinesisStreamsInput?: record, KinesisFirehoseInput?: record, InputParallelism?: record, InputSchema: record}
]: any -> record<ApplicationARN: string, ApplicationVersionId: int, InputDescriptions: table<InputId: string, NamePrefix: string, InAppStreamNames: list, InputProcessingConfigurationDescription: record, KinesisStreamsInputDescription: record, KinesisFirehoseInputDescription: record, InputSchema: record, InputParallelism: record, InputStartingPositionConfiguration: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.AddApplicationInput")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CurrentApplicationVersionId": $current_application_version_id, "Input": $body_input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "Input") == null) { error make --unspanned { msg: "required body field 'Input' missing: pass --body-input or pipe a record" } }
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

# Adds an InputProcessingConfiguration to a SQL-based Kinesis Data Analytics application. An input processor pre-processes records on the input stream before the application's SQL code executes. Currently, the only input processor available is Amazon Lambda (https://docs.aws.amazon.com/lambda/).
#
# POST /
# operationId: AddApplicationInputProcessingConfiguration
# --InputProcessingConfiguration shape: {InputLambdaProcessor: record}
export def "add-application-input-processing-configuration" [
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
  application_name: string # The name of the application to which you want to add the input processing configuration.
  current_application_version_id: int # The version of the application to which you want to add the input processing configuration. You can use the DescribeApplication operation to get the current application version. If the version specified is not the current version, the ConcurrentModificationException is returned.
  input_id: string # The ID of the input configuration to add the input processing configuration to. You can get a list of the input IDs for an application using the DescribeApplication operation.
  input_processing_configuration: record # For a SQL-based Kinesis Data Analytics application, describes a processor that is used to preprocess the records in the stream before being processed by your application code. Currently, the only input processor available is Amazon Lambda (https://docs.aws.amazon.com/lambda/). — shape: {InputLambdaProcessor: record}
]: any -> record<ApplicationARN: string, ApplicationVersionId: int, InputId: string, InputProcessingConfigurationDescription: record<InputLambdaProcessorDescription: record<ResourceARN: string, RoleARN: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.AddApplicationInputProcessingConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CurrentApplicationVersionId": $current_application_version_id, "InputId": $input_id, "InputProcessingConfiguration": $input_processing_configuration} | compact
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

# Adds an external destination to your SQL-based Kinesis Data Analytics application. If you want Kinesis Data Analytics to deliver data from an in-application stream within your application to an external destination (such as an Kinesis data stream, a Kinesis Data Firehose delivery stream, or an Amazon Lambda function), you add the relevant configuration to your application using this operation. You can configure one or more outputs for your application. Each output configuration maps an in-application stream and an external destination. You can use one of the output configurations to deliver data from your in-application error stream to an external destination so that you can analyze the errors. Any configuration update, including adding a streaming source using this operation, results in a new version of the application. You can use the DescribeApplication operation to find the current application version.
#
# POST /
# operationId: AddApplicationOutput
# --Output shape: {Name: string, KinesisStreamsOutput?: record, KinesisFirehoseOutput?: record, LambdaOutput?: record, DestinationSchema: record}
export def "add-application-output" [
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
  application_name: string # The name of the application to which you want to add the output configuration.
  current_application_version_id: int # The version of the application to which you want to add the output configuration. You can use the DescribeApplication operation to get the current application version. If the version specified is not the current version, the ConcurrentModificationException is returned.
  output: record # Describes a SQL-based Kinesis Data Analytics application's output configuration, in which you identify an in-application stream and a destination where you want the in-application stream data to be written. The destination can be a Kinesis data stream or a Kinesis Data Firehose delivery stream. — shape: {Name: string, KinesisStreamsOutput?: record, KinesisFirehoseOutput?: record, LambdaOutput?: record, DestinationSchema: record}
]: any -> record<ApplicationARN: string, ApplicationVersionId: int, OutputDescriptions: table<OutputId: string, Name: string, KinesisStreamsOutputDescription: record, KinesisFirehoseOutputDescription: record, LambdaOutputDescription: record, DestinationSchema: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.AddApplicationOutput")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CurrentApplicationVersionId": $current_application_version_id, "Output": $output} | compact
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

# Adds a reference data source to an existing SQL-based Kinesis Data Analytics application. Kinesis Data Analytics reads reference data (that is, an Amazon S3 object) and creates an in-application table within your application. In the request, you provide the source (S3 bucket name and object key name), name of the in-application table to create, and the necessary mapping information that describes how data in an Amazon S3 object maps to columns in the resulting in-application table.
#
# POST /
# operationId: AddApplicationReferenceDataSource
# --ReferenceDataSource shape: {TableName: string, S3ReferenceDataSource?: record, ReferenceSchema: record}
export def "add-application-reference-data-source" [
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
  application_name: string # The name of an existing application.
  current_application_version_id: int # The version of the application for which you are adding the reference data source. You can use the DescribeApplication operation to get the current application version. If the version specified is not the current version, the ConcurrentModificationException is returned.
  reference_data_source: record # For a SQL-based Kinesis Data Analytics application, describes the reference data source by providing the source information (Amazon S3 bucket name and object key name), the resulting in-application table name that is created, and the necessary schema to map the data elements in the Amazon S3 object to the in-application table. — shape: {TableName: string, S3ReferenceDataSource?: record, ReferenceSchema: record}
]: any -> record<ApplicationARN: string, ApplicationVersionId: int, ReferenceDataSourceDescriptions: table<ReferenceId: string, TableName: string, S3ReferenceDataSourceDescription: record, ReferenceSchema: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.AddApplicationReferenceDataSource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CurrentApplicationVersionId": $current_application_version_id, "ReferenceDataSource": $reference_data_source} | compact
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

# Adds a Virtual Private Cloud (VPC) configuration to the application. Applications can use VPCs to store and access resources securely. Note the following about VPC configurations for Kinesis Data Analytics applications: VPC configurations are not supported for SQL applications. When a VPC is added to a Kinesis Data Analytics application, the application can no longer be accessed from the Internet directly. To enable Internet access to the application, add an Internet gateway to your VPC.
#
# POST /
# operationId: AddApplicationVpcConfiguration
# --VpcConfiguration shape: {SubnetIds: list<string>, SecurityGroupIds: list<string>}
export def "add-application-vpc-configuration" [
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
  application_name: string # The name of an existing application.
  --current-application-version-id: int # The version of the application to which you want to add the VPC configuration. You must provide the CurrentApplicationVersionId or the ConditionalToken. You can use the DescribeApplication operation to get the current application version. If the version specified is not the current version, the ConcurrentModificationException is returned. For better concurrency support, use the ConditionalToken parameter instead of CurrentApplicationVersionId.
  vpc_configuration: record # Describes the parameters of a VPC used by the application. — shape: {SubnetIds: list<string>, SecurityGroupIds: list<string>}
  --conditional-token: string # A value you use to implement strong concurrency for application updates. You must provide the ApplicationVersionID or the ConditionalToken. You get the application's current ConditionalToken using DescribeApplication. For better concurrency support, use the ConditionalToken parameter instead of CurrentApplicationVersionId.
]: any -> record<ApplicationARN: string, ApplicationVersionId: int, VpcConfigurationDescription: record<VpcConfigurationId: string, VpcId: string, SubnetIds: list<string>, SecurityGroupIds: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.AddApplicationVpcConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CurrentApplicationVersionId": $current_application_version_id, "VpcConfiguration": $vpc_configuration, "ConditionalToken": $conditional_token} | compact
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

# Creates a Kinesis Data Analytics application. For information about creating a Kinesis Data Analytics application, see Creating an Application (https://docs.aws.amazon.com/kinesisanalytics/latest/java/getting-started.html).
#
# POST /
# operationId: CreateApplication
# --ApplicationConfiguration shape: {SqlApplicationConfiguration?: record, FlinkApplicationConfiguration?: record, EnvironmentProperties?: record, ApplicationCodeConfiguration?: record, ApplicationSnapshotConfiguration?: record, VpcConfigurations?: list, ZeppelinApplicationConfiguration?: record}
# --CloudWatchLoggingOptions item shape: {LogStreamARN: string}
# --Tags item shape: {Key: string, Value?: string}
export def "create-application" [
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
  application_name: string # The name of your application (for example, sample-app).
  --application-description: string # A summary description of the application.
  runtime_environment: string@runtime-environment-completer # The runtime environment for the application.
  service_execution_role: string # The IAM role used by the application to access Kinesis data streams, Kinesis Data Firehose delivery streams, Amazon S3 objects, and other external resources.
  --application-configuration: record # Specifies the creation parameters for a Kinesis Data Analytics application. — shape: {SqlApplicationConfiguration?: record, FlinkApplicationConfiguration?: record, EnvironmentProperties?: record, ApplicationCodeConfiguration?: record, ApplicationSnapshotConfiguration?: record, VpcConfigurations?: list, ZeppelinApplicationConfiguration?: record}
  --cloud-watch-logging-options: list # Use this parameter to configure an Amazon CloudWatch log stream to monitor application configuration errors. — item shape: {LogStreamARN: string}
  --tags: list # A list of one or more tags to assign to the application. A tag is a key-value pair that identifies an application. Note that the maximum number of application tags includes system tags. The maximum number of user-defined application tags is 50. For more information, see Using Tagging (https://docs.aws.amazon.com/kinesisanalytics/latest/java/how-tagging.html). — item shape: {Key: string, Value?: string}
  --application-mode: string@application-mode-completer # Use the STREAMING mode to create a Kinesis Data Analytics For Flink application. To create a Kinesis Data Analytics Studio notebook, use the INTERACTIVE mode.
]: any -> record<ApplicationDetail: record<ApplicationARN: string, ApplicationDescription: string, ApplicationName: string, RuntimeEnvironment: string, ServiceExecutionRole: string, ApplicationStatus: string, ApplicationVersionId: int, CreateTimestamp: string, LastUpdateTimestamp: string, ApplicationConfigurationDescription: record<SqlApplicationConfigurationDescription: record, ApplicationCodeConfigurationDescription: record, RunConfigurationDescription: record, FlinkApplicationConfigurationDescription: record, EnvironmentPropertyDescriptions: record, ApplicationSnapshotConfigurationDescription: record, VpcConfigurationDescriptions: list, ZeppelinApplicationConfigurationDescription: record>, CloudWatchLoggingOptionDescriptions: list<record>, ApplicationMaintenanceConfigurationDescription: record<ApplicationMaintenanceWindowStartTime: string, ApplicationMaintenanceWindowEndTime: string>, ApplicationVersionUpdatedFrom: int, ApplicationVersionRolledBackFrom: int, ConditionalToken: string, ApplicationVersionRolledBackTo: int, ApplicationMode: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.CreateApplication")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "ApplicationDescription": $application_description, "RuntimeEnvironment": $runtime_environment, "ServiceExecutionRole": $service_execution_role, "ApplicationConfiguration": $application_configuration, "CloudWatchLoggingOptions": $cloud_watch_logging_options, "Tags": $tags, "ApplicationMode": $application_mode} | compact
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

# Creates and returns a URL that you can use to connect to an application's extension. The IAM role or user used to call this API defines the permissions to access the extension. After the presigned URL is created, no additional permission is required to access this URL. IAM authorization policies for this API are also enforced for every HTTP request that attempts to connect to the extension. You control the amount of time that the URL will be valid using the SessionExpirationDurationInSeconds parameter. If you do not provide this parameter, the returned URL is valid for twelve hours. The URL that you get from a call to CreateApplicationPresignedUrl must be used within 3 minutes to be valid. If you first try to use the URL after the 3-minute limit expires, the service returns an HTTP 403 Forbidden error.
#
# POST /
# operationId: CreateApplicationPresignedUrl
export def "create-application-presigned-url" [
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
  application_name: string # The name of the application.
  url_type: string@url-type-completer # The type of the extension for which to create and return a URL. Currently, the only valid extension URL type is FLINK_DASHBOARD_URL.
  --session-expiration-duration-in-seconds: int # The duration in seconds for which the returned URL will be valid.
]: any -> record<AuthorizedUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.CreateApplicationPresignedUrl")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "UrlType": $url_type, "SessionExpirationDurationInSeconds": $session_expiration_duration_in_seconds} | compact
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

# Creates a snapshot of the application's state data.
#
# POST /
# operationId: CreateApplicationSnapshot
export def "create-application-snapshot" [
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
  application_name: string # The name of an existing application
  snapshot_name: string # An identifier for the application snapshot.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.CreateApplicationSnapshot")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "SnapshotName": $snapshot_name} | compact
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

# Deletes the specified application. Kinesis Data Analytics halts application execution and deletes the application.
#
# POST /
# operationId: DeleteApplication
export def "delete-application" [
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
  application_name: string # The name of the application to delete.
  create_timestamp: string # Use the DescribeApplication operation to get this value. (format: date-time)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.DeleteApplication")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CreateTimestamp": $create_timestamp} | compact
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

# Deletes an Amazon CloudWatch log stream from an Kinesis Data Analytics application.
#
# POST /
# operationId: DeleteApplicationCloudWatchLoggingOption
export def "delete-application-cloud-watch-logging-option" [
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
  application_name: string # The application name.
  --current-application-version-id: int # The version ID of the application. You must provide the CurrentApplicationVersionId or the ConditionalToken. You can retrieve the application version ID using DescribeApplication. For better concurrency support, use the ConditionalToken parameter instead of CurrentApplicationVersionId.
  cloud_watch_logging_option_id: string # The CloudWatchLoggingOptionId of the Amazon CloudWatch logging option to delete. You can get the CloudWatchLoggingOptionId by using the DescribeApplication operation.
  --conditional-token: string # A value you use to implement strong concurrency for application updates. You must provide the CurrentApplicationVersionId or the ConditionalToken. You get the application's current ConditionalToken using DescribeApplication. For better concurrency support, use the ConditionalToken parameter instead of CurrentApplicationVersionId.
]: any -> record<ApplicationARN: string, ApplicationVersionId: int, CloudWatchLoggingOptionDescriptions: table<CloudWatchLoggingOptionId: string, LogStreamARN: string, RoleARN: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.DeleteApplicationCloudWatchLoggingOption")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CurrentApplicationVersionId": $current_application_version_id, "CloudWatchLoggingOptionId": $cloud_watch_logging_option_id, "ConditionalToken": $conditional_token} | compact
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

# Deletes an InputProcessingConfiguration from an input.
#
# POST /
# operationId: DeleteApplicationInputProcessingConfiguration
export def "delete-application-input-processing-configuration" [
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
  application_name: string # The name of the application.
  current_application_version_id: int # The application version. You can use the DescribeApplication operation to get the current application version. If the version specified is not the current version, the ConcurrentModificationException is returned.
  input_id: string # The ID of the input configuration from which to delete the input processing configuration. You can get a list of the input IDs for an application by using the DescribeApplication operation.
]: any -> record<ApplicationARN: string, ApplicationVersionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.DeleteApplicationInputProcessingConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CurrentApplicationVersionId": $current_application_version_id, "InputId": $input_id} | compact
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

# Deletes the output destination configuration from your SQL-based Kinesis Data Analytics application's configuration. Kinesis Data Analytics will no longer write data from the corresponding in-application stream to the external output destination.
#
# POST /
# operationId: DeleteApplicationOutput
export def "delete-application-output" [
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
  application_name: string # The application name.
  current_application_version_id: int # The application version. You can use the DescribeApplication operation to get the current application version. If the version specified is not the current version, the ConcurrentModificationException is returned.
  output_id: string # The ID of the configuration to delete. Each output configuration that is added to the application (either when the application is created or later) using the AddApplicationOutput operation has a unique ID. You need to provide the ID to uniquely identify the output configuration that you want to delete from the application configuration. You can use the DescribeApplication operation to get the specific OutputId.
]: any -> record<ApplicationARN: string, ApplicationVersionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.DeleteApplicationOutput")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CurrentApplicationVersionId": $current_application_version_id, "OutputId": $output_id} | compact
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

# Deletes a reference data source configuration from the specified SQL-based Kinesis Data Analytics application's configuration. If the application is running, Kinesis Data Analytics immediately removes the in-application table that you created using the AddApplicationReferenceDataSource operation.
#
# POST /
# operationId: DeleteApplicationReferenceDataSource
export def "delete-application-reference-data-source" [
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
  application_name: string # The name of an existing application.
  current_application_version_id: int # The current application version. You can use the DescribeApplication operation to get the current application version. If the version specified is not the current version, the ConcurrentModificationException is returned.
  reference_id: string # The ID of the reference data source. When you add a reference data source to your application using the AddApplicationReferenceDataSource, Kinesis Data Analytics assigns an ID. You can use the DescribeApplication operation to get the reference ID.
]: any -> record<ApplicationARN: string, ApplicationVersionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.DeleteApplicationReferenceDataSource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CurrentApplicationVersionId": $current_application_version_id, "ReferenceId": $reference_id} | compact
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

# Deletes a snapshot of application state.
#
# POST /
# operationId: DeleteApplicationSnapshot
export def "delete-application-snapshot" [
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
  application_name: string # The name of an existing application.
  snapshot_name: string # The identifier for the snapshot delete.
  snapshot_creation_timestamp: string # The creation timestamp of the application snapshot to delete. You can retrieve this value using or . (format: date-time)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.DeleteApplicationSnapshot")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "SnapshotName": $snapshot_name, "SnapshotCreationTimestamp": $snapshot_creation_timestamp} | compact
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

# Removes a VPC configuration from a Kinesis Data Analytics application.
#
# POST /
# operationId: DeleteApplicationVpcConfiguration
export def "delete-application-vpc-configuration" [
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
  application_name: string # The name of an existing application.
  --current-application-version-id: int # The current application version ID. You must provide the CurrentApplicationVersionId or the ConditionalToken. You can retrieve the application version ID using DescribeApplication. For better concurrency support, use the ConditionalToken parameter instead of CurrentApplicationVersionId.
  vpc_configuration_id: string # The ID of the VPC configuration to delete.
  --conditional-token: string # A value you use to implement strong concurrency for application updates. You must provide the CurrentApplicationVersionId or the ConditionalToken. You get the application's current ConditionalToken using DescribeApplication. For better concurrency support, use the ConditionalToken parameter instead of CurrentApplicationVersionId.
]: any -> record<ApplicationARN: string, ApplicationVersionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.DeleteApplicationVpcConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CurrentApplicationVersionId": $current_application_version_id, "VpcConfigurationId": $vpc_configuration_id, "ConditionalToken": $conditional_token} | compact
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

# Returns information about a specific Kinesis Data Analytics application. If you want to retrieve a list of all applications in your account, use the ListApplications operation.
#
# POST /
# operationId: DescribeApplication
export def "describe-application" [
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
  application_name: string # The name of the application.
  --include-additional-details: oneof<nothing, bool> # Displays verbose information about a Kinesis Data Analytics application, including the application's job plan.
]: any -> record<ApplicationDetail: record<ApplicationARN: string, ApplicationDescription: string, ApplicationName: string, RuntimeEnvironment: string, ServiceExecutionRole: string, ApplicationStatus: string, ApplicationVersionId: int, CreateTimestamp: string, LastUpdateTimestamp: string, ApplicationConfigurationDescription: record<SqlApplicationConfigurationDescription: record, ApplicationCodeConfigurationDescription: record, RunConfigurationDescription: record, FlinkApplicationConfigurationDescription: record, EnvironmentPropertyDescriptions: record, ApplicationSnapshotConfigurationDescription: record, VpcConfigurationDescriptions: list, ZeppelinApplicationConfigurationDescription: record>, CloudWatchLoggingOptionDescriptions: list<record>, ApplicationMaintenanceConfigurationDescription: record<ApplicationMaintenanceWindowStartTime: string, ApplicationMaintenanceWindowEndTime: string>, ApplicationVersionUpdatedFrom: int, ApplicationVersionRolledBackFrom: int, ConditionalToken: string, ApplicationVersionRolledBackTo: int, ApplicationMode: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.DescribeApplication")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "IncludeAdditionalDetails": $include_additional_details} | compact
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

# Returns information about a snapshot of application state data.
#
# POST /
# operationId: DescribeApplicationSnapshot
export def "describe-application-snapshot" [
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
  application_name: string # The name of an existing application.
  snapshot_name: string # The identifier of an application snapshot. You can retrieve this value using .
]: any -> record<SnapshotDetails: record<SnapshotName: string, SnapshotStatus: string, ApplicationVersionId: int, SnapshotCreationTimestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.DescribeApplicationSnapshot")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "SnapshotName": $snapshot_name} | compact
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

# Provides a detailed description of a specified version of the application. To see a list of all the versions of an application, invoke the ListApplicationVersions operation. This operation is supported only for Amazon Kinesis Data Analytics for Apache Flink.
#
# POST /
# operationId: DescribeApplicationVersion
export def "describe-application-version" [
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
  application_name: string # The name of the application for which you want to get the version description.
  application_version_id: int # The ID of the application version for which you want to get the description.
]: any -> record<ApplicationVersionDetail: record<ApplicationARN: string, ApplicationDescription: string, ApplicationName: string, RuntimeEnvironment: string, ServiceExecutionRole: string, ApplicationStatus: string, ApplicationVersionId: int, CreateTimestamp: string, LastUpdateTimestamp: string, ApplicationConfigurationDescription: record<SqlApplicationConfigurationDescription: record, ApplicationCodeConfigurationDescription: record, RunConfigurationDescription: record, FlinkApplicationConfigurationDescription: record, EnvironmentPropertyDescriptions: record, ApplicationSnapshotConfigurationDescription: record, VpcConfigurationDescriptions: list, ZeppelinApplicationConfigurationDescription: record>, CloudWatchLoggingOptionDescriptions: list<record>, ApplicationMaintenanceConfigurationDescription: record<ApplicationMaintenanceWindowStartTime: string, ApplicationMaintenanceWindowEndTime: string>, ApplicationVersionUpdatedFrom: int, ApplicationVersionRolledBackFrom: int, ConditionalToken: string, ApplicationVersionRolledBackTo: int, ApplicationMode: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.DescribeApplicationVersion")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "ApplicationVersionId": $application_version_id} | compact
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

# Infers a schema for a SQL-based Kinesis Data Analytics application by evaluating sample records on the specified streaming source (Kinesis data stream or Kinesis Data Firehose delivery stream) or Amazon S3 object. In the response, the operation returns the inferred schema and also the sample records that the operation used to infer the schema. You can use the inferred schema when configuring a streaming source for your application. When you create an application using the Kinesis Data Analytics console, the console uses this operation to infer a schema and show it in the console user interface.
#
# POST /
# operationId: DiscoverInputSchema
# --InputStartingPositionConfiguration shape: {InputStartingPosition?: "NOW"|"TRIM_HORIZON"|"LAST_STOPPED_POINT"}
# --S3Configuration shape: {BucketARN: string, FileKey: string}
# --InputProcessingConfiguration shape: {InputLambdaProcessor: record}
export def "discover-input-schema" [
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
  --resource-arn: string # The Amazon Resource Name (ARN) of the streaming source.
  service_execution_role: string # The ARN of the role that is used to access the streaming source.
  --input-starting-position-configuration: record # Describes the point at which the application reads from the streaming source. — shape: {InputStartingPosition?: "NOW"|"TRIM_HORIZON"|"LAST_STOPPED_POINT"}
  --s3-configuration: record # For a SQL-based Kinesis Data Analytics application, provides a description of an Amazon S3 data source, including the Amazon Resource Name (ARN) of the S3 bucket and the name of the Amazon S3 object that contains the data. — shape: {BucketARN: string, FileKey: string}
  --input-processing-configuration: record # For a SQL-based Kinesis Data Analytics application, describes a processor that is used to preprocess the records in the stream before being processed by your application code. Currently, the only input processor available is Amazon Lambda (https://docs.aws.amazon.com/lambda/). — shape: {InputLambdaProcessor: record}
]: any -> record<InputSchema: record<RecordFormat: record<RecordFormatType: string, MappingParameters: record>, RecordEncoding: string, RecordColumns: list<record>>, ParsedInputRecords: list<list<string>>, ProcessedInputRecords: list<string>, RawInputRecords: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.DiscoverInputSchema")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARN": $resource_arn, "ServiceExecutionRole": $service_execution_role, "InputStartingPositionConfiguration": $input_starting_position_configuration, "S3Configuration": $s3_configuration, "InputProcessingConfiguration": $input_processing_configuration} | compact
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

# Lists information about the current application snapshots.
#
# POST /
# operationId: ListApplicationSnapshots
export def "list-application-snapshots" [
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
  application_name: string # The name of an existing application.
  --limit: int # The maximum number of application snapshots to list.
  --next-token: string # Use this parameter if you receive a NextToken response in a previous request that indicates that there is more output available. Set it to the value of the previous call's NextToken response to indicate where the output should continue from.
]: any -> record<SnapshotSummaries: table<SnapshotName: string, SnapshotStatus: string, ApplicationVersionId: int, SnapshotCreationTimestamp: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.ListApplicationSnapshots")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "Limit": $limit, "NextToken": $next_token} | compact
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

# Lists all the versions for the specified application, including versions that were rolled back. The response also includes a summary of the configuration associated with each version. To get the complete description of a specific application version, invoke the DescribeApplicationVersion operation. This operation is supported only for Amazon Kinesis Data Analytics for Apache Flink.
#
# POST /
# operationId: ListApplicationVersions
export def "list-application-versions" [
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
  application_name: string # The name of the application for which you want to list all versions.
  --limit: int # The maximum number of versions to list in this invocation of the operation.
  --next-token: string # If a previous invocation of this operation returned a pagination token, pass it into this value to retrieve the next set of results. For more information about pagination, see Using the Amazon Command Line Interface's Pagination Options (https://docs.aws.amazon.com/cli/latest/userguide/pagination.html).
]: any -> record<ApplicationVersionSummaries: table<ApplicationVersionId: int, ApplicationStatus: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.ListApplicationVersions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "Limit": $limit, "NextToken": $next_token} | compact
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

# Returns a list of Kinesis Data Analytics applications in your account. For each application, the response includes the application name, Amazon Resource Name (ARN), and status. If you want detailed information about a specific application, use DescribeApplication.
#
# POST /
# operationId: ListApplications
export def "list-applications" [
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
  --limit: int # The maximum number of applications to list.
  --next-token: string # If a previous command returned a pagination token, pass it into this value to retrieve the next set of results. For more information about pagination, see Using the Amazon Command Line Interface's Pagination Options (https://docs.aws.amazon.com/cli/latest/userguide/pagination.html).
]: any -> record<ApplicationSummaries: table<ApplicationName: string, ApplicationARN: string, ApplicationStatus: string, ApplicationVersionId: int, RuntimeEnvironment: string, ApplicationMode: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.ListApplications")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Limit": $limit, "NextToken": $next_token} | compact
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

# Retrieves the list of key-value tags assigned to the application. For more information, see Using Tagging (https://docs.aws.amazon.com/kinesisanalytics/latest/java/how-tagging.html).
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23 # required
  resource_arn: string # The ARN of the application for which to retrieve tags.
]: any -> record<Tags: table<Key: string, Value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.ListTagsForResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARN": $resource_arn} | compact
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

# Reverts the application to the previous running version. You can roll back an application if you suspect it is stuck in a transient status. You can roll back an application only if it is in the UPDATING or AUTOSCALING status. When you rollback an application, it loads state data from the last successful snapshot. If the application has no snapshots, Kinesis Data Analytics rejects the rollback request. This action is not supported for Kinesis Data Analytics for SQL applications.
#
# POST /
# operationId: RollbackApplication
export def "rollback-application" [
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
  application_name: string # The name of the application.
  current_application_version_id: int # The current application version ID. You can retrieve the application version ID using DescribeApplication.
]: any -> record<ApplicationDetail: record<ApplicationARN: string, ApplicationDescription: string, ApplicationName: string, RuntimeEnvironment: string, ServiceExecutionRole: string, ApplicationStatus: string, ApplicationVersionId: int, CreateTimestamp: string, LastUpdateTimestamp: string, ApplicationConfigurationDescription: record<SqlApplicationConfigurationDescription: record, ApplicationCodeConfigurationDescription: record, RunConfigurationDescription: record, FlinkApplicationConfigurationDescription: record, EnvironmentPropertyDescriptions: record, ApplicationSnapshotConfigurationDescription: record, VpcConfigurationDescriptions: list, ZeppelinApplicationConfigurationDescription: record>, CloudWatchLoggingOptionDescriptions: list<record>, ApplicationMaintenanceConfigurationDescription: record<ApplicationMaintenanceWindowStartTime: string, ApplicationMaintenanceWindowEndTime: string>, ApplicationVersionUpdatedFrom: int, ApplicationVersionRolledBackFrom: int, ConditionalToken: string, ApplicationVersionRolledBackTo: int, ApplicationMode: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.RollbackApplication")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CurrentApplicationVersionId": $current_application_version_id} | compact
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

# Starts the specified Kinesis Data Analytics application. After creating an application, you must exclusively call this operation to start your application.
#
# POST /
# operationId: StartApplication
# --RunConfiguration shape: {FlinkRunConfiguration?: record, SqlRunConfigurations?: list, ApplicationRestoreConfiguration?: record}
export def "start-application" [
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
  application_name: string # The name of the application.
  --run-configuration: record # Describes the starting parameters for an Kinesis Data Analytics application. — shape: {FlinkRunConfiguration?: record, SqlRunConfigurations?: list, ApplicationRestoreConfiguration?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.StartApplication")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "RunConfiguration": $run_configuration} | compact
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

# Stops the application from processing data. You can stop an application only if it is in the running status, unless you set the Force parameter to true. You can use the DescribeApplication operation to find the application status. Kinesis Data Analytics takes a snapshot when the application is stopped, unless Force is set to true.
#
# POST /
# operationId: StopApplication
export def "stop-application" [
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
  application_name: string # The name of the running application to stop.
  --force: oneof<nothing, bool> # Set to true to force the application to stop. If you set Force to true, Kinesis Data Analytics stops the application without taking a snapshot. Force-stopping your application may lead to data loss or duplication. To prevent data loss or duplicate processing of data during application restarts, we recommend you to take frequent snapshots of your application. You can only force stop a Flink-based Kinesis Data Analytics application. You can't force stop a SQL-based Kinesis Data Analytics application. The application must be in the STARTING, UPDATING, STOPPING, AUTOSCALING, or RUNNING status.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.StopApplication")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "Force": $force} | compact
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

# Adds one or more key-value tags to a Kinesis Data Analytics application. Note that the maximum number of application tags includes system tags. The maximum number of user-defined application tags is 50. For more information, see Using Tagging (https://docs.aws.amazon.com/kinesisanalytics/latest/java/how-tagging.html).
#
# POST /
# operationId: TagResource
# --Tags item shape: {Key: string, Value?: string}
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  resource_arn: string # The ARN of the application to assign the tags.
  tags: list # The key-value tags to assign to the application. — item shape: {Key: string, Value?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.TagResource")
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

# Removes one or more tags from a Kinesis Data Analytics application. For more information, see Using Tagging (https://docs.aws.amazon.com/kinesisanalytics/latest/java/how-tagging.html).
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  resource_arn: string # The ARN of the Kinesis Data Analytics application from which to remove the tags.
  tag_keys: list<string> # A list of keys of tags to remove from the specified application.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.UntagResource")
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

# Updates an existing Kinesis Data Analytics application. Using this operation, you can update application code, input configuration, and output configuration. Kinesis Data Analytics updates the ApplicationVersionId each time you update your application. You cannot update the RuntimeEnvironment of an existing application. If you need to update an application's RuntimeEnvironment, you must delete the application and create it again.
#
# POST /
# operationId: UpdateApplication
# --ApplicationConfigurationUpdate shape: {SqlApplicationConfigurationUpdate?: record, ApplicationCodeConfigurationUpdate?: record, FlinkApplicationConfigurationUpdate?: record, EnvironmentPropertyUpdates?: record, ApplicationSnapshotConfigurationUpdate?: record, VpcConfigurationUpdates?: list, ZeppelinApplicationConfigurationUpdate?: record}
# --RunConfigurationUpdate shape: {FlinkRunConfiguration?: record, ApplicationRestoreConfiguration?: record}
# --CloudWatchLoggingOptionUpdates item shape: {CloudWatchLoggingOptionId: string, LogStreamARNUpdate?: string}
export def "update-application" [
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
  application_name: string # The name of the application to update.
  --current-application-version-id: int # The current application version ID. You must provide the CurrentApplicationVersionId or the ConditionalToken.You can retrieve the application version ID using DescribeApplication. For better concurrency support, use the ConditionalToken parameter instead of CurrentApplicationVersionId.
  --application-configuration-update: record # Describes updates to an application's configuration. — shape: {SqlApplicationConfigurationUpdate?: record, ApplicationCodeConfigurationUpdate?: record, FlinkApplicationConfigurationUpdate?: record, EnvironmentPropertyUpdates?: record, ApplicationSnapshotConfigurationUpdate?: record, VpcConfigurationUpdates?: list, ZeppelinApplicationConfigurationUpdate?: record}
  --service-execution-role-update: string # Describes updates to the service execution role.
  --run-configuration-update: record # Describes the updates to the starting parameters for a Kinesis Data Analytics application. — shape: {FlinkRunConfiguration?: record, ApplicationRestoreConfiguration?: record}
  --cloud-watch-logging-option-updates: list # Describes application Amazon CloudWatch logging option updates. You can only update existing CloudWatch logging options with this action. To add a new CloudWatch logging option, use AddApplicationCloudWatchLoggingOption. — item shape: {CloudWatchLoggingOptionId: string, LogStreamARNUpdate?: string}
  --conditional-token: string # A value you use to implement strong concurrency for application updates. You must provide the CurrentApplicationVersionId or the ConditionalToken. You get the application's current ConditionalToken using DescribeApplication. For better concurrency support, use the ConditionalToken parameter instead of CurrentApplicationVersionId.
]: any -> record<ApplicationDetail: record<ApplicationARN: string, ApplicationDescription: string, ApplicationName: string, RuntimeEnvironment: string, ServiceExecutionRole: string, ApplicationStatus: string, ApplicationVersionId: int, CreateTimestamp: string, LastUpdateTimestamp: string, ApplicationConfigurationDescription: record<SqlApplicationConfigurationDescription: record, ApplicationCodeConfigurationDescription: record, RunConfigurationDescription: record, FlinkApplicationConfigurationDescription: record, EnvironmentPropertyDescriptions: record, ApplicationSnapshotConfigurationDescription: record, VpcConfigurationDescriptions: list, ZeppelinApplicationConfigurationDescription: record>, CloudWatchLoggingOptionDescriptions: list<record>, ApplicationMaintenanceConfigurationDescription: record<ApplicationMaintenanceWindowStartTime: string, ApplicationMaintenanceWindowEndTime: string>, ApplicationVersionUpdatedFrom: int, ApplicationVersionRolledBackFrom: int, ConditionalToken: string, ApplicationVersionRolledBackTo: int, ApplicationMode: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.UpdateApplication")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "CurrentApplicationVersionId": $current_application_version_id, "ApplicationConfigurationUpdate": $application_configuration_update, "ServiceExecutionRoleUpdate": $service_execution_role_update, "RunConfigurationUpdate": $run_configuration_update, "CloudWatchLoggingOptionUpdates": $cloud_watch_logging_option_updates, "ConditionalToken": $conditional_token} | compact
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

# Updates the maintenance configuration of the Kinesis Data Analytics application. You can invoke this operation on an application that is in one of the two following states: READY or RUNNING. If you invoke it when the application is in a state other than these two states, it throws a ResourceInUseException. The service makes use of the updated configuration the next time it schedules maintenance for the application. If you invoke this operation after the service schedules maintenance, the service will apply the configuration update the next time it schedules maintenance for the application. This means that you might not see the maintenance configuration update applied to the maintenance process that follows a successful invocation of this operation, but to the following maintenance process instead. To see the current maintenance configuration of your application, invoke the DescribeApplication operation. For information about application maintenance, see Kinesis Data Analytics for Apache Flink Maintenance (https://docs.aws.amazon.com/kinesisanalytics/latest/java/maintenance.html). This operation is supported only for Amazon Kinesis Data Analytics for Apache Flink.
#
# POST /
# operationId: UpdateApplicationMaintenanceConfiguration
# --ApplicationMaintenanceConfigurationUpdate shape: {ApplicationMaintenanceWindowStartTimeUpdate: string}
export def "update-application-maintenance-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  application_name: string # The name of the application for which you want to update the maintenance configuration.
  application_maintenance_configuration_update: record # Describes the updated maintenance configuration for the application. — shape: {ApplicationMaintenanceWindowStartTimeUpdate: string}
]: any -> record<ApplicationARN: string, ApplicationMaintenanceConfigurationDescription: record<ApplicationMaintenanceWindowStartTime: string, ApplicationMaintenanceWindowEndTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "KinesisAnalytics_20180523.UpdateApplicationMaintenanceConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ApplicationName": $application_name, "ApplicationMaintenanceConfigurationUpdate": $application_maintenance_configuration_update} | compact
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
