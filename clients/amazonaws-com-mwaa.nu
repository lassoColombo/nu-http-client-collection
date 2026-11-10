# Auto-generated client for AmazonMWAA v2020-07-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/mwaa/2020-07-01/openapi.json
# Auth: --token flag or $env.AMAZONMWAA_TOKEN

const BASE_URL = "http://airflow.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZONMWAA_TOKEN | default "" }
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
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
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

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://airflow.us-east-1.amazonaws.com" "http://airflow.us-east-2.amazonaws.com" "http://airflow.us-west-1.amazonaws.com" "http://airflow.us-west-2.amazonaws.com" "http://airflow.us-gov-west-1.amazonaws.com" "http://airflow.us-gov-east-1.amazonaws.com" "http://airflow.ca-central-1.amazonaws.com" "http://airflow.eu-north-1.amazonaws.com" "http://airflow.eu-west-1.amazonaws.com" "http://airflow.eu-west-2.amazonaws.com" "http://airflow.eu-west-3.amazonaws.com" "http://airflow.eu-central-1.amazonaws.com" "http://airflow.eu-south-1.amazonaws.com" "http://airflow.af-south-1.amazonaws.com" "http://airflow.ap-northeast-1.amazonaws.com" "http://airflow.ap-northeast-2.amazonaws.com" "http://airflow.ap-northeast-3.amazonaws.com" "http://airflow.ap-southeast-1.amazonaws.com" "http://airflow.ap-southeast-2.amazonaws.com" "http://airflow.ap-east-1.amazonaws.com" "http://airflow.ap-south-1.amazonaws.com" "http://airflow.sa-east-1.amazonaws.com" "http://airflow.me-south-1.amazonaws.com" "https://airflow.us-east-1.amazonaws.com" "https://airflow.us-east-2.amazonaws.com" "https://airflow.us-west-1.amazonaws.com" "https://airflow.us-west-2.amazonaws.com" "https://airflow.us-gov-west-1.amazonaws.com" "https://airflow.us-gov-east-1.amazonaws.com" "https://airflow.ca-central-1.amazonaws.com" "https://airflow.eu-north-1.amazonaws.com" "https://airflow.eu-west-1.amazonaws.com" "https://airflow.eu-west-2.amazonaws.com" "https://airflow.eu-west-3.amazonaws.com" "https://airflow.eu-central-1.amazonaws.com" "https://airflow.eu-south-1.amazonaws.com" "https://airflow.af-south-1.amazonaws.com" "https://airflow.ap-northeast-1.amazonaws.com" "https://airflow.ap-northeast-2.amazonaws.com" "https://airflow.ap-northeast-3.amazonaws.com" "https://airflow.ap-southeast-1.amazonaws.com" "https://airflow.ap-southeast-2.amazonaws.com" "https://airflow.ap-east-1.amazonaws.com" "https://airflow.ap-south-1.amazonaws.com" "https://airflow.sa-east-1.amazonaws.com" "https://airflow.me-south-1.amazonaws.com" "http://airflow.cn-north-1.amazonaws.com.cn" "http://airflow.cn-northwest-1.amazonaws.com.cn" "https://airflow.cn-north-1.amazonaws.com.cn" "https://airflow.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def webserver-access-mode-completer [] { ["PRIVATE_ONLY" "PUBLIC_ONLY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-cli-token" "create-environment" "delete-environment" "get-environment" "update-environment" "create-web-login-token" "list-environments" "list-tags-for-resource" "tag-resource" "publish-metrics" "untag-resource" "commands"] | sort) } | get name | first)
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

# Creates a CLI token for the Airflow CLI. To learn more, see Creating an Apache Airflow CLI token (https://docs.aws.amazon.com/mwaa/latest/userguide/call-mwaa-apis-cli.html).
#
# POST /clitoken/{Name}
# operationId: CreateCliToken
export def "create-cli-token" [
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
]: nothing -> oneof<record<CliToken: string, WebServerHostname: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/clitoken/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Creates an Amazon Managed Workflows for Apache Airflow (MWAA) environment.
#
# PUT /environments/{Name}
# operationId: CreateEnvironment
export def "create-environment" [
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
  --logging-configuration: record # Defines the Apache Airflow log types to send to CloudWatch Logs. — shape: {DagProcessingLogs?: record, SchedulerLogs?: record, TaskLogs?: record, WebserverLogs?: record, WorkerLogs?: record}
  --max-workers: int # The maximum number of workers that you want to run in your environment. MWAA scales the number of Apache Airflow workers up to the number you specify in the MaxWorkers field. For example, 20. When there are no more tasks running, and no more in the queue, MWAA disposes of the extra workers leaving the one worker that is included with your environment, or the number you specify in MinWorkers.
  --min-workers: int # The minimum number of workers that you want to run in your environment. MWAA scales the number of Apache Airflow workers up to the number you specify in the MaxWorkers field. When there are no more tasks running, and no more in the queue, MWAA disposes of the extra workers leaving the worker count you specify in the MinWorkers field. For example, 2.
  network_configuration: record # Describes the VPC networking components used to secure and enable network traffic between the Amazon Web Services resources for your environment. For more information, see About networking on Amazon MWAA (https://docs.aws.amazon.com/mwaa/latest/userguide/networking-about.html). — shape: {SecurityGroupIds?: list<string>, SubnetIds?: list<string>}
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
]: any -> oneof<record<Arn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/environments/{name}") $auth.query)
  let req_body = {"AirflowConfigurationOptions": $airflow_configuration_options, "AirflowVersion": $airflow_version, "DagS3Path": $dag_s3_path, "EnvironmentClass": $environment_class, "ExecutionRoleArn": $execution_role_arn, "KmsKey": $kms_key, "LoggingConfiguration": $logging_configuration, "MaxWorkers": $max_workers, "MinWorkers": $min_workers, "NetworkConfiguration": $network_configuration, "PluginsS3ObjectVersion": $plugins_s3_object_version, "PluginsS3Path": $plugins_s3_path, "RequirementsS3ObjectVersion": $requirements_s3_object_version, "RequirementsS3Path": $requirements_s3_path, "Schedulers": $schedulers, "SourceBucketArn": $source_bucket_arn, "StartupScriptS3ObjectVersion": $startup_script_s3_object_version, "StartupScriptS3Path": $startup_script_s3_path, "Tags": $tags, "WebserverAccessMode": $webserver_access_mode, "WeeklyMaintenanceWindowStart": $weekly_maintenance_window_start} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Deletes an Amazon Managed Workflows for Apache Airflow (MWAA) environment.
#
# DELETE /environments/{Name}
# operationId: DeleteEnvironment
export def "delete-environment" [
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
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/environments/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Describes an Amazon Managed Workflows for Apache Airflow (MWAA) environment.
#
# GET /environments/{Name}
# operationId: GetEnvironment
export def "get-environment" [
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
]: nothing -> oneof<record<Environment: record<AirflowConfigurationOptions: record, AirflowVersion: string, Arn: string, CreatedAt: string, DagS3Path: string, EnvironmentClass: string, ExecutionRoleArn: string, KmsKey: string, LastUpdate: record<CreatedAt: string, Error: record, Source: string, Status: string>, LoggingConfiguration: record<DagProcessingLogs: record, SchedulerLogs: record, TaskLogs: record, WebserverLogs: record, WorkerLogs: record>, MaxWorkers: int, MinWorkers: int, Name: string, NetworkConfiguration: record<SecurityGroupIds: list, SubnetIds: list>, PluginsS3ObjectVersion: string, PluginsS3Path: string, RequirementsS3ObjectVersion: string, RequirementsS3Path: string, Schedulers: int, ServiceRoleArn: string, SourceBucketArn: string, StartupScriptS3ObjectVersion: string, StartupScriptS3Path: string, Status: string, Tags: record, WebserverAccessMode: string, WebserverUrl: string, WeeklyMaintenanceWindowStart: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/environments/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Updates an Amazon Managed Workflows for Apache Airflow (MWAA) environment.
#
# PATCH /environments/{Name}
# operationId: UpdateEnvironment
export def "update-environment" [
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
  --logging-configuration: record # Defines the Apache Airflow log types to send to CloudWatch Logs. — shape: {DagProcessingLogs?: record, SchedulerLogs?: record, TaskLogs?: record, WebserverLogs?: record, WorkerLogs?: record}
  --max-workers: int # The maximum number of workers that you want to run in your environment. MWAA scales the number of Apache Airflow workers up to the number you specify in the MaxWorkers field. For example, 20. When there are no more tasks running, and no more in the queue, MWAA disposes of the extra workers leaving the one worker that is included with your environment, or the number you specify in MinWorkers.
  --min-workers: int # The minimum number of workers that you want to run in your environment. MWAA scales the number of Apache Airflow workers up to the number you specify in the MaxWorkers field. When there are no more tasks running, and no more in the queue, MWAA disposes of the extra workers leaving the worker count you specify in the MinWorkers field. For example, 2.
  --network-configuration: record # Defines the VPC networking components used to secure and enable network traffic between the Amazon Web Services resources for your environment. For more information, see About networking on Amazon MWAA (https://docs.aws.amazon.com/mwaa/latest/userguide/networking-about.html). — shape: {SecurityGroupIds?: list<string>}
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
]: any -> oneof<record<Arn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/environments/{name}") $auth.query)
  let req_body = {"AirflowConfigurationOptions": $airflow_configuration_options, "AirflowVersion": $airflow_version, "DagS3Path": $dag_s3_path, "EnvironmentClass": $environment_class, "ExecutionRoleArn": $execution_role_arn, "LoggingConfiguration": $logging_configuration, "MaxWorkers": $max_workers, "MinWorkers": $min_workers, "NetworkConfiguration": $network_configuration, "PluginsS3ObjectVersion": $plugins_s3_object_version, "PluginsS3Path": $plugins_s3_path, "RequirementsS3ObjectVersion": $requirements_s3_object_version, "RequirementsS3Path": $requirements_s3_path, "Schedulers": $schedulers, "SourceBucketArn": $source_bucket_arn, "StartupScriptS3ObjectVersion": $startup_script_s3_object_version, "StartupScriptS3Path": $startup_script_s3_path, "WebserverAccessMode": $webserver_access_mode, "WeeklyMaintenanceWindowStart": $weekly_maintenance_window_start} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a web login token for the Airflow Web UI. To learn more, see Creating an Apache Airflow web login token (https://docs.aws.amazon.com/mwaa/latest/userguide/call-mwaa-apis-web.html).
#
# POST /webtoken/{Name}
# operationId: CreateWebLoginToken
export def "create-web-login-token" [
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
]: nothing -> oneof<record<WebServerHostname: string, WebToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/webtoken/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Lists the Amazon Managed Workflows for Apache Airflow (MWAA) environments.
#
# GET /environments
# operationId: ListEnvironments
export def "list-environments" [
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
]: nothing -> oneof<record<Environments: list<string>, NextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/environments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Lists the key-value tag pairs associated to the Amazon Managed Workflows for Apache Airflow (MWAA) environment. For example, "Environment": "Staging".
#
# GET /tags/{ResourceArn}
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
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
]: nothing -> oneof<record<Tags: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'ResourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Associates key-value tag pairs to your Amazon Managed Workflows for Apache Airflow (MWAA) environment.
#
# POST /tags/{ResourceArn}
# operationId: TagResource
export def "tag-resource" [
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
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'ResourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $auth.query)
  let req_body = {"Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Internal only. Publishes environment health metrics to Amazon CloudWatch.
#
# POST /metrics/environments/{EnvironmentName}
# operationId: PublishMetrics
export def "publish-metrics" [
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
  metric_data: list # Internal only. Publishes metrics to Amazon CloudWatch. To learn more about the metrics published to Amazon CloudWatch, see Amazon MWAA performance metrics in Amazon CloudWatch (https://docs.aws.amazon.com/mwaa/latest/userguide/cw-metrics.html). — item shape: {Dimensions?: list, MetricName: string, StatisticValues?: record, Timestamp: string, Unit?: "Seconds"|"Microseconds"|"Milliseconds"|"Bytes"|"Kilobytes"|"Megabytes"|"Gigabytes"|"Terabytes"|"Bits"|"Kilobits"|"Megabits"|"Gigabits"|"Terabits"|"Percent"|"Count"|"Bytes/Second"|"Kilobytes/Second"|"Megabytes/Second"|"Gigabytes/Second"|"Terabytes/Second"|"Bits/Second"|"Kilobits/Second"|"Megabits/Second"|"Gigabits/Second"|"Terabits/Second"|"Count/Second"|"None", Value?: float}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($environment_name | is-empty) { error make --unspanned { msg: "path parameter 'EnvironmentName' must be non-empty" } }
  let full_url = (build-url $base ({environment_name: (encode-path-segment $environment_name)} | format pattern "/metrics/environments/{environment_name}") $auth.query)
  let req_body = {"MetricData": $metric_data} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Removes key-value tag pairs associated to your Amazon Managed Workflows for Apache Airflow (MWAA) environment. For example, "Environment": "Staging".
#
# DELETE /tags/{ResourceArn}
# operationId: UntagResource
export def "untag-resource" [
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
  --tag-keys: list # The key-value tag pair you want to remove. For example, "Environment": "Staging". (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'ResourceArn' must be non-empty" } }
  if ($tag_keys == null) { error make --unspanned { msg: "required query parameter 'tagKeys' missing: pass --tag-keys" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
