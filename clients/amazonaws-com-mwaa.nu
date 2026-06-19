# Auto-generated client for AmazonMWAA v2020-07-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/mwaa/2020-07-01/openapi.json
# Auth: --token flag or $env.AMAZONMWAA_TOKEN

const BASE_URL = "http://airflow.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZONMWAA_TOKEN | default "" }
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

def base-url-completer [] { ["http://airflow.us-east-1.amazonaws.com" "http://airflow.us-east-2.amazonaws.com" "http://airflow.us-west-1.amazonaws.com" "http://airflow.us-west-2.amazonaws.com" "http://airflow.us-gov-west-1.amazonaws.com" "http://airflow.us-gov-east-1.amazonaws.com" "http://airflow.ca-central-1.amazonaws.com" "http://airflow.eu-north-1.amazonaws.com" "http://airflow.eu-west-1.amazonaws.com" "http://airflow.eu-west-2.amazonaws.com" "http://airflow.eu-west-3.amazonaws.com" "http://airflow.eu-central-1.amazonaws.com" "http://airflow.eu-south-1.amazonaws.com" "http://airflow.af-south-1.amazonaws.com" "http://airflow.ap-northeast-1.amazonaws.com" "http://airflow.ap-northeast-2.amazonaws.com" "http://airflow.ap-northeast-3.amazonaws.com" "http://airflow.ap-southeast-1.amazonaws.com" "http://airflow.ap-southeast-2.amazonaws.com" "http://airflow.ap-east-1.amazonaws.com" "http://airflow.ap-south-1.amazonaws.com" "http://airflow.sa-east-1.amazonaws.com" "http://airflow.me-south-1.amazonaws.com" "https://airflow.us-east-1.amazonaws.com" "https://airflow.us-east-2.amazonaws.com" "https://airflow.us-west-1.amazonaws.com" "https://airflow.us-west-2.amazonaws.com" "https://airflow.us-gov-west-1.amazonaws.com" "https://airflow.us-gov-east-1.amazonaws.com" "https://airflow.ca-central-1.amazonaws.com" "https://airflow.eu-north-1.amazonaws.com" "https://airflow.eu-west-1.amazonaws.com" "https://airflow.eu-west-2.amazonaws.com" "https://airflow.eu-west-3.amazonaws.com" "https://airflow.eu-central-1.amazonaws.com" "https://airflow.eu-south-1.amazonaws.com" "https://airflow.af-south-1.amazonaws.com" "https://airflow.ap-northeast-1.amazonaws.com" "https://airflow.ap-northeast-2.amazonaws.com" "https://airflow.ap-northeast-3.amazonaws.com" "https://airflow.ap-southeast-1.amazonaws.com" "https://airflow.ap-southeast-2.amazonaws.com" "https://airflow.ap-east-1.amazonaws.com" "https://airflow.ap-south-1.amazonaws.com" "https://airflow.sa-east-1.amazonaws.com" "https://airflow.me-south-1.amazonaws.com" "http://airflow.cn-north-1.amazonaws.com.cn" "http://airflow.cn-northwest-1.amazonaws.com.cn" "https://airflow.cn-north-1.amazonaws.com.cn" "https://airflow.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def webserver-access-mode-completer [] { ["PRIVATE_ONLY" "PUBLIC_ONLY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "clitoken create-cli-token" } } | get name | first)
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

# Creates a CLI token for the Airflow CLI. To learn more, see Creating an Apache Airflow CLI token (https://docs.aws.amazon.com/mwaa/latest/userguide/call-mwaa-apis-cli.html).
#
# POST /clitoken/{Name}
# operationId: CreateCliToken
export def "clitoken create-cli-token" [
  name: string
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
]: nothing -> record<CliToken: record, WebServerHostname: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clitoken/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates an Amazon Managed Workflows for Apache Airflow (MWAA) environment.
#
# PUT /environments/{Name}
# operationId: CreateEnvironment
# --LoggingConfiguration shape: {DagProcessingLogs?: any, SchedulerLogs?: any, TaskLogs?: any, WebserverLogs?: any, WorkerLogs?: any}
# --NetworkConfiguration shape: {SecurityGroupIds?: any, SubnetIds?: any}
export def "environments create" [
  name: string
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
  --airflow-configuration-options: record # A list of key-value pairs containing the Apache Airflow configuration options you want to attach to your environment. For more information, see Apache Airflow configuration options (https://docs.aws.amazon.com/mwaa/latest/userguide/configuring-env-variables.html).
  --airflow-version: string # The Apache Airflow version for your environment. If no value is specified, it defaults to the latest version. Valid values: 1.10.12, 2.0.2, 2.2.2, and 2.4.3. For more information, see Apache Airflow versions on Amazon Managed Workflows for Apache Airflow (MWAA) (https://docs.aws.amazon.com/mwaa/latest/userguide/airflow-versions.html).
  dag_s3_path: string # The relative path to the DAGs folder on your Amazon S3 bucket. For example, dags. For more information, see Adding or updating DAGs (https://docs.aws.amazon.com/mwaa/latest/userguide/configuring-dag-folder.html).
  --environment-class: string # The environment class type. Valid values: mw1.small, mw1.medium, mw1.large. For more information, see Amazon MWAA environment class (https://docs.aws.amazon.com/mwaa/latest/userguide/environment-class.html).
  execution_role_arn: string # The Amazon Resource Name (ARN) of the execution role for your environment. An execution role is an Amazon Web Services Identity and Access Management (IAM) role that grants MWAA permission to access Amazon Web Services services and resources used by your environment. For example, arn:aws:iam::123456789:role/my-execution-role. For more information, see Amazon MWAA Execution role (https://docs.aws.amazon.com/mwaa/latest/userguide/mwaa-create-role.html).
  --kms-key: string # The Amazon Web Services Key Management Service (KMS) key to encrypt the data in your environment. You can use an Amazon Web Services owned CMK, or a Customer managed CMK (advanced). For more information, see Create an Amazon MWAA environment (https://docs.aws.amazon.com/mwaa/latest/userguide/create-environment.html).
  --logging-configuration: record # Defines the Apache Airflow log types to send to CloudWatch Logs. — shape: {DagProcessingLogs?: any, SchedulerLogs?: any, TaskLogs?: any, WebserverLogs?: any, WorkerLogs?: any}
  --max-workers: int # The maximum number of workers that you want to run in your environment. MWAA scales the number of Apache Airflow workers up to the number you specify in the MaxWorkers field. For example, 20. When there are no more tasks running, and no more in the queue, MWAA disposes of the extra workers leaving the one worker that is included with your environment, or the number you specify in MinWorkers.
  --min-workers: int # The minimum number of workers that you want to run in your environment. MWAA scales the number of Apache Airflow workers up to the number you specify in the MaxWorkers field. When there are no more tasks running, and no more in the queue, MWAA disposes of the extra workers leaving the worker count you specify in the MinWorkers field. For example, 2.
  network_configuration: record # Describes the VPC networking components used to secure and enable network traffic between the Amazon Web Services resources for your environment. For more information, see About networking on Amazon MWAA (https://docs.aws.amazon.com/mwaa/latest/userguide/networking-about.html). — shape: {SecurityGroupIds?: any, SubnetIds?: any}
  --plugins-s3-object-version: string # The version of the plugins.zip file on your Amazon S3 bucket. You must specify a version each time a plugins.zip file is updated. For more information, see How S3 Versioning works (https://docs.aws.amazon.com/AmazonS3/latest/userguide/versioning-workflows.html).
  --plugins-s3-path: string # The relative path to the plugins.zip file on your Amazon S3 bucket. For example, plugins.zip. If specified, then the plugins.zip version is required. For more information, see Installing custom plugins (https://docs.aws.amazon.com/mwaa/latest/userguide/configuring-dag-import-plugins.html).
  --requirements-s3-object-version: string # The version of the requirements.txt file on your Amazon S3 bucket. You must specify a version each time a requirements.txt file is updated. For more information, see How S3 Versioning works (https://docs.aws.amazon.com/AmazonS3/latest/userguide/versioning-workflows.html).
  --requirements-s3-path: string # The relative path to the requirements.txt file on your Amazon S3 bucket. For example, requirements.txt. If specified, then a version is required. For more information, see Installing Python dependencies (https://docs.aws.amazon.com/mwaa/latest/userguide/working-dags-dependencies.html).
  --schedulers: int # The number of Apache Airflow schedulers to run in your environment. Valid values: v2 - Accepts between 2 to 5. Defaults to 2. v1 - Accepts 1.
  source_bucket_arn: string # The Amazon Resource Name (ARN) of the Amazon S3 bucket where your DAG code and supporting files are stored. For example, arn:aws:s3:::my-airflow-bucket-unique-name. For more information, see Create an Amazon S3 bucket for Amazon MWAA (https://docs.aws.amazon.com/mwaa/latest/userguide/mwaa-s3-bucket.html).
  --startup-script-s3-object-version: string # The version of the startup shell script in your Amazon S3 bucket. You must specify the version ID (https://docs.aws.amazon.com/AmazonS3/latest/userguide/versioning-workflows.html) that Amazon S3 assigns to the file every time you update the script. Version IDs are Unicode, UTF-8 encoded, URL-ready, opaque strings that are no more than 1,024 bytes long. The following is an example: 3sL4kqtJlcpXroDTDmJ+rmSpXd3dIbrHY+MTRCxf3vjVBH40Nr8X8gdRQBpUMLUo For more information, see Using a startup script (https://docs.aws.amazon.com/mwaa/latest/userguide/using-startup-script.html).
  --startup-script-s3-path: string # The relative path to the startup shell script in your Amazon S3 bucket. For example, s3://mwaa-environment/startup.sh. Amazon MWAA runs the script as your environment starts, and before running the Apache Airflow process. You can use this script to install dependencies, modify Apache Airflow configuration options, and set environment variables. For more information, see Using a startup script (https://docs.aws.amazon.com/mwaa/latest/userguide/using-startup-script.html).
  --tags: record # The key-value tag pairs you want to associate to your environment. For example, "Environment": "Staging". For more information, see Tagging Amazon Web Services resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html).
  --webserver-access-mode: string@webserver-access-mode-completer # The Apache Airflow Web server access mode. For more information, see Apache Airflow access modes (https://docs.aws.amazon.com/mwaa/latest/userguide/configuring-networking.html).
  --weekly-maintenance-window-start: string # The day and time of the week in Coordinated Universal Time (UTC) 24-hour standard time to start weekly maintenance updates of your environment in the following format: DAY:HH:MM. For example: TUE:03:30. You can specify a start time in 30 minute increments only.
]: any -> record<Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/environments/{name}"))
  let req_body = {"AirflowConfigurationOptions": $airflow_configuration_options, "AirflowVersion": $airflow_version, "DagS3Path": $dag_s3_path, "EnvironmentClass": $environment_class, "ExecutionRoleArn": $execution_role_arn, "KmsKey": $kms_key, "LoggingConfiguration": $logging_configuration, "MaxWorkers": $max_workers, "MinWorkers": $min_workers, "NetworkConfiguration": $network_configuration, "PluginsS3ObjectVersion": $plugins_s3_object_version, "PluginsS3Path": $plugins_s3_path, "RequirementsS3ObjectVersion": $requirements_s3_object_version, "RequirementsS3Path": $requirements_s3_path, "Schedulers": $schedulers, "SourceBucketArn": $source_bucket_arn, "StartupScriptS3ObjectVersion": $startup_script_s3_object_version, "StartupScriptS3Path": $startup_script_s3_path, "Tags": $tags, "WebserverAccessMode": $webserver_access_mode, "WeeklyMaintenanceWindowStart": $weekly_maintenance_window_start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an Amazon Managed Workflows for Apache Airflow (MWAA) environment.
#
# DELETE /environments/{Name}
# operationId: DeleteEnvironment
export def "environments delete" [
  name: string
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
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/environments/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describes an Amazon Managed Workflows for Apache Airflow (MWAA) environment.
#
# GET /environments/{Name}
# operationId: GetEnvironment
export def "environments get" [
  name: string
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
]: nothing -> record<Environment: record<AirflowConfigurationOptions: record, AirflowVersion: record, Arn: record, CreatedAt: record, DagS3Path: record, EnvironmentClass: record, ExecutionRoleArn: record, KmsKey: record, LastUpdate: record<CreatedAt: record, Error: record, Source: record, Status: record>, LoggingConfiguration: record<DagProcessingLogs: record, SchedulerLogs: record, TaskLogs: record, WebserverLogs: record, WorkerLogs: record>, MaxWorkers: record, MinWorkers: record, Name: record, NetworkConfiguration: record<SecurityGroupIds: record, SubnetIds: record>, PluginsS3ObjectVersion: record, PluginsS3Path: record, RequirementsS3ObjectVersion: record, RequirementsS3Path: record, Schedulers: record, ServiceRoleArn: record, SourceBucketArn: record, StartupScriptS3ObjectVersion: record, StartupScriptS3Path: record, Status: record, Tags: record, WebserverAccessMode: record, WebserverUrl: record, WeeklyMaintenanceWindowStart: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/environments/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an Amazon Managed Workflows for Apache Airflow (MWAA) environment.
#
# PATCH /environments/{Name}
# operationId: UpdateEnvironment
# --LoggingConfiguration shape: {DagProcessingLogs?: any, SchedulerLogs?: any, TaskLogs?: any, WebserverLogs?: any, WorkerLogs?: any}
# --NetworkConfiguration shape: {SecurityGroupIds?: any}
export def "environments update" [
  name: string
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
  --airflow-configuration-options: record # A list of key-value pairs containing the Apache Airflow configuration options you want to attach to your environment. For more information, see Apache Airflow configuration options (https://docs.aws.amazon.com/mwaa/latest/userguide/configuring-env-variables.html).
  --airflow-version: string # The Apache Airflow version for your environment. If no value is specified, defaults to the latest version. Valid values: 1.10.12, 2.0.2, 2.2.2, and 2.4.3.
  --dag-s3-path: string # The relative path to the DAGs folder on your Amazon S3 bucket. For example, dags. For more information, see Adding or updating DAGs (https://docs.aws.amazon.com/mwaa/latest/userguide/configuring-dag-folder.html).
  --environment-class: string # The environment class type. Valid values: mw1.small, mw1.medium, mw1.large. For more information, see Amazon MWAA environment class (https://docs.aws.amazon.com/mwaa/latest/userguide/environment-class.html).
  --execution-role-arn: string # The Amazon Resource Name (ARN) of the execution role in IAM that allows MWAA to access Amazon Web Services resources in your environment. For example, arn:aws:iam::123456789:role/my-execution-role. For more information, see Amazon MWAA Execution role (https://docs.aws.amazon.com/mwaa/latest/userguide/mwaa-create-role.html).
  --logging-configuration: record # Defines the Apache Airflow log types to send to CloudWatch Logs. — shape: {DagProcessingLogs?: any, SchedulerLogs?: any, TaskLogs?: any, WebserverLogs?: any, WorkerLogs?: any}
  --max-workers: int # The maximum number of workers that you want to run in your environment. MWAA scales the number of Apache Airflow workers up to the number you specify in the MaxWorkers field. For example, 20. When there are no more tasks running, and no more in the queue, MWAA disposes of the extra workers leaving the one worker that is included with your environment, or the number you specify in MinWorkers.
  --min-workers: int # The minimum number of workers that you want to run in your environment. MWAA scales the number of Apache Airflow workers up to the number you specify in the MaxWorkers field. When there are no more tasks running, and no more in the queue, MWAA disposes of the extra workers leaving the worker count you specify in the MinWorkers field. For example, 2.
  --network-configuration: record # Defines the VPC networking components used to secure and enable network traffic between the Amazon Web Services resources for your environment. For more information, see About networking on Amazon MWAA (https://docs.aws.amazon.com/mwaa/latest/userguide/networking-about.html). — shape: {SecurityGroupIds?: any}
  --plugins-s3-object-version: string # The version of the plugins.zip file on your Amazon S3 bucket. You must specify a version each time a plugins.zip file is updated. For more information, see How S3 Versioning works (https://docs.aws.amazon.com/AmazonS3/latest/userguide/versioning-workflows.html).
  --plugins-s3-path: string # The relative path to the plugins.zip file on your Amazon S3 bucket. For example, plugins.zip. If specified, then the plugins.zip version is required. For more information, see Installing custom plugins (https://docs.aws.amazon.com/mwaa/latest/userguide/configuring-dag-import-plugins.html).
  --requirements-s3-object-version: string # The version of the requirements.txt file on your Amazon S3 bucket. You must specify a version each time a requirements.txt file is updated. For more information, see How S3 Versioning works (https://docs.aws.amazon.com/AmazonS3/latest/userguide/versioning-workflows.html).
  --requirements-s3-path: string # The relative path to the requirements.txt file on your Amazon S3 bucket. For example, requirements.txt. If specified, then a file version is required. For more information, see Installing Python dependencies (https://docs.aws.amazon.com/mwaa/latest/userguide/working-dags-dependencies.html).
  --schedulers: int # The number of Apache Airflow schedulers to run in your Amazon MWAA environment.
  --source-bucket-arn: string # The Amazon Resource Name (ARN) of the Amazon S3 bucket where your DAG code and supporting files are stored. For example, arn:aws:s3:::my-airflow-bucket-unique-name. For more information, see Create an Amazon S3 bucket for Amazon MWAA (https://docs.aws.amazon.com/mwaa/latest/userguide/mwaa-s3-bucket.html).
  --startup-script-s3-object-version: string # The version of the startup shell script in your Amazon S3 bucket. You must specify the version ID (https://docs.aws.amazon.com/AmazonS3/latest/userguide/versioning-workflows.html) that Amazon S3 assigns to the file every time you update the script. Version IDs are Unicode, UTF-8 encoded, URL-ready, opaque strings that are no more than 1,024 bytes long. The following is an example: 3sL4kqtJlcpXroDTDmJ+rmSpXd3dIbrHY+MTRCxf3vjVBH40Nr8X8gdRQBpUMLUo For more information, see Using a startup script (https://docs.aws.amazon.com/mwaa/latest/userguide/using-startup-script.html).
  --startup-script-s3-path: string # The relative path to the startup shell script in your Amazon S3 bucket. For example, s3://mwaa-environment/startup.sh. Amazon MWAA runs the script as your environment starts, and before running the Apache Airflow process. You can use this script to install dependencies, modify Apache Airflow configuration options, and set environment variables. For more information, see Using a startup script (https://docs.aws.amazon.com/mwaa/latest/userguide/using-startup-script.html).
  --webserver-access-mode: string@webserver-access-mode-completer # The Apache Airflow Web server access mode. For more information, see Apache Airflow access modes (https://docs.aws.amazon.com/mwaa/latest/userguide/configuring-networking.html).
  --weekly-maintenance-window-start: string # The day and time of the week in Coordinated Universal Time (UTC) 24-hour standard time to start weekly maintenance updates of your environment in the following format: DAY:HH:MM. For example: TUE:03:30. You can specify a start time in 30 minute increments only.
]: any -> record<Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/environments/{name}"))
  let req_body = {"AirflowConfigurationOptions": $airflow_configuration_options, "AirflowVersion": $airflow_version, "DagS3Path": $dag_s3_path, "EnvironmentClass": $environment_class, "ExecutionRoleArn": $execution_role_arn, "LoggingConfiguration": $logging_configuration, "MaxWorkers": $max_workers, "MinWorkers": $min_workers, "NetworkConfiguration": $network_configuration, "PluginsS3ObjectVersion": $plugins_s3_object_version, "PluginsS3Path": $plugins_s3_path, "RequirementsS3ObjectVersion": $requirements_s3_object_version, "RequirementsS3Path": $requirements_s3_path, "Schedulers": $schedulers, "SourceBucketArn": $source_bucket_arn, "StartupScriptS3ObjectVersion": $startup_script_s3_object_version, "StartupScriptS3Path": $startup_script_s3_path, "WebserverAccessMode": $webserver_access_mode, "WeeklyMaintenanceWindowStart": $weekly_maintenance_window_start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a web login token for the Airflow Web UI. To learn more, see Creating an Apache Airflow web login token (https://docs.aws.amazon.com/mwaa/latest/userguide/call-mwaa-apis-web.html).
#
# POST /webtoken/{Name}
# operationId: CreateWebLoginToken
export def "webtoken create-web-login-token" [
  name: string
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
]: nothing -> record<WebServerHostname: record, WebToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/webtoken/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists the Amazon Managed Workflows for Apache Airflow (MWAA) environments.
#
# GET /environments
# operationId: ListEnvironments
export def "environments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to retrieve per page. For example, 5 environments per page.
  --next-token: string # Retrieves the next page of the results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Environments: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/environments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: null}
}

# Lists the key-value tag pairs associated to the Amazon Managed Workflows for Apache Airflow (MWAA) environment. For example, "Environment": "Staging".
#
# GET /tags/{ResourceArn}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'ResourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Associates key-value tag pairs to your Amazon Managed Workflows for Apache Airflow (MWAA) environment.
#
# POST /tags/{ResourceArn}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: record # The key-value tag pairs you want to associate to your environment. For example, "Environment": "Staging". For more information, see Tagging Amazon Web Services resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'ResourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Internal only. Publishes environment health metrics to Amazon CloudWatch.
#
# POST /metrics/environments/{EnvironmentName}
# operationId: PublishMetrics
# --MetricData item shape: {Dimensions?: any, MetricName: any, StatisticValues?: any, Timestamp: any, Unit?: any, Value?: any}
export def "metrics-environments publish" [
  environment_name: string
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
  metric_data: list # Internal only. Publishes metrics to Amazon CloudWatch. To learn more about the metrics published to Amazon CloudWatch, see Amazon MWAA performance metrics in Amazon CloudWatch (https://docs.aws.amazon.com/mwaa/latest/userguide/cw-metrics.html). — item shape: {Dimensions?: any, MetricName: any, StatisticValues?: any, Timestamp: any, Unit?: any, Value?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($environment_name | is-empty) { error make --unspanned { msg: "path parameter 'EnvironmentName' must be non-empty" } }
  let full_url = (build-url $base ({environment_name: (encode-path-segment $environment_name)} | format pattern "/metrics/environments/{environment_name}"))
  let req_body = {"MetricData": $metric_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes key-value tag pairs associated to your Amazon Managed Workflows for Apache Airflow (MWAA) environment. For example, "Environment": "Staging".
#
# DELETE /tags/{ResourceArn}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # The key-value tag pair you want to remove. For example, "Environment": "Staging".
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
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'ResourceArn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}
