# Auto-generated client for AWS CodeDeploy v2014-10-06
# Source: https://api.apis.guru/v2/specs/amazonaws.com/codedeploy/2014-10-06/openapi.json
# Auth: --token flag or $env.AWS_CODEDEPLOY_TOKEN

const BASE_URL = "http://codedeploy.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_CODEDEPLOY_TOKEN | default "" }
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

def base-url-completer [] { ["http://codedeploy.us-east-1.amazonaws.com" "http://codedeploy.us-east-2.amazonaws.com" "http://codedeploy.us-west-1.amazonaws.com" "http://codedeploy.us-west-2.amazonaws.com" "http://codedeploy.us-gov-west-1.amazonaws.com" "http://codedeploy.us-gov-east-1.amazonaws.com" "http://codedeploy.ca-central-1.amazonaws.com" "http://codedeploy.eu-north-1.amazonaws.com" "http://codedeploy.eu-west-1.amazonaws.com" "http://codedeploy.eu-west-2.amazonaws.com" "http://codedeploy.eu-west-3.amazonaws.com" "http://codedeploy.eu-central-1.amazonaws.com" "http://codedeploy.eu-south-1.amazonaws.com" "http://codedeploy.af-south-1.amazonaws.com" "http://codedeploy.ap-northeast-1.amazonaws.com" "http://codedeploy.ap-northeast-2.amazonaws.com" "http://codedeploy.ap-northeast-3.amazonaws.com" "http://codedeploy.ap-southeast-1.amazonaws.com" "http://codedeploy.ap-southeast-2.amazonaws.com" "http://codedeploy.ap-east-1.amazonaws.com" "http://codedeploy.ap-south-1.amazonaws.com" "http://codedeploy.sa-east-1.amazonaws.com" "http://codedeploy.me-south-1.amazonaws.com" "https://codedeploy.us-east-1.amazonaws.com" "https://codedeploy.us-east-2.amazonaws.com" "https://codedeploy.us-west-1.amazonaws.com" "https://codedeploy.us-west-2.amazonaws.com" "https://codedeploy.us-gov-west-1.amazonaws.com" "https://codedeploy.us-gov-east-1.amazonaws.com" "https://codedeploy.ca-central-1.amazonaws.com" "https://codedeploy.eu-north-1.amazonaws.com" "https://codedeploy.eu-west-1.amazonaws.com" "https://codedeploy.eu-west-2.amazonaws.com" "https://codedeploy.eu-west-3.amazonaws.com" "https://codedeploy.eu-central-1.amazonaws.com" "https://codedeploy.eu-south-1.amazonaws.com" "https://codedeploy.af-south-1.amazonaws.com" "https://codedeploy.ap-northeast-1.amazonaws.com" "https://codedeploy.ap-northeast-2.amazonaws.com" "https://codedeploy.ap-northeast-3.amazonaws.com" "https://codedeploy.ap-southeast-1.amazonaws.com" "https://codedeploy.ap-southeast-2.amazonaws.com" "https://codedeploy.ap-east-1.amazonaws.com" "https://codedeploy.ap-south-1.amazonaws.com" "https://codedeploy.sa-east-1.amazonaws.com" "https://codedeploy.me-south-1.amazonaws.com" "http://codedeploy.cn-north-1.amazonaws.com.cn" "http://codedeploy.cn-northwest-1.amazonaws.com.cn" "https://codedeploy.cn-north-1.amazonaws.com.cn" "https://codedeploy.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["CodeDeploy_20141006.AddTagsToOnPremisesInstances"] }
def x-amz-target-completer-1 [] { ["CodeDeploy_20141006.BatchGetApplicationRevisions"] }
def x-amz-target-completer-2 [] { ["CodeDeploy_20141006.BatchGetApplications"] }
def x-amz-target-completer-3 [] { ["CodeDeploy_20141006.BatchGetDeploymentGroups"] }
def x-amz-target-completer-4 [] { ["CodeDeploy_20141006.BatchGetDeploymentInstances"] }
def x-amz-target-completer-5 [] { ["CodeDeploy_20141006.BatchGetDeploymentTargets"] }
def x-amz-target-completer-6 [] { ["CodeDeploy_20141006.BatchGetDeployments"] }
def x-amz-target-completer-7 [] { ["CodeDeploy_20141006.BatchGetOnPremisesInstances"] }
def deployment-wait-type-completer [] { ["READY_WAIT" "TERMINATION_WAIT"] }
def x-amz-target-completer-8 [] { ["CodeDeploy_20141006.ContinueDeployment"] }
def compute-platform-completer [] { ["ECS" "Lambda" "Server"] }
def x-amz-target-completer-9 [] { ["CodeDeploy_20141006.CreateApplication"] }
def file-exists-behavior-completer [] { ["DISALLOW" "OVERWRITE" "RETAIN"] }
def x-amz-target-completer-10 [] { ["CodeDeploy_20141006.CreateDeployment"] }
def x-amz-target-completer-11 [] { ["CodeDeploy_20141006.CreateDeploymentConfig"] }
def outdated-instances-strategy-completer [] { ["IGNORE" "UPDATE"] }
def x-amz-target-completer-12 [] { ["CodeDeploy_20141006.CreateDeploymentGroup"] }
def x-amz-target-completer-13 [] { ["CodeDeploy_20141006.DeleteApplication"] }
def x-amz-target-completer-14 [] { ["CodeDeploy_20141006.DeleteDeploymentConfig"] }
def x-amz-target-completer-15 [] { ["CodeDeploy_20141006.DeleteDeploymentGroup"] }
def x-amz-target-completer-16 [] { ["CodeDeploy_20141006.DeleteGitHubAccountToken"] }
def x-amz-target-completer-17 [] { ["CodeDeploy_20141006.DeleteResourcesByExternalId"] }
def x-amz-target-completer-18 [] { ["CodeDeploy_20141006.DeregisterOnPremisesInstance"] }
def x-amz-target-completer-19 [] { ["CodeDeploy_20141006.GetApplication"] }
def x-amz-target-completer-20 [] { ["CodeDeploy_20141006.GetApplicationRevision"] }
def x-amz-target-completer-21 [] { ["CodeDeploy_20141006.GetDeployment"] }
def x-amz-target-completer-22 [] { ["CodeDeploy_20141006.GetDeploymentConfig"] }
def x-amz-target-completer-23 [] { ["CodeDeploy_20141006.GetDeploymentGroup"] }
def x-amz-target-completer-24 [] { ["CodeDeploy_20141006.GetDeploymentInstance"] }
def x-amz-target-completer-25 [] { ["CodeDeploy_20141006.GetDeploymentTarget"] }
def x-amz-target-completer-26 [] { ["CodeDeploy_20141006.GetOnPremisesInstance"] }
def sort-by-completer [] { ["firstUsedTime" "lastUsedTime" "registerTime"] }
def sort-order-completer [] { ["ascending" "descending"] }
def deployed-completer [] { ["exclude" "ignore" "include"] }
def x-amz-target-completer-27 [] { ["CodeDeploy_20141006.ListApplicationRevisions"] }
def x-amz-target-completer-28 [] { ["CodeDeploy_20141006.ListApplications"] }
def x-amz-target-completer-29 [] { ["CodeDeploy_20141006.ListDeploymentConfigs"] }
def x-amz-target-completer-30 [] { ["CodeDeploy_20141006.ListDeploymentGroups"] }
def x-amz-target-completer-31 [] { ["CodeDeploy_20141006.ListDeploymentInstances"] }
def x-amz-target-completer-32 [] { ["CodeDeploy_20141006.ListDeploymentTargets"] }
def x-amz-target-completer-33 [] { ["CodeDeploy_20141006.ListDeployments"] }
def x-amz-target-completer-34 [] { ["CodeDeploy_20141006.ListGitHubAccountTokenNames"] }
def registration-status-completer [] { ["Deregistered" "Registered"] }
def x-amz-target-completer-35 [] { ["CodeDeploy_20141006.ListOnPremisesInstances"] }
def x-amz-target-completer-36 [] { ["CodeDeploy_20141006.ListTagsForResource"] }
def status-completer [] { ["Failed" "InProgress" "Pending" "Skipped" "Succeeded" "Unknown"] }
def x-amz-target-completer-37 [] { ["CodeDeploy_20141006.PutLifecycleEventHookExecutionStatus"] }
def x-amz-target-completer-38 [] { ["CodeDeploy_20141006.RegisterApplicationRevision"] }
def x-amz-target-completer-39 [] { ["CodeDeploy_20141006.RegisterOnPremisesInstance"] }
def x-amz-target-completer-40 [] { ["CodeDeploy_20141006.RemoveTagsFromOnPremisesInstances"] }
def x-amz-target-completer-41 [] { ["CodeDeploy_20141006.SkipWaitTimeForInstanceTermination"] }
def x-amz-target-completer-42 [] { ["CodeDeploy_20141006.StopDeployment"] }
def x-amz-target-completer-43 [] { ["CodeDeploy_20141006.TagResource"] }
def x-amz-target-completer-44 [] { ["CodeDeploy_20141006.UntagResource"] }
def x-amz-target-completer-45 [] { ["CodeDeploy_20141006.UpdateApplication"] }
def x-amz-target-completer-46 [] { ["CodeDeploy_20141006.UpdateDeploymentGroup"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "add-tags-to-on-premises-instances" } } | get name | first)
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

# Adds tags to on-premises instances.
#
# POST /
# operationId: AddTagsToOnPremisesInstances
# --tags item shape: {Key?: string, Value?: string}
export def "add-tags-to-on-premises-instances" [
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
  tags: list # The tag key-value pairs to add to the on-premises instances. Keys and values are both required. Keys cannot be null or empty strings. Value-only tags are not allowed. — item shape: {Key?: string, Value?: string}
  instance_names: list<string> # The names of the on-premises instances to which to add tags.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.AddTagsToOnPremisesInstances")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"tags": $tags, "instanceNames": $instance_names} | compact
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

# Gets information about one or more application revisions. The maximum number of application revisions that can be returned is 25.
#
# POST /
# operationId: BatchGetApplicationRevisions
# --revisions item shape: {revisionType?: "S3"|"GitHub"|"String"|"AppSpecContent", s3Location?: record, gitHubLocation?: record, string?: record, appSpecContent?: record}
export def "batch-get-application-revisions" [
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
  application_name: string # The name of an CodeDeploy application about which to get revision information.
  revisions: list # An array of RevisionLocation objects that specify information to get about the application revisions, including type and location. The maximum number of RevisionLocation objects you can specify is 25. — item shape: {revisionType?: "S3"|"GitHub"|"String"|"AppSpecContent", s3Location?: record, gitHubLocation?: record, string?: record, appSpecContent?: record}
]: any -> record<applicationName: string, errorMessage: string, revisions: table<revisionLocation: record, genericRevisionInfo: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.BatchGetApplicationRevisions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationName": $application_name, "revisions": $revisions} | compact
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

# Gets information about one or more applications. The maximum number of applications that can be returned is 100.
#
# POST /
# operationId: BatchGetApplications
export def "batch-get-applications" [
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
  application_names: list<string> # A list of application names separated by spaces. The maximum number of application names you can specify is 100.
]: any -> record<applicationsInfo: table<applicationId: string, applicationName: string, createTime: string, linkedToGitHub: bool, gitHubAccountName: string, computePlatform: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.BatchGetApplications")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationNames": $application_names} | compact
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

# Gets information about one or more deployment groups.
#
# POST /
# operationId: BatchGetDeploymentGroups
export def "batch-get-deployment-groups" [
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
  application_name: string # The name of an CodeDeploy application associated with the applicable IAM or Amazon Web Services account.
  deployment_group_names: list<string> # The names of the deployment groups.
]: any -> record<deploymentGroupsInfo: table<applicationName: string, deploymentGroupId: string, deploymentGroupName: string, deploymentConfigName: string, ec2TagFilters: list, onPremisesInstanceTagFilters: list, autoScalingGroups: list, serviceRoleArn: string, targetRevision: record, triggerConfigurations: list, alarmConfiguration: record, autoRollbackConfiguration: record, deploymentStyle: record, outdatedInstancesStrategy: string, blueGreenDeploymentConfiguration: record, loadBalancerInfo: record, lastSuccessfulDeployment: record, lastAttemptedDeployment: record, ec2TagSet: record, onPremisesTagSet: record, computePlatform: string, ecsServices: list>, errorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.BatchGetDeploymentGroups")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationName": $application_name, "deploymentGroupNames": $deployment_group_names} | compact
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

# This method works, but is deprecated. Use BatchGetDeploymentTargets instead. Returns an array of one or more instances associated with a deployment. This method works with EC2/On-premises and Lambda compute platforms. The newer BatchGetDeploymentTargets works with all compute platforms. The maximum number of instances that can be returned is 25.
#
# POST /
# DEPRECATED
# operationId: BatchGetDeploymentInstances
@deprecated
export def "batch-get-deployment-instances" [
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
  deployment_id: string # The unique ID of a deployment.
  instance_ids: list<string> # The unique IDs of instances used in the deployment. The maximum number of instance IDs you can specify is 25.
]: any -> record<instancesSummary: table<deploymentId: string, instanceId: string, status: string, lastUpdatedAt: string, lifecycleEvents: list, instanceType: string>, errorMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.BatchGetDeploymentInstances")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentId": $deployment_id, "instanceIds": $instance_ids} | compact
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

# Returns an array of one or more targets associated with a deployment. This method works with all compute types and should be used instead of the deprecated BatchGetDeploymentInstances. The maximum number of targets that can be returned is 25. The type of targets returned depends on the deployment's compute platform or deployment method: EC2/On-premises: Information about Amazon EC2 instance targets. Lambda: Information about Lambda functions targets. Amazon ECS: Information about Amazon ECS service targets. CloudFormation: Information about targets of blue/green deployments initiated by a CloudFormation stack update.
#
# POST /
# operationId: BatchGetDeploymentTargets
export def "batch-get-deployment-targets" [
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
  --deployment-id: string # The unique ID of a deployment.
  --target-ids: list<string> # The unique IDs of the deployment targets. The compute platform of the deployment determines the type of the targets and their formats. The maximum number of deployment target IDs you can specify is 25. For deployments that use the EC2/On-premises compute platform, the target IDs are Amazon EC2 or on-premises instances IDs, and their target type is instanceTarget. For deployments that use the Lambda compute platform, the target IDs are the names of Lambda functions, and their target type is instanceTarget. For deployments that use the Amazon ECS compute platform, the target IDs are pairs of Amazon ECS clusters and services specified using the format <clustername>:<servicename>. Their target type is ecsTarget. For deployments that are deployed with CloudFormation, the target IDs are CloudFormation stack IDs. Their target type is cloudFormationTarget.
]: any -> record<deploymentTargets: table<deploymentTargetType: string, instanceTarget: record, lambdaTarget: record, ecsTarget: record, cloudFormationTarget: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.BatchGetDeploymentTargets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentId": $deployment_id, "targetIds": $target_ids} | compact
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

# Gets information about one or more deployments. The maximum number of deployments that can be returned is 25.
#
# POST /
# operationId: BatchGetDeployments
export def "batch-get-deployments" [
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
  deployment_ids: list<string> # A list of deployment IDs, separated by spaces. The maximum number of deployment IDs you can specify is 25.
]: any -> record<deploymentsInfo: table<applicationName: string, deploymentGroupName: string, deploymentConfigName: string, deploymentId: string, previousRevision: record, revision: record, status: string, errorInformation: record, createTime: string, startTime: string, completeTime: string, deploymentOverview: record, description: string, creator: string, ignoreApplicationStopFailures: bool, autoRollbackConfiguration: record, updateOutdatedInstancesOnly: bool, rollbackInfo: record, deploymentStyle: record, targetInstances: record, instanceTerminationWaitTimeStarted: bool, blueGreenDeploymentConfiguration: record, loadBalancerInfo: record, additionalDeploymentStatusInfo: string, fileExistsBehavior: string, deploymentStatusMessages: list, computePlatform: string, externalId: string, relatedDeployments: record, overrideAlarmConfiguration: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.BatchGetDeployments")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentIds": $deployment_ids} | compact
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

# Gets information about one or more on-premises instances. The maximum number of on-premises instances that can be returned is 25.
#
# POST /
# operationId: BatchGetOnPremisesInstances
export def "batch-get-on-premises-instances" [
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
  instance_names: list<string> # The names of the on-premises instances about which to get information. The maximum number of instance names you can specify is 25.
]: any -> record<instanceInfos: table<instanceName: string, iamSessionArn: string, iamUserArn: string, instanceArn: string, registerTime: string, deregisterTime: string, tags: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.BatchGetOnPremisesInstances")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"instanceNames": $instance_names} | compact
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

# For a blue/green deployment, starts the process of rerouting traffic from instances in the original environment to instances in the replacement environment without waiting for a specified wait time to elapse. (Traffic rerouting, which is achieved by registering instances in the replacement environment with the load balancer, can start as soon as all instances have a status of Ready.)
#
# POST /
# operationId: ContinueDeployment
export def "continue-deployment" [
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
  --deployment-id: string # The unique ID of a blue/green deployment for which you want to start rerouting traffic to the replacement environment.
  --deployment-wait-type: string@deployment-wait-type-completer # The status of the deployment's waiting period. READY_WAIT indicates that the deployment is ready to start shifting traffic. TERMINATION_WAIT indicates that the traffic is shifted, but the original target is not terminated.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.ContinueDeployment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentId": $deployment_id, "deploymentWaitType": $deployment_wait_type} | compact
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

# Creates an application.
#
# POST /
# operationId: CreateApplication
# --tags item shape: {Key?: string, Value?: string}
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  application_name: string # The name of the application. This name must be unique with the applicable IAM or Amazon Web Services account.
  --compute-platform: string@compute-platform-completer # The destination platform type for the deployment (Lambda, Server, or ECS).
  --tags: list # The metadata that you apply to CodeDeploy applications to help you organize and categorize them. Each tag consists of a key and an optional value, both of which you define. — item shape: {Key?: string, Value?: string}
]: any -> record<applicationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.CreateApplication")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationName": $application_name, "computePlatform": $compute_platform, "tags": $tags} | compact
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

# Deploys an application revision through the specified deployment group.
#
# POST /
# operationId: CreateDeployment
# --revision shape: {revisionType?: "S3"|"GitHub"|"String"|"AppSpecContent", s3Location?: record, gitHubLocation?: record, string?: record, appSpecContent?: record}
# --targetInstances shape: {tagFilters?: list, autoScalingGroups?: list<string>, ec2TagSet?: record}
# --autoRollbackConfiguration shape: {enabled?: bool, events?: list<string>}
# --overrideAlarmConfiguration shape: {enabled?: bool, ignorePollAlarmFailure?: bool, alarms?: list}
export def "create-deployment" [
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
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  --deployment-group-name: string # The name of the deployment group.
  --revision: record # Information about the location of an application revision. — shape: {revisionType?: "S3"|"GitHub"|"String"|"AppSpecContent", s3Location?: record, gitHubLocation?: record, string?: record, appSpecContent?: record}
  --deployment-config-name: string # The name of a deployment configuration associated with the IAM user or Amazon Web Services account. If not specified, the value configured in the deployment group is used as the default. If the deployment group does not have a deployment configuration associated with it, CodeDeployDefault.OneAtATime is used by default.
  --description: string # A comment about the deployment.
  --ignore-application-stop-failures: oneof<nothing, bool> # If true, then if an ApplicationStop, BeforeBlockTraffic, or AfterBlockTraffic deployment lifecycle event to an instance fails, then the deployment continues to the next deployment lifecycle event. For example, if ApplicationStop fails, the deployment continues with DownloadBundle. If BeforeBlockTraffic fails, the deployment continues with BlockTraffic. If AfterBlockTraffic fails, the deployment continues with ApplicationStop. If false or not specified, then if a lifecycle event fails during a deployment to an instance, that deployment fails. If deployment to that instance is part of an overall deployment and the number of healthy hosts is not less than the minimum number of healthy hosts, then a deployment to the next instance is attempted. During a deployment, the CodeDeploy agent runs the scripts specified for ApplicationStop, BeforeBlockTraffic, and AfterBlockTraffic in the AppSpec file from the previous successful deployment. (All other scripts are run from the AppSpec file in the current deployment.) If one of these scripts contains an error and does not run successfully, the deployment can fail. If the cause of the failure is a script from the last successful deployment that will never run successfully, create a new deployment and use ignoreApplicationStopFailures to specify that the ApplicationStop, BeforeBlockTraffic, and AfterBlockTraffic failures should be ignored.
  --target-instances: record # Information about the instances to be used in the replacement environment in a blue/green deployment. — shape: {tagFilters?: list, autoScalingGroups?: list<string>, ec2TagSet?: record}
  --auto-rollback-configuration: record # Information about a configuration for automatically rolling back to a previous version of an application revision when a deployment is not completed successfully. — shape: {enabled?: bool, events?: list<string>}
  --update-outdated-instances-only: oneof<nothing, bool> # Indicates whether to deploy to all instances or only to instances that are not running the latest application revision.
  --file-exists-behavior: string@file-exists-behavior-completer # Information about how CodeDeploy handles files that already exist in a deployment target location but weren't part of the previous successful deployment. The fileExistsBehavior parameter takes any of the following values: DISALLOW: The deployment fails. This is also the default behavior if no option is specified. OVERWRITE: The version of the file from the application revision currently being deployed replaces the version already on the instance. RETAIN: The version of the file already on the instance is kept and used as part of the new deployment.
  --override-alarm-configuration: record # Information about alarms associated with a deployment or deployment group. — shape: {enabled?: bool, ignorePollAlarmFailure?: bool, alarms?: list}
]: any -> record<deploymentId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.CreateDeployment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationName": $application_name, "deploymentGroupName": $deployment_group_name, "revision": $revision, "deploymentConfigName": $deployment_config_name, "description": $description, "ignoreApplicationStopFailures": $ignore_application_stop_failures, "targetInstances": $target_instances, "autoRollbackConfiguration": $auto_rollback_configuration, "updateOutdatedInstancesOnly": $update_outdated_instances_only, "fileExistsBehavior": $file_exists_behavior, "overrideAlarmConfiguration": $override_alarm_configuration} | compact
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

# Creates a deployment configuration.
#
# POST /
# operationId: CreateDeploymentConfig
# --minimumHealthyHosts shape: {type?: "HOST_COUNT"|"FLEET_PERCENT", value?: int}
# --trafficRoutingConfig shape: {type?: "TimeBasedCanary"|"TimeBasedLinear"|"AllAtOnce", timeBasedCanary?: record, timeBasedLinear?: record}
export def "create-deployment-config" [
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
  deployment_config_name: string # The name of the deployment configuration to create.
  --minimum-healthy-hosts: record # Information about minimum healthy instance. — shape: {type?: "HOST_COUNT"|"FLEET_PERCENT", value?: int}
  --traffic-routing-config: record # The configuration that specifies how traffic is shifted from one version of a Lambda function to another version during an Lambda deployment, or from one Amazon ECS task set to another during an Amazon ECS deployment. — shape: {type?: "TimeBasedCanary"|"TimeBasedLinear"|"AllAtOnce", timeBasedCanary?: record, timeBasedLinear?: record}
  --compute-platform: string@compute-platform-completer # The destination platform type for the deployment (Lambda, Server, or ECS).
]: any -> record<deploymentConfigId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.CreateDeploymentConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentConfigName": $deployment_config_name, "minimumHealthyHosts": $minimum_healthy_hosts, "trafficRoutingConfig": $traffic_routing_config, "computePlatform": $compute_platform} | compact
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

# Creates a deployment group to which application revisions are deployed.
#
# POST /
# operationId: CreateDeploymentGroup
# --ec2TagFilters item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
# --onPremisesInstanceTagFilters item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
# --triggerConfigurations item shape: {triggerName?: string, triggerTargetArn?: string, triggerEvents?: list<string>}
# --alarmConfiguration shape: {enabled?: bool, ignorePollAlarmFailure?: bool, alarms?: list}
# --autoRollbackConfiguration shape: {enabled?: bool, events?: list<string>}
# --deploymentStyle shape: {deploymentType?: "IN_PLACE"|"BLUE_GREEN", deploymentOption?: "WITH_TRAFFIC_CONTROL"|"WITHOUT_TRAFFIC_CONTROL"}
# --blueGreenDeploymentConfiguration shape: {terminateBlueInstancesOnDeploymentSuccess?: record, deploymentReadyOption?: record, greenFleetProvisioningOption?: record}
# --loadBalancerInfo shape: {elbInfoList?: list, targetGroupInfoList?: list, targetGroupPairInfoList?: list}
# --ec2TagSet shape: {ec2TagSetList?: list}
# --ecsServices item shape: {serviceName?: string, clusterName?: string}
# --onPremisesTagSet shape: {onPremisesTagSetList?: list}
# --tags item shape: {Key?: string, Value?: string}
export def "create-deployment-group" [
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
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  deployment_group_name: string # The name of a new deployment group for the specified application.
  --deployment-config-name: string # If specified, the deployment configuration name can be either one of the predefined configurations provided with CodeDeploy or a custom deployment configuration that you create by calling the create deployment configuration operation. CodeDeployDefault.OneAtATime is the default deployment configuration. It is used if a configuration isn't specified for the deployment or deployment group. For more information about the predefined deployment configurations in CodeDeploy, see Working with Deployment Configurations in CodeDeploy (https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html) in the CodeDeploy User Guide.
  --ec2-tag-filters: list # The Amazon EC2 tags on which to filter. The deployment group includes Amazon EC2 instances with any of the specified tags. Cannot be used in the same call as ec2TagSet. — item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
  --on-premises-instance-tag-filters: list # The on-premises instance tags on which to filter. The deployment group includes on-premises instances with any of the specified tags. Cannot be used in the same call as OnPremisesTagSet. — item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
  --auto-scaling-groups: list<string> # A list of associated Amazon EC2 Auto Scaling groups.
  service_role_arn: string # A service role Amazon Resource Name (ARN) that allows CodeDeploy to act on the user's behalf when interacting with Amazon Web Services services.
  --trigger-configurations: list # Information about triggers to create when the deployment group is created. For examples, see Create a Trigger for an CodeDeploy Event (https://docs.aws.amazon.com/codedeploy/latest/userguide/how-to-notify-sns.html) in the CodeDeploy User Guide. — item shape: {triggerName?: string, triggerTargetArn?: string, triggerEvents?: list<string>}
  --alarm-configuration: record # Information about alarms associated with a deployment or deployment group. — shape: {enabled?: bool, ignorePollAlarmFailure?: bool, alarms?: list}
  --auto-rollback-configuration: record # Information about a configuration for automatically rolling back to a previous version of an application revision when a deployment is not completed successfully. — shape: {enabled?: bool, events?: list<string>}
  --outdated-instances-strategy: string@outdated-instances-strategy-completer # Indicates what happens when new Amazon EC2 instances are launched mid-deployment and do not receive the deployed application revision. If this option is set to UPDATE or is unspecified, CodeDeploy initiates one or more 'auto-update outdated instances' deployments to apply the deployed application revision to the new Amazon EC2 instances. If this option is set to IGNORE, CodeDeploy does not initiate a deployment to update the new Amazon EC2 instances. This may result in instances having different revisions.
  --deployment-style: record # Information about the type of deployment, either in-place or blue/green, you want to run and whether to route deployment traffic behind a load balancer. — shape: {deploymentType?: "IN_PLACE"|"BLUE_GREEN", deploymentOption?: "WITH_TRAFFIC_CONTROL"|"WITHOUT_TRAFFIC_CONTROL"}
  --blue-green-deployment-configuration: record # Information about blue/green deployment options for a deployment group. — shape: {terminateBlueInstancesOnDeploymentSuccess?: record, deploymentReadyOption?: record, greenFleetProvisioningOption?: record}
  --load-balancer-info: record # Information about the Elastic Load Balancing load balancer or target group used in a deployment. — shape: {elbInfoList?: list, targetGroupInfoList?: list, targetGroupPairInfoList?: list}
  --ec2-tag-set: record # Information about groups of Amazon EC2 instance tags. — shape: {ec2TagSetList?: list}
  --ecs-services: list # The target Amazon ECS services in the deployment group. This applies only to deployment groups that use the Amazon ECS compute platform. A target Amazon ECS service is specified as an Amazon ECS cluster and service name pair using the format <clustername>:<servicename>. — item shape: {serviceName?: string, clusterName?: string}
  --on-premises-tag-set: record # Information about groups of on-premises instance tags. — shape: {onPremisesTagSetList?: list}
  --tags: list # The metadata that you apply to CodeDeploy deployment groups to help you organize and categorize them. Each tag consists of a key and an optional value, both of which you define. — item shape: {Key?: string, Value?: string}
]: any -> record<deploymentGroupId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.CreateDeploymentGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationName": $application_name, "deploymentGroupName": $deployment_group_name, "deploymentConfigName": $deployment_config_name, "ec2TagFilters": $ec2_tag_filters, "onPremisesInstanceTagFilters": $on_premises_instance_tag_filters, "autoScalingGroups": $auto_scaling_groups, "serviceRoleArn": $service_role_arn, "triggerConfigurations": $trigger_configurations, "alarmConfiguration": $alarm_configuration, "autoRollbackConfiguration": $auto_rollback_configuration, "outdatedInstancesStrategy": $outdated_instances_strategy, "deploymentStyle": $deployment_style, "blueGreenDeploymentConfiguration": $blue_green_deployment_configuration, "loadBalancerInfo": $load_balancer_info, "ec2TagSet": $ec2_tag_set, "ecsServices": $ecs_services, "onPremisesTagSet": $on_premises_tag_set, "tags": $tags} | compact
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

# Deletes an application.
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.DeleteApplication")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationName": $application_name} | compact
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

# Deletes a deployment configuration. A deployment configuration cannot be deleted if it is currently in use. Predefined configurations cannot be deleted.
#
# POST /
# operationId: DeleteDeploymentConfig
export def "delete-deployment-config" [
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
  deployment_config_name: string # The name of a deployment configuration associated with the IAM user or Amazon Web Services account.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.DeleteDeploymentConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentConfigName": $deployment_config_name} | compact
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

# Deletes a deployment group.
#
# POST /
# operationId: DeleteDeploymentGroup
export def "delete-deployment-group" [
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
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  deployment_group_name: string # The name of a deployment group for the specified application.
]: any -> record<hooksNotCleanedUp: table<name: string, hook: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.DeleteDeploymentGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationName": $application_name, "deploymentGroupName": $deployment_group_name} | compact
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

# Deletes a GitHub account connection.
#
# POST /
# operationId: DeleteGitHubAccountToken
export def "delete-git-hub-account-token" [
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
  --token-name: string # The name of the GitHub account connection to delete.
]: any -> record<tokenName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.DeleteGitHubAccountToken")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"tokenName": $token_name} | compact
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

# Deletes resources linked to an external ID.
#
# POST /
# operationId: DeleteResourcesByExternalId
export def "delete-resources-by-external-id" [
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
  --external-id: string # The unique ID of an external resource (for example, a CloudFormation stack ID) that is linked to one or more CodeDeploy resources.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.DeleteResourcesByExternalId")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"externalId": $external_id} | compact
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

# Deregisters an on-premises instance.
#
# POST /
# operationId: DeregisterOnPremisesInstance
export def "deregister-on-premises-instance" [
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
  instance_name: string # The name of the on-premises instance to deregister.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.DeregisterOnPremisesInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"instanceName": $instance_name} | compact
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

# Gets information about an application.
#
# POST /
# operationId: GetApplication
export def "get-application" [
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
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
]: any -> record<application: record<applicationId: string, applicationName: string, createTime: string, linkedToGitHub: bool, gitHubAccountName: string, computePlatform: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.GetApplication")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationName": $application_name} | compact
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

# Gets information about an application revision.
#
# POST /
# operationId: GetApplicationRevision
# --revision shape: {revisionType?: "S3"|"GitHub"|"String"|"AppSpecContent", s3Location?: record, gitHubLocation?: record, string?: record, appSpecContent?: record}
export def "get-application-revision" [
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
  application_name: string # The name of the application that corresponds to the revision.
  revision: record # Information about the location of an application revision. — shape: {revisionType?: "S3"|"GitHub"|"String"|"AppSpecContent", s3Location?: record, gitHubLocation?: record, string?: record, appSpecContent?: record}
]: any -> record<applicationName: string, revision: record<revisionType: string, s3Location: record<bucket: string, key: string, bundleType: string, version: string, eTag: string>, gitHubLocation: record<repository: string, commitId: string>, string: record<content: string, sha256: string>, appSpecContent: record<content: string, sha256: string>>, revisionInfo: record<description: string, deploymentGroups: list<string>, firstUsedTime: string, lastUsedTime: string, registerTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.GetApplicationRevision")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationName": $application_name, "revision": $revision} | compact
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

# Gets information about a deployment. The content property of the appSpecContent object in the returned revision is always null. Use GetApplicationRevision and the sha256 property of the returned appSpecContent object to get the content of the deployment’s AppSpec file.
#
# POST /
# operationId: GetDeployment
export def "get-deployment" [
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
  deployment_id: string # The unique ID of a deployment associated with the IAM user or Amazon Web Services account.
]: any -> record<deploymentInfo: record<applicationName: string, deploymentGroupName: string, deploymentConfigName: string, deploymentId: string, previousRevision: record<revisionType: string, s3Location: record, gitHubLocation: record, string: record, appSpecContent: record>, revision: record<revisionType: string, s3Location: record, gitHubLocation: record, string: record, appSpecContent: record>, status: string, errorInformation: record<code: string, message: string>, createTime: string, startTime: string, completeTime: string, deploymentOverview: record<Pending: int, InProgress: int, Succeeded: int, Failed: int, Skipped: int, Ready: int>, description: string, creator: string, ignoreApplicationStopFailures: bool, autoRollbackConfiguration: record<enabled: bool, events: list>, updateOutdatedInstancesOnly: bool, rollbackInfo: record<rollbackDeploymentId: string, rollbackTriggeringDeploymentId: string, rollbackMessage: string>, deploymentStyle: record<deploymentType: string, deploymentOption: string>, targetInstances: record<tagFilters: list, autoScalingGroups: list, ec2TagSet: record>, instanceTerminationWaitTimeStarted: bool, blueGreenDeploymentConfiguration: record<terminateBlueInstancesOnDeploymentSuccess: record, deploymentReadyOption: record, greenFleetProvisioningOption: record>, loadBalancerInfo: record<elbInfoList: list, targetGroupInfoList: list, targetGroupPairInfoList: list>, additionalDeploymentStatusInfo: string, fileExistsBehavior: string, deploymentStatusMessages: list<string>, computePlatform: string, externalId: string, relatedDeployments: record<autoUpdateOutdatedInstancesRootDeploymentId: string, autoUpdateOutdatedInstancesDeploymentIds: list>, overrideAlarmConfiguration: record<enabled: bool, ignorePollAlarmFailure: bool, alarms: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.GetDeployment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentId": $deployment_id} | compact
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

# Gets information about a deployment configuration.
#
# POST /
# operationId: GetDeploymentConfig
export def "get-deployment-config" [
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
  deployment_config_name: string # The name of a deployment configuration associated with the IAM user or Amazon Web Services account.
]: any -> record<deploymentConfigInfo: record<deploymentConfigId: string, deploymentConfigName: string, minimumHealthyHosts: record<type: string, value: int>, createTime: string, computePlatform: string, trafficRoutingConfig: record<type: string, timeBasedCanary: record, timeBasedLinear: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.GetDeploymentConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentConfigName": $deployment_config_name} | compact
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

# Gets information about a deployment group.
#
# POST /
# operationId: GetDeploymentGroup
export def "get-deployment-group" [
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
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  deployment_group_name: string # The name of a deployment group for the specified application.
]: any -> record<deploymentGroupInfo: record<applicationName: string, deploymentGroupId: string, deploymentGroupName: string, deploymentConfigName: string, ec2TagFilters: list<record>, onPremisesInstanceTagFilters: list<record>, autoScalingGroups: list<record>, serviceRoleArn: string, targetRevision: record<revisionType: string, s3Location: record, gitHubLocation: record, string: record, appSpecContent: record>, triggerConfigurations: list<record>, alarmConfiguration: record<enabled: bool, ignorePollAlarmFailure: bool, alarms: list>, autoRollbackConfiguration: record<enabled: bool, events: list>, deploymentStyle: record<deploymentType: string, deploymentOption: string>, outdatedInstancesStrategy: string, blueGreenDeploymentConfiguration: record<terminateBlueInstancesOnDeploymentSuccess: record, deploymentReadyOption: record, greenFleetProvisioningOption: record>, loadBalancerInfo: record<elbInfoList: list, targetGroupInfoList: list, targetGroupPairInfoList: list>, lastSuccessfulDeployment: record<deploymentId: string, status: string, endTime: string, createTime: string>, lastAttemptedDeployment: record<deploymentId: string, status: string, endTime: string, createTime: string>, ec2TagSet: record<ec2TagSetList: list>, onPremisesTagSet: record<onPremisesTagSetList: list>, computePlatform: string, ecsServices: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.GetDeploymentGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationName": $application_name, "deploymentGroupName": $deployment_group_name} | compact
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

# Gets information about an instance as part of a deployment.
#
# POST /
# DEPRECATED
# operationId: GetDeploymentInstance
@deprecated
export def "get-deployment-instance" [
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
  deployment_id: string # The unique ID of a deployment.
  instance_id: string # The unique ID of an instance in the deployment group.
]: any -> record<instanceSummary: record<deploymentId: string, instanceId: string, status: string, lastUpdatedAt: string, lifecycleEvents: list<record>, instanceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.GetDeploymentInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentId": $deployment_id, "instanceId": $instance_id} | compact
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

# Returns information about a deployment target.
#
# POST /
# operationId: GetDeploymentTarget
export def "get-deployment-target" [
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
  --deployment-id: string # The unique ID of a deployment.
  --target-id: string # The unique ID of a deployment target.
]: any -> record<deploymentTarget: record<deploymentTargetType: string, instanceTarget: record<deploymentId: string, targetId: string, targetArn: string, status: string, lastUpdatedAt: string, lifecycleEvents: list, instanceLabel: string>, lambdaTarget: record<deploymentId: string, targetId: string, targetArn: string, status: string, lastUpdatedAt: string, lifecycleEvents: list, lambdaFunctionInfo: record>, ecsTarget: record<deploymentId: string, targetId: string, targetArn: string, lastUpdatedAt: string, lifecycleEvents: list, status: string, taskSetsInfo: list>, cloudFormationTarget: record<deploymentId: string, targetId: string, lastUpdatedAt: string, lifecycleEvents: list, status: string, resourceType: string, targetVersionWeight: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.GetDeploymentTarget")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentId": $deployment_id, "targetId": $target_id} | compact
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

# Gets information about an on-premises instance.
#
# POST /
# operationId: GetOnPremisesInstance
export def "get-on-premises-instance" [
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
  instance_name: string # The name of the on-premises instance about which to get information.
]: any -> record<instanceInfo: record<instanceName: string, iamSessionArn: string, iamUserArn: string, instanceArn: string, registerTime: string, deregisterTime: string, tags: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.GetOnPremisesInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"instanceName": $instance_name} | compact
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

# Lists information about revisions for an application.
#
# POST /
# operationId: ListApplicationRevisions
export def "list-application-revisions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-27 # required
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  --sort-by: string@sort-by-completer # The column name to use to sort the list results: registerTime: Sort by the time the revisions were registered with CodeDeploy. firstUsedTime: Sort by the time the revisions were first used in a deployment. lastUsedTime: Sort by the time the revisions were last used in a deployment. If not specified or set to null, the results are returned in an arbitrary order.
  --sort-order: string@sort-order-completer # The order in which to sort the list results: ascending: ascending order. descending: descending order. If not specified, the results are sorted in ascending order. If set to null, the results are sorted in an arbitrary order.
  --s3-bucket: string # An Amazon S3 bucket name to limit the search for revisions. If set to null, all of the user's buckets are searched.
  --s3-key-prefix: string # A key prefix for the set of Amazon S3 objects to limit the search for revisions.
  --deployed: string@deployed-completer # Whether to list revisions based on whether the revision is the target revision of a deployment group: include: List revisions that are target revisions of a deployment group. exclude: Do not list revisions that are target revisions of a deployment group. ignore: List all revisions.
  --next-token-body: string # An identifier returned from the previous ListApplicationRevisions call. It can be used to return the next set of applications in the list. (body field)
]: any -> record<revisions: table<revisionType: string, s3Location: record, gitHubLocation: record, string: record, appSpecContent: record>, nextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.ListApplicationRevisions")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"applicationName": $application_name, "sortBy": $sort_by, "sortOrder": $sort_order, "s3Bucket": $s3_bucket, "s3KeyPrefix": $s3_key_prefix, "deployed": $deployed, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the applications registered with the IAM user or Amazon Web Services account.
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
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28 # required
  --next-token-body: string # An identifier returned from the previous list applications call. It can be used to return the next set of applications in the list. (body field)
]: any -> record<applications: list<string>, nextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.ListApplications")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the deployment configurations with the IAM user or Amazon Web Services account.
#
# POST /
# operationId: ListDeploymentConfigs
export def "list-deployment-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29 # required
  --next-token-body: string # An identifier returned from the previous ListDeploymentConfigs call. It can be used to return the next set of deployment configurations in the list. (body field)
]: any -> record<deploymentConfigsList: list<string>, nextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.ListDeploymentConfigs")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the deployment groups for an application registered with the IAM user or Amazon Web Services account.
#
# POST /
# operationId: ListDeploymentGroups
export def "list-deployment-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30 # required
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  --next-token-body: string # An identifier returned from the previous list deployment groups call. It can be used to return the next set of deployment groups in the list. (body field)
]: any -> record<applicationName: string, deploymentGroups: list<string>, nextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.ListDeploymentGroups")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"applicationName": $application_name, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# The newer BatchGetDeploymentTargets should be used instead because it works with all compute types. ListDeploymentInstances throws an exception if it is used with a compute platform other than EC2/On-premises or Lambda. Lists the instance for a deployment associated with the IAM user or Amazon Web Services account.
#
# POST /
# DEPRECATED
# operationId: ListDeploymentInstances
@deprecated
export def "list-deployment-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31 # required
  deployment_id: string # The unique ID of a deployment.
  --next-token-body: string # An identifier returned from the previous list deployment instances call. It can be used to return the next set of deployment instances in the list. (body field)
  --instance-status-filter: list<string> # A subset of instances to list by status: Pending: Include those instances with pending deployments. InProgress: Include those instances where deployments are still in progress. Succeeded: Include those instances with successful deployments. Failed: Include those instances with failed deployments. Skipped: Include those instances with skipped deployments. Unknown: Include those instances with deployments in an unknown state.
  --instance-type-filter: list<string> # The set of instances in a blue/green deployment, either those in the original environment ("BLUE") or those in the replacement environment ("GREEN"), for which you want to view instance information.
]: any -> record<instancesList: list<string>, nextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.ListDeploymentInstances")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"deploymentId": $deployment_id, "nextToken": $next_token_body, "instanceStatusFilter": $instance_status_filter, "instanceTypeFilter": $instance_type_filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns an array of target IDs that are associated a deployment.
#
# POST /
# operationId: ListDeploymentTargets
export def "list-deployment-targets" [
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
  --deployment-id: string # The unique ID of a deployment.
  --next-token: string # A token identifier returned from the previous ListDeploymentTargets call. It can be used to return the next set of deployment targets in the list.
  --target-filters: record # A key used to filter the returned targets. The two valid values are: TargetStatus - A TargetStatus filter string can be Failed, InProgress, Pending, Ready, Skipped, Succeeded, or Unknown. ServerInstanceLabel - A ServerInstanceLabel filter string can be Blue or Green.
]: any -> record<targetIds: list<string>, nextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.ListDeploymentTargets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentId": $deployment_id, "nextToken": $next_token, "targetFilters": $target_filters} | compact
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

# Lists the deployments in a deployment group for an application registered with the IAM user or Amazon Web Services account.
#
# POST /
# operationId: ListDeployments
# --createTimeRange shape: {start?: string, end?: string}
export def "list-deployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33 # required
  --application-name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account. If applicationName is specified, then deploymentGroupName must be specified. If it is not specified, then deploymentGroupName must not be specified.
  --deployment-group-name: string # The name of a deployment group for the specified application. If deploymentGroupName is specified, then applicationName must be specified. If it is not specified, then applicationName must not be specified.
  --external-id: string # The unique ID of an external resource for returning deployments linked to the external resource.
  --include-only-statuses: list<string> # A subset of deployments to list by status: Created: Include created deployments in the resulting list. Queued: Include queued deployments in the resulting list. In Progress: Include in-progress deployments in the resulting list. Succeeded: Include successful deployments in the resulting list. Failed: Include failed deployments in the resulting list. Stopped: Include stopped deployments in the resulting list.
  --create-time-range: record # Information about a time range. — shape: {start?: string, end?: string}
  --next-token-body: string # An identifier returned from the previous list deployments call. It can be used to return the next set of deployments in the list. (body field)
]: any -> record<deployments: list<string>, nextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.ListDeployments")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"applicationName": $application_name, "deploymentGroupName": $deployment_group_name, "externalId": $external_id, "includeOnlyStatuses": $include_only_statuses, "createTimeRange": $create_time_range, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the names of stored connections to GitHub accounts.
#
# POST /
# operationId: ListGitHubAccountTokenNames
export def "list-git-hub-account-token-names" [
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
  --next-token: string # An identifier returned from the previous ListGitHubAccountTokenNames call. It can be used to return the next set of names in the list.
]: any -> record<tokenNameList: list<string>, nextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.ListGitHubAccountTokenNames")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"nextToken": $next_token} | compact
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

# Gets a list of names for one or more on-premises instances. Unless otherwise specified, both registered and deregistered on-premises instance names are listed. To list only registered or deregistered on-premises instance names, use the registration status parameter.
#
# POST /
# operationId: ListOnPremisesInstances
# --tagFilters item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
export def "list-on-premises-instances" [
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
  --registration-status: string@registration-status-completer # The registration status of the on-premises instances: Deregistered: Include deregistered on-premises instances in the resulting list. Registered: Include registered on-premises instances in the resulting list.
  --tag-filters: list # The on-premises instance tags that are used to restrict the on-premises instance names returned. — item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
  --next-token: string # An identifier returned from the previous list on-premises instances call. It can be used to return the next set of on-premises instances in the list.
]: any -> record<instanceNames: list<string>, nextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.ListOnPremisesInstances")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"registrationStatus": $registration_status, "tagFilters": $tag_filters, "nextToken": $next_token} | compact
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

# Returns a list of tags for the resource identified by a specified Amazon Resource Name (ARN). Tags are used to organize and categorize your CodeDeploy resources.
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  resource_arn: string # The ARN of a CodeDeploy resource. ListTagsForResource returns all the tags associated with the resource that is identified by the ResourceArn.
  --next-token: string # An identifier returned from the previous ListTagsForResource call. It can be used to return the next set of applications in the list.
]: any -> record<Tags: table<Key: string, Value: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.ListTagsForResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "NextToken": $next_token} | compact
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

# Sets the result of a Lambda validation function. The function validates lifecycle hooks during a deployment that uses the Lambda or Amazon ECS compute platform. For Lambda deployments, the available lifecycle hooks are BeforeAllowTraffic and AfterAllowTraffic. For Amazon ECS deployments, the available lifecycle hooks are BeforeInstall, AfterInstall, AfterAllowTestTraffic, BeforeAllowTraffic, and AfterAllowTraffic. Lambda validation functions return Succeeded or Failed. For more information, see AppSpec 'hooks' Section for an Lambda Deployment (https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-lambda) and AppSpec 'hooks' Section for an Amazon ECS Deployment (https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-ecs).
#
# POST /
# operationId: PutLifecycleEventHookExecutionStatus
export def "put-lifecycle-event-hook-execution-status" [
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
  --deployment-id: string # The unique ID of a deployment. Pass this ID to a Lambda function that validates a deployment lifecycle event.
  --lifecycle-event-hook-execution-id: string # The execution ID of a deployment's lifecycle hook. A deployment lifecycle hook is specified in the hooks section of the AppSpec file.
  --status: string@status-completer # The result of a Lambda function that validates a deployment lifecycle event. The values listed in Valid Values are valid for lifecycle statuses in general; however, only Succeeded and Failed can be passed successfully in your API call.
]: any -> record<lifecycleEventHookExecutionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.PutLifecycleEventHookExecutionStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentId": $deployment_id, "lifecycleEventHookExecutionId": $lifecycle_event_hook_execution_id, "status": $status} | compact
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

# Registers with CodeDeploy a revision for the specified application.
#
# POST /
# operationId: RegisterApplicationRevision
# --revision shape: {revisionType?: "S3"|"GitHub"|"String"|"AppSpecContent", s3Location?: record, gitHubLocation?: record, string?: record, appSpecContent?: record}
export def "register-application-revision" [
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
  application_name: string # The name of an CodeDeploy application associated with the IAM user or Amazon Web Services account.
  --description: string # A comment about the revision.
  revision: record # Information about the location of an application revision. — shape: {revisionType?: "S3"|"GitHub"|"String"|"AppSpecContent", s3Location?: record, gitHubLocation?: record, string?: record, appSpecContent?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.RegisterApplicationRevision")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationName": $application_name, "description": $description, "revision": $revision} | compact
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

# Registers an on-premises instance. Only one IAM ARN (an IAM session ARN or IAM user ARN) is supported in the request. You cannot use both.
#
# POST /
# operationId: RegisterOnPremisesInstance
export def "register-on-premises-instance" [
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
  instance_name: string # The name of the on-premises instance to register.
  --iam-session-arn: string # The ARN of the IAM session to associate with the on-premises instance.
  --iam-user-arn: string # The ARN of the IAM user to associate with the on-premises instance.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.RegisterOnPremisesInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"instanceName": $instance_name, "iamSessionArn": $iam_session_arn, "iamUserArn": $iam_user_arn} | compact
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

# Removes one or more tags from one or more on-premises instances.
#
# POST /
# operationId: RemoveTagsFromOnPremisesInstances
# --tags item shape: {Key?: string, Value?: string}
export def "remove-tags-from-on-premises-instances" [
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
  tags: list # The tag key-value pairs to remove from the on-premises instances. — item shape: {Key?: string, Value?: string}
  instance_names: list<string> # The names of the on-premises instances from which to remove tags.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.RemoveTagsFromOnPremisesInstances")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"tags": $tags, "instanceNames": $instance_names} | compact
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

# In a blue/green deployment, overrides any specified wait time and starts terminating instances immediately after the traffic routing is complete.
#
# POST /
# DEPRECATED
# operationId: SkipWaitTimeForInstanceTermination
@deprecated
export def "skip-wait-time-for-instance-termination" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  --deployment-id: string # The unique ID of a blue/green deployment for which you want to skip the instance termination wait time.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.SkipWaitTimeForInstanceTermination")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentId": $deployment_id} | compact
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

# Attempts to stop an ongoing deployment.
#
# POST /
# operationId: StopDeployment
export def "stop-deployment" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  deployment_id: string # The unique ID of a deployment.
  --auto-rollback-enabled: oneof<nothing, bool> # Indicates, when a deployment is stopped, whether instances that have been updated should be rolled back to the previous version of the application revision.
]: any -> record<status: string, statusMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.StopDeployment")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deploymentId": $deployment_id, "autoRollbackEnabled": $auto_rollback_enabled} | compact
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

# Associates the list of tags in the input Tags parameter with the resource identified by the ResourceArn input parameter.
#
# POST /
# operationId: TagResource
# --Tags item shape: {Key?: string, Value?: string}
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  resource_arn: string # The ARN of a resource, such as a CodeDeploy application or deployment group.
  tags: list # A list of tags that TagResource associates with a resource. The resource is identified by the ResourceArn input parameter. — item shape: {Key?: string, Value?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Tags": $tags} | compact
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

# Disassociates a resource from a list of tags. The resource is identified by the ResourceArn input parameter. The tags are identified by the list of keys in the TagKeys input parameter.
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  resource_arn: string # The Amazon Resource Name (ARN) that specifies from which resource to disassociate the tags with the keys in the TagKeys input parameter.
  tag_keys: list<string> # A list of keys of Tag objects. The Tag objects identified by the keys are disassociated from the resource specified by the ResourceArn input parameter.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "TagKeys": $tag_keys} | compact
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

# Changes the name of an application.
#
# POST /
# operationId: UpdateApplication
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  --application-name: string # The current name of the application you want to change.
  --new-application-name: string # The new name to give the application.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.UpdateApplication")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationName": $application_name, "newApplicationName": $new_application_name} | compact
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

# Changes information about a deployment group.
#
# POST /
# operationId: UpdateDeploymentGroup
# --ec2TagFilters item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
# --onPremisesInstanceTagFilters item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
# --triggerConfigurations item shape: {triggerName?: string, triggerTargetArn?: string, triggerEvents?: list<string>}
# --alarmConfiguration shape: {enabled?: bool, ignorePollAlarmFailure?: bool, alarms?: list}
# --autoRollbackConfiguration shape: {enabled?: bool, events?: list<string>}
# --deploymentStyle shape: {deploymentType?: "IN_PLACE"|"BLUE_GREEN", deploymentOption?: "WITH_TRAFFIC_CONTROL"|"WITHOUT_TRAFFIC_CONTROL"}
# --blueGreenDeploymentConfiguration shape: {terminateBlueInstancesOnDeploymentSuccess?: record, deploymentReadyOption?: record, greenFleetProvisioningOption?: record}
# --loadBalancerInfo shape: {elbInfoList?: list, targetGroupInfoList?: list, targetGroupPairInfoList?: list}
# --ec2TagSet shape: {ec2TagSetList?: list}
# --ecsServices item shape: {serviceName?: string, clusterName?: string}
# --onPremisesTagSet shape: {onPremisesTagSetList?: list}
export def "update-deployment-group" [
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
  --x-amz-target: string@x-amz-target-completer-46 # required
  application_name: string # The application name that corresponds to the deployment group to update.
  current_deployment_group_name: string # The current name of the deployment group.
  --new-deployment-group-name: string # The new name of the deployment group, if you want to change it.
  --deployment-config-name: string # The replacement deployment configuration name to use, if you want to change it.
  --ec2-tag-filters: list # The replacement set of Amazon EC2 tags on which to filter, if you want to change them. To keep the existing tags, enter their names. To remove tags, do not enter any tag names. — item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
  --on-premises-instance-tag-filters: list # The replacement set of on-premises instance tags on which to filter, if you want to change them. To keep the existing tags, enter their names. To remove tags, do not enter any tag names. — item shape: {Key?: string, Value?: string, Type?: "KEY_ONLY"|"VALUE_ONLY"|"KEY_AND_VALUE"}
  --auto-scaling-groups: list<string> # The replacement list of Auto Scaling groups to be included in the deployment group, if you want to change them. To keep the Auto Scaling groups, enter their names or do not specify this parameter. To remove Auto Scaling groups, specify a non-null empty list of Auto Scaling group names to detach all CodeDeploy-managed Auto Scaling lifecycle hooks. For examples, see Amazon EC2 instances in an Amazon EC2 Auto Scaling group fail to launch and receive the error "Heartbeat Timeout" (https://docs.aws.amazon.com/https:/docs.aws.amazon.com/codedeploy/latest/userguide/troubleshooting-auto-scaling.html#troubleshooting-auto-scaling-heartbeat) in the CodeDeploy User Guide.
  --service-role-arn: string # A replacement ARN for the service role, if you want to change it.
  --trigger-configurations: list # Information about triggers to change when the deployment group is updated. For examples, see Edit a Trigger in a CodeDeploy Deployment Group (https://docs.aws.amazon.com/codedeploy/latest/userguide/how-to-notify-edit.html) in the CodeDeploy User Guide. — item shape: {triggerName?: string, triggerTargetArn?: string, triggerEvents?: list<string>}
  --alarm-configuration: record # Information about alarms associated with a deployment or deployment group. — shape: {enabled?: bool, ignorePollAlarmFailure?: bool, alarms?: list}
  --auto-rollback-configuration: record # Information about a configuration for automatically rolling back to a previous version of an application revision when a deployment is not completed successfully. — shape: {enabled?: bool, events?: list<string>}
  --outdated-instances-strategy: string@outdated-instances-strategy-completer # Indicates what happens when new Amazon EC2 instances are launched mid-deployment and do not receive the deployed application revision. If this option is set to UPDATE or is unspecified, CodeDeploy initiates one or more 'auto-update outdated instances' deployments to apply the deployed application revision to the new Amazon EC2 instances. If this option is set to IGNORE, CodeDeploy does not initiate a deployment to update the new Amazon EC2 instances. This may result in instances having different revisions.
  --deployment-style: record # Information about the type of deployment, either in-place or blue/green, you want to run and whether to route deployment traffic behind a load balancer. — shape: {deploymentType?: "IN_PLACE"|"BLUE_GREEN", deploymentOption?: "WITH_TRAFFIC_CONTROL"|"WITHOUT_TRAFFIC_CONTROL"}
  --blue-green-deployment-configuration: record # Information about blue/green deployment options for a deployment group. — shape: {terminateBlueInstancesOnDeploymentSuccess?: record, deploymentReadyOption?: record, greenFleetProvisioningOption?: record}
  --load-balancer-info: record # Information about the Elastic Load Balancing load balancer or target group used in a deployment. — shape: {elbInfoList?: list, targetGroupInfoList?: list, targetGroupPairInfoList?: list}
  --ec2-tag-set: record # Information about groups of Amazon EC2 instance tags. — shape: {ec2TagSetList?: list}
  --ecs-services: list # The target Amazon ECS services in the deployment group. This applies only to deployment groups that use the Amazon ECS compute platform. A target Amazon ECS service is specified as an Amazon ECS cluster and service name pair using the format <clustername>:<servicename>. — item shape: {serviceName?: string, clusterName?: string}
  --on-premises-tag-set: record # Information about groups of on-premises instance tags. — shape: {onPremisesTagSetList?: list}
]: any -> record<hooksNotCleanedUp: table<name: string, hook: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeDeploy_20141006.UpdateDeploymentGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"applicationName": $application_name, "currentDeploymentGroupName": $current_deployment_group_name, "newDeploymentGroupName": $new_deployment_group_name, "deploymentConfigName": $deployment_config_name, "ec2TagFilters": $ec2_tag_filters, "onPremisesInstanceTagFilters": $on_premises_instance_tag_filters, "autoScalingGroups": $auto_scaling_groups, "serviceRoleArn": $service_role_arn, "triggerConfigurations": $trigger_configurations, "alarmConfiguration": $alarm_configuration, "autoRollbackConfiguration": $auto_rollback_configuration, "outdatedInstancesStrategy": $outdated_instances_strategy, "deploymentStyle": $deployment_style, "blueGreenDeploymentConfiguration": $blue_green_deployment_configuration, "loadBalancerInfo": $load_balancer_info, "ec2TagSet": $ec2_tag_set, "ecsServices": $ecs_services, "onPremisesTagSet": $on_premises_tag_set} | compact
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
