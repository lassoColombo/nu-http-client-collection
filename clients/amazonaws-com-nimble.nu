# Auto-generated client for AmazonNimbleStudio v2020-08-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/nimble/2020-08-01/openapi.json
# Auth: --token flag or $env.AMAZONNIMBLESTUDIO_TOKEN

const BASE_URL = "http://nimble.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZONNIMBLESTUDIO_TOKEN | default "" }
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

def base-url-completer [] { ["http://nimble.us-east-1.amazonaws.com" "http://nimble.us-east-2.amazonaws.com" "http://nimble.us-west-1.amazonaws.com" "http://nimble.us-west-2.amazonaws.com" "http://nimble.us-gov-west-1.amazonaws.com" "http://nimble.us-gov-east-1.amazonaws.com" "http://nimble.ca-central-1.amazonaws.com" "http://nimble.eu-north-1.amazonaws.com" "http://nimble.eu-west-1.amazonaws.com" "http://nimble.eu-west-2.amazonaws.com" "http://nimble.eu-west-3.amazonaws.com" "http://nimble.eu-central-1.amazonaws.com" "http://nimble.eu-south-1.amazonaws.com" "http://nimble.af-south-1.amazonaws.com" "http://nimble.ap-northeast-1.amazonaws.com" "http://nimble.ap-northeast-2.amazonaws.com" "http://nimble.ap-northeast-3.amazonaws.com" "http://nimble.ap-southeast-1.amazonaws.com" "http://nimble.ap-southeast-2.amazonaws.com" "http://nimble.ap-east-1.amazonaws.com" "http://nimble.ap-south-1.amazonaws.com" "http://nimble.sa-east-1.amazonaws.com" "http://nimble.me-south-1.amazonaws.com" "https://nimble.us-east-1.amazonaws.com" "https://nimble.us-east-2.amazonaws.com" "https://nimble.us-west-1.amazonaws.com" "https://nimble.us-west-2.amazonaws.com" "https://nimble.us-gov-west-1.amazonaws.com" "https://nimble.us-gov-east-1.amazonaws.com" "https://nimble.ca-central-1.amazonaws.com" "https://nimble.eu-north-1.amazonaws.com" "https://nimble.eu-west-1.amazonaws.com" "https://nimble.eu-west-2.amazonaws.com" "https://nimble.eu-west-3.amazonaws.com" "https://nimble.eu-central-1.amazonaws.com" "https://nimble.eu-south-1.amazonaws.com" "https://nimble.af-south-1.amazonaws.com" "https://nimble.ap-northeast-1.amazonaws.com" "https://nimble.ap-northeast-2.amazonaws.com" "https://nimble.ap-northeast-3.amazonaws.com" "https://nimble.ap-southeast-1.amazonaws.com" "https://nimble.ap-southeast-2.amazonaws.com" "https://nimble.ap-east-1.amazonaws.com" "https://nimble.ap-south-1.amazonaws.com" "https://nimble.sa-east-1.amazonaws.com" "https://nimble.me-south-1.amazonaws.com" "http://nimble.cn-north-1.amazonaws.com.cn" "http://nimble.cn-northwest-1.amazonaws.com.cn" "https://nimble.cn-north-1.amazonaws.com.cn" "https://nimble.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def ec2-instance-type-completer [] { ["g3.4xlarge" "g3s.xlarge" "g4dn.12xlarge" "g4dn.16xlarge" "g4dn.2xlarge" "g4dn.4xlarge" "g4dn.8xlarge" "g4dn.xlarge" "g5.16xlarge" "g5.2xlarge" "g5.4xlarge" "g5.8xlarge" "g5.xlarge"] }
def subtype-completer [] { ["AMAZON_FSX_FOR_LUSTRE" "AMAZON_FSX_FOR_WINDOWS" "AWS_MANAGED_MICROSOFT_AD" "CUSTOM"] }
def type-completer [] { ["ACTIVE_DIRECTORY" "COMPUTE_FARM" "CUSTOM" "LICENSE_SERVICE" "SHARED_FILE_SYSTEM"] }
def persona-completer [] { ["USER"] }
def volume-retention-mode-completer [] { ["DELETE" "RETAIN"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2020-08-01-studios-eula-acceptances create-accept" } } | get name | first)
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

# Accept EULAs.
#
# POST /2020-08-01/studios/{studioId}/eula-acceptances
# operationId: AcceptEulas
export def "2020-08-01-studios-eula-acceptances create-accept" [
  studio_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --eula-ids: list<string> # The EULA ID.
]: any -> record<eulaAcceptances: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/eula-acceptances"))
  let req_body = {"eulaIds": $eula_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List EULA acceptances.
#
# GET /2020-08-01/studios/{studioId}/eula-acceptances
# operationId: ListEulaAcceptances
export def "2020-08-01-studios-eula-acceptances list" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --eula-ids: list # The list of EULA IDs that have been previously accepted.
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<eulaAcceptances: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "eulaIds" $eula_ids "multi") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/eula-acceptances") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"eulaIds": $eula_ids, "nextToken": $next_token} | compact), body: null}
}

# Create a launch profile.
#
# POST /2020-08-01/studios/{studioId}/launch-profiles
# operationId: CreateLaunchProfile
# --streamConfiguration shape: {automaticTerminationMode?: any, clipboardMode?: any, ec2InstanceTypes?: any, maxSessionLengthInMinutes?: any, maxStoppedSessionLengthInMinutes?: any, sessionBackup?: any, sessionPersistenceMode?: any, sessionStorage?: any, streamingImageIds?: any, volumeConfiguration?: any}
export def "2020-08-01-studios-launch-profiles create" [
  studio_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --description: string # A human-readable description of the launch profile. (format: password)
  ec2_subnet_ids: list<string> # Specifies the IDs of the EC2 subnets where streaming sessions will be accessible from. These subnets must support the specified instance types.
  launch_profile_protocol_versions: list<string> # The version number of the protocol that is used by the launch profile. The only valid version is "2021-03-31".
  name: string # The name for the launch profile. (format: password)
  stream_configuration: record # Configuration for streaming workstations created using this launch profile. — shape: {automaticTerminationMode?: any, clipboardMode?: any, ec2InstanceTypes?: any, maxSessionLengthInMinutes?: any, maxStoppedSessionLengthInMinutes?: any, sessionBackup?: any, sessionPersistenceMode?: any, sessionStorage?: any, streamingImageIds?: any, volumeConfiguration?: any}
  studio_component_ids: list<string> # Unique identifiers for a collection of studio components that can be used with this launch profile.
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
]: any -> record<launchProfile: record<arn: record, createdAt: record, createdBy: record, description: record, ec2SubnetIds: record, launchProfileId: record, launchProfileProtocolVersions: record, name: record, state: record, statusCode: record, statusMessage: record, streamConfiguration: record<automaticTerminationMode: record, clipboardMode: record, ec2InstanceTypes: record, maxSessionLengthInMinutes: record, maxStoppedSessionLengthInMinutes: record, sessionBackup: record, sessionPersistenceMode: record, sessionStorage: record, streamingImageIds: record, volumeConfiguration: record>, studioComponentIds: record, tags: record, updatedAt: record, updatedBy: record, validationResults: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles"))
  let req_body = {"description": $description, "ec2SubnetIds": $ec2_subnet_ids, "launchProfileProtocolVersions": $launch_profile_protocol_versions, "name": $name, "streamConfiguration": $stream_configuration, "studioComponentIds": $studio_component_ids, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all the launch profiles a studio.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles
# operationId: ListLaunchProfiles
export def "2020-08-01-studios-launch-profiles list" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The max number of results to return in the response.
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --principal-id: string # The principal ID. This currently supports a IAM Identity Center UserId.
  --states: list # Filter this request to launch profiles in any of the given states.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<launchProfiles: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "principalId" $principal_id "scalar") (serialize-qp "states" $states "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "principalId": $principal_id, "states": $states} | compact), body: null}
}

# Creates a streaming image resource in a studio.
#
# POST /2020-08-01/studios/{studioId}/streaming-images
# operationId: CreateStreamingImage
export def "2020-08-01-studios-streaming-images create" [
  studio_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --description: string # The description. (format: password)
  ec2_image_id: string # The ID of an EC2 machine image with which to create this streaming image.
  name: string # A friendly name for a streaming image resource. (format: password)
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
]: any -> record<streamingImage: record<arn: record, description: record, ec2ImageId: record, encryptionConfiguration: record<keyArn: record, keyType: record>, eulaIds: record, name: record, owner: record, platform: record, state: record, statusCode: record, statusMessage: record, streamingImageId: record, tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-images"))
  let req_body = {"description": $description, "ec2ImageId": $ec2_image_id, "name": $name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List the streaming image resources available to this studio. This list will contain both images provided by Amazon Web Services, as well as streaming images that you have created in your studio.
#
# GET /2020-08-01/studios/{studioId}/streaming-images
# operationId: ListStreamingImages
export def "2020-08-01-studios-streaming-images list" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --owner: string # Filter this request to streaming images with the given owner
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<nextToken: record, streamingImages: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-images") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "owner": $owner} | compact), body: null}
}

# Creates a streaming session in a studio. After invoking this operation, you must poll GetStreamingSession until the streaming session is in the READY state.
#
# POST /2020-08-01/studios/{studioId}/streaming-sessions
# operationId: CreateStreamingSession
export def "2020-08-01-studios-streaming-sessions create" [
  studio_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --ec2-instance-type: string@ec2-instance-type-completer # The EC2 Instance type used for the streaming session.
  launch_profile_id: string # The ID of the launch profile used to control access from the streaming session.
  --owned-by: string # The user ID of the user that owns the streaming session. The user that owns the session will be logging into the session and interacting with the virtual workstation.
  --streaming-image-id: string # The ID of the streaming image.
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
]: any -> record<session: record<arn: record, automaticTerminationMode: record, backupMode: record, createdAt: record, createdBy: record, ec2InstanceType: record, launchProfileId: record, maxBackupsToRetain: record, ownedBy: record, sessionId: record, sessionPersistenceMode: record, startedAt: record, startedBy: record, startedFromBackupId: record, state: record, statusCode: record, statusMessage: record, stopAt: record, stoppedAt: record, stoppedBy: record, streamingImageId: record, tags: record, terminateAt: record, updatedAt: record, updatedBy: record, volumeConfiguration: record<iops: record, size: record, throughput: record>, volumeRetentionMode: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions"))
  let req_body = {"ec2InstanceType": $ec2_instance_type, "launchProfileId": $launch_profile_id, "ownedBy": $owned_by, "streamingImageId": $streaming_image_id, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the streaming sessions in a studio.
#
# GET /2020-08-01/studios/{studioId}/streaming-sessions
# operationId: ListStreamingSessions
export def "2020-08-01-studios-streaming-sessions list" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by: string # Filters the request to streaming sessions created by the given user.
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --owned-by: string # Filters the request to streaming session owned by the given user
  --session-ids: string # Filters the request to only the provided session IDs.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<nextToken: record, sessions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "createdBy" $created_by "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "ownedBy" $owned_by "scalar") (serialize-qp "sessionIds" $session_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"createdBy": $created_by, "nextToken": $next_token, "ownedBy": $owned_by, "sessionIds": $session_ids} | compact), body: null}
}

# Creates a streaming session stream for a streaming session. After invoking this API, invoke GetStreamingSessionStream with the returned streamId to poll the resource until it is in the READY state.
#
# POST /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/streams
# operationId: CreateStreamingSessionStream
export def "2020-08-01-studios-streaming-sessions-streams create" [
  studio_id: string
  session_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --expiration-in-seconds: int # The expiration time in seconds.
]: any -> record<stream: record<createdAt: record, createdBy: record, expiresAt: record, ownedBy: record, state: record, statusCode: record, streamId: record, url: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), session_id: (encode-path-segment $session_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions/{session_id}/streams"))
  let req_body = {"expirationInSeconds": $expiration_in_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a new studio. When creating a studio, two IAM roles must be provided: the admin role and the user role. These roles are assumed by your users when they log in to the Nimble Studio portal. The user role must have the AmazonNimbleStudio-StudioUser managed policy attached for the portal to function properly. The admin role must have the AmazonNimbleStudio-StudioAdmin managed policy attached for the portal to function properly. You may optionally specify a KMS key in the StudioEncryptionConfiguration. In Nimble Studio, resource names, descriptions, initialization scripts, and other data you provide are always encrypted at rest using an KMS key. By default, this key is owned by Amazon Web Services and managed on your behalf. You may provide your own KMS key when calling CreateStudio to encrypt this data using a key you own and manage. When providing an KMS key during studio creation, Nimble Studio creates KMS grants in your account to provide your studio user and admin roles access to these KMS keys. If you delete this grant, the studio will no longer be accessible to your portal users. If you delete the studio KMS key, your studio will no longer be accessible.
#
# POST /2020-08-01/studios
# operationId: CreateStudio
# --studioEncryptionConfiguration shape: {keyArn?: any, keyType?: any}
export def "2020-08-01-studios create" [
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  admin_role_arn: string # The IAM role that studio admins will assume when logging in to the Nimble Studio portal.
  display_name: string # A friendly name for the studio. (format: password)
  --studio-encryption-configuration: record # Configuration of the encryption method that is used for the studio. — shape: {keyArn?: any, keyType?: any}
  studio_name: string # The studio name that is used in the URL of the Nimble Studio portal when accessed by Nimble Studio users.
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
  user_role_arn: string # The IAM role that studio users will assume when logging in to the Nimble Studio portal.
]: any -> record<studio: record<adminRoleArn: record, arn: record, createdAt: record, displayName: record, homeRegion: record, ssoClientId: record, state: record, statusCode: record, statusMessage: record, studioEncryptionConfiguration: record<keyArn: record, keyType: record>, studioId: record, studioName: record, studioUrl: record, tags: record, updatedAt: record, userRoleArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2020-08-01/studios")
  let req_body = {"adminRoleArn": $admin_role_arn, "displayName": $display_name, "studioEncryptionConfiguration": $studio_encryption_configuration, "studioName": $studio_name, "tags": $tags, "userRoleArn": $user_role_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List studios in your Amazon Web Services accounts in the requested Amazon Web Services Region.
#
# GET /2020-08-01/studios
# operationId: ListStudios
export def "2020-08-01-studios list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<nextToken: record, studios: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2020-08-01/studios" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token} | compact), body: null}
}

# Creates a studio component resource.
#
# POST /2020-08-01/studios/{studioId}/studio-components
# operationId: CreateStudioComponent
# --configuration shape: {activeDirectoryConfiguration?: any, computeFarmConfiguration?: any, licenseServiceConfiguration?: any, sharedFileSystemConfiguration?: any}
# --initializationScripts item shape: {launchProfileProtocolVersion?: any, platform?: any, runContext?: any, script?: any}
# --scriptParameters item shape: {key?: any, value?: any}
export def "2020-08-01-studios-studio-components create" [
  studio_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --configuration: record # The configuration of the studio component, based on component type. — shape: {activeDirectoryConfiguration?: any, computeFarmConfiguration?: any, licenseServiceConfiguration?: any, sharedFileSystemConfiguration?: any}
  --description: string # The description. (format: password)
  --ec2-security-group-ids: list<string> # The EC2 security groups that control access to the studio component.
  --initialization-scripts: list # Initialization scripts for studio components. — item shape: {launchProfileProtocolVersion?: any, platform?: any, runContext?: any, script?: any}
  name: string # The name for the studio component. (format: password)
  --runtime-role-arn: string # An IAM role attached to a Studio Component that gives the studio component access to Amazon Web Services resources at anytime while the instance is running.
  --script-parameters: list # Parameters for the studio component scripts. — item shape: {key?: any, value?: any}
  --secure-initialization-role-arn: string # An IAM role attached to Studio Component when the system initialization script runs which give the studio component access to Amazon Web Services resources when the system initialization script runs.
  --subtype: string@subtype-completer # The specific subtype of a studio component.
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
  type: string@type-completer # The type of the studio component.
]: any -> record<studioComponent: record<arn: record, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: record, createdBy: record, description: record, ec2SecurityGroupIds: record, initializationScripts: record, name: record, runtimeRoleArn: record, scriptParameters: record, secureInitializationRoleArn: record, state: record, statusCode: record, statusMessage: record, studioComponentId: record, subtype: record, tags: record, type: record, updatedAt: record, updatedBy: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/studio-components"))
  let req_body = {"configuration": $configuration, "description": $description, "ec2SecurityGroupIds": $ec2_security_group_ids, "initializationScripts": $initialization_scripts, "name": $name, "runtimeRoleArn": $runtime_role_arn, "scriptParameters": $script_parameters, "secureInitializationRoleArn": $secure_initialization_role_arn, "subtype": $subtype, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the StudioComponents in a studio.
#
# GET /2020-08-01/studios/{studioId}/studio-components
# operationId: ListStudioComponents
export def "2020-08-01-studios-studio-components list" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The max number of results to return in the response.
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --states: list # Filters the request to studio components that are in one of the given states.
  --types: list # Filters the request to studio components that are of one of the given types.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<nextToken: record, studioComponents: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "states" $states "multi") (serialize-qp "types" $types "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/studio-components") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "states": $states, "types": $types} | compact), body: null}
}

# Permanently delete a launch profile.
#
# DELETE /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}
# operationId: DeleteLaunchProfile
export def "2020-08-01-studios-launch-profiles delete" [
  studio_id: string
  launch_profile_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> record<launchProfile: record<arn: record, createdAt: record, createdBy: record, description: record, ec2SubnetIds: record, launchProfileId: record, launchProfileProtocolVersions: record, name: record, state: record, statusCode: record, statusMessage: record, streamConfiguration: record<automaticTerminationMode: record, clipboardMode: record, ec2InstanceTypes: record, maxSessionLengthInMinutes: record, maxStoppedSessionLengthInMinutes: record, sessionBackup: record, sessionPersistenceMode: record, sessionStorage: record, streamingImageIds: record, volumeConfiguration: record>, studioComponentIds: record, tags: record, updatedAt: record, updatedBy: record, validationResults: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a launch profile.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}
# operationId: GetLaunchProfile
export def "2020-08-01-studios-launch-profiles get" [
  studio_id: string
  launch_profile_id: string
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
]: nothing -> record<launchProfile: record<arn: record, createdAt: record, createdBy: record, description: record, ec2SubnetIds: record, launchProfileId: record, launchProfileProtocolVersions: record, name: record, state: record, statusCode: record, statusMessage: record, streamConfiguration: record<automaticTerminationMode: record, clipboardMode: record, ec2InstanceTypes: record, maxSessionLengthInMinutes: record, maxStoppedSessionLengthInMinutes: record, sessionBackup: record, sessionPersistenceMode: record, sessionStorage: record, streamingImageIds: record, volumeConfiguration: record>, studioComponentIds: record, tags: record, updatedAt: record, updatedBy: record, validationResults: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a launch profile.
#
# PATCH /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}
# operationId: UpdateLaunchProfile
# --streamConfiguration shape: {automaticTerminationMode?: any, clipboardMode?: any, ec2InstanceTypes?: any, maxSessionLengthInMinutes?: any, maxStoppedSessionLengthInMinutes?: any, sessionBackup?: any, sessionPersistenceMode?: any, sessionStorage?: any, streamingImageIds?: any, volumeConfiguration?: any}
export def "2020-08-01-studios-launch-profiles update" [
  studio_id: string
  launch_profile_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --description: string # A human-readable description of the launch profile. (format: password)
  --launch-profile-protocol-versions: list<string> # The version number of the protocol that is used by the launch profile. The only valid version is "2021-03-31".
  --name: string # The name for the launch profile. (format: password)
  --stream-configuration: record # Configuration for streaming workstations created using this launch profile. — shape: {automaticTerminationMode?: any, clipboardMode?: any, ec2InstanceTypes?: any, maxSessionLengthInMinutes?: any, maxStoppedSessionLengthInMinutes?: any, sessionBackup?: any, sessionPersistenceMode?: any, sessionStorage?: any, streamingImageIds?: any, volumeConfiguration?: any}
  --studio-component-ids: list<string> # Unique identifiers for a collection of studio components that can be used with this launch profile.
]: any -> record<launchProfile: record<arn: record, createdAt: record, createdBy: record, description: record, ec2SubnetIds: record, launchProfileId: record, launchProfileProtocolVersions: record, name: record, state: record, statusCode: record, statusMessage: record, streamConfiguration: record<automaticTerminationMode: record, clipboardMode: record, ec2InstanceTypes: record, maxSessionLengthInMinutes: record, maxStoppedSessionLengthInMinutes: record, sessionBackup: record, sessionPersistenceMode: record, sessionStorage: record, streamingImageIds: record, volumeConfiguration: record>, studioComponentIds: record, tags: record, updatedAt: record, updatedBy: record, validationResults: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}"))
  let req_body = {"description": $description, "launchProfileProtocolVersions": $launch_profile_protocol_versions, "name": $name, "streamConfiguration": $stream_configuration, "studioComponentIds": $studio_component_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a user from launch profile membership.
#
# DELETE /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership/{principalId}
# operationId: DeleteLaunchProfileMember
export def "2020-08-01-studios-launch-profiles-membership delete-member" [
  studio_id: string
  launch_profile_id: string
  principal_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  if ($principal_id | is-empty) { error make --unspanned { msg: "path parameter 'principalId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id), principal_id: (encode-path-segment $principal_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/membership/{principal_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a user persona in launch profile membership.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership/{principalId}
# operationId: GetLaunchProfileMember
export def "2020-08-01-studios-launch-profiles-membership get-member" [
  studio_id: string
  launch_profile_id: string
  principal_id: string
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
]: nothing -> record<member: record<identityStoreId: record, persona: record, principalId: record, sid: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  if ($principal_id | is-empty) { error make --unspanned { msg: "path parameter 'principalId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id), principal_id: (encode-path-segment $principal_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/membership/{principal_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a user persona in launch profile membership.
#
# PATCH /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership/{principalId}
# operationId: UpdateLaunchProfileMember
export def "2020-08-01-studios-launch-profiles-membership update-member" [
  studio_id: string
  launch_profile_id: string
  principal_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  persona: string@persona-completer # The persona.
]: any -> record<member: record<identityStoreId: record, persona: record, principalId: record, sid: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  if ($principal_id | is-empty) { error make --unspanned { msg: "path parameter 'principalId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id), principal_id: (encode-path-segment $principal_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/membership/{principal_id}"))
  let req_body = {"persona": $persona} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete streaming image.
#
# DELETE /2020-08-01/studios/{studioId}/streaming-images/{streamingImageId}
# operationId: DeleteStreamingImage
export def "2020-08-01-studios-streaming-images delete" [
  studio_id: string
  streaming_image_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> record<streamingImage: record<arn: record, description: record, ec2ImageId: record, encryptionConfiguration: record<keyArn: record, keyType: record>, eulaIds: record, name: record, owner: record, platform: record, state: record, statusCode: record, statusMessage: record, streamingImageId: record, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($streaming_image_id | is-empty) { error make --unspanned { msg: "path parameter 'streamingImageId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), streaming_image_id: (encode-path-segment $streaming_image_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-images/{streaming_image_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get streaming image.
#
# GET /2020-08-01/studios/{studioId}/streaming-images/{streamingImageId}
# operationId: GetStreamingImage
export def "2020-08-01-studios-streaming-images get" [
  studio_id: string
  streaming_image_id: string
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
]: nothing -> record<streamingImage: record<arn: record, description: record, ec2ImageId: record, encryptionConfiguration: record<keyArn: record, keyType: record>, eulaIds: record, name: record, owner: record, platform: record, state: record, statusCode: record, statusMessage: record, streamingImageId: record, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($streaming_image_id | is-empty) { error make --unspanned { msg: "path parameter 'streamingImageId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), streaming_image_id: (encode-path-segment $streaming_image_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-images/{streaming_image_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update streaming image.
#
# PATCH /2020-08-01/studios/{studioId}/streaming-images/{streamingImageId}
# operationId: UpdateStreamingImage
export def "2020-08-01-studios-streaming-images update" [
  studio_id: string
  streaming_image_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --description: string # The description. (format: password)
  --name: string # A friendly name for a streaming image resource. (format: password)
]: any -> record<streamingImage: record<arn: record, description: record, ec2ImageId: record, encryptionConfiguration: record<keyArn: record, keyType: record>, eulaIds: record, name: record, owner: record, platform: record, state: record, statusCode: record, statusMessage: record, streamingImageId: record, tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($streaming_image_id | is-empty) { error make --unspanned { msg: "path parameter 'streamingImageId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), streaming_image_id: (encode-path-segment $streaming_image_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-images/{streaming_image_id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes streaming session resource. After invoking this operation, use GetStreamingSession to poll the resource until it transitions to a DELETED state. A streaming session will count against your streaming session quota until it is marked DELETED.
#
# DELETE /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}
# operationId: DeleteStreamingSession
export def "2020-08-01-studios-streaming-sessions delete" [
  studio_id: string
  session_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> record<session: record<arn: record, automaticTerminationMode: record, backupMode: record, createdAt: record, createdBy: record, ec2InstanceType: record, launchProfileId: record, maxBackupsToRetain: record, ownedBy: record, sessionId: record, sessionPersistenceMode: record, startedAt: record, startedBy: record, startedFromBackupId: record, state: record, statusCode: record, statusMessage: record, stopAt: record, stoppedAt: record, stoppedBy: record, streamingImageId: record, tags: record, terminateAt: record, updatedAt: record, updatedBy: record, volumeConfiguration: record<iops: record, size: record, throughput: record>, volumeRetentionMode: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), session_id: (encode-path-segment $session_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions/{session_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets StreamingSession resource. Invoke this operation to poll for a streaming session state while creating or deleting a session.
#
# GET /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}
# operationId: GetStreamingSession
export def "2020-08-01-studios-streaming-sessions get" [
  studio_id: string
  session_id: string
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
]: nothing -> record<session: record<arn: record, automaticTerminationMode: record, backupMode: record, createdAt: record, createdBy: record, ec2InstanceType: record, launchProfileId: record, maxBackupsToRetain: record, ownedBy: record, sessionId: record, sessionPersistenceMode: record, startedAt: record, startedBy: record, startedFromBackupId: record, state: record, statusCode: record, statusMessage: record, stopAt: record, stoppedAt: record, stoppedBy: record, streamingImageId: record, tags: record, terminateAt: record, updatedAt: record, updatedBy: record, volumeConfiguration: record<iops: record, size: record, throughput: record>, volumeRetentionMode: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), session_id: (encode-path-segment $session_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions/{session_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a studio resource.
#
# DELETE /2020-08-01/studios/{studioId}
# operationId: DeleteStudio
export def "2020-08-01-studios delete" [
  studio_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> record<studio: record<adminRoleArn: record, arn: record, createdAt: record, displayName: record, homeRegion: record, ssoClientId: record, state: record, statusCode: record, statusMessage: record, studioEncryptionConfiguration: record<keyArn: record, keyType: record>, studioId: record, studioName: record, studioUrl: record, tags: record, updatedAt: record, userRoleArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a studio resource.
#
# GET /2020-08-01/studios/{studioId}
# operationId: GetStudio
export def "2020-08-01-studios get" [
  studio_id: string
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
]: nothing -> record<studio: record<adminRoleArn: record, arn: record, createdAt: record, displayName: record, homeRegion: record, ssoClientId: record, state: record, statusCode: record, statusMessage: record, studioEncryptionConfiguration: record<keyArn: record, keyType: record>, studioId: record, studioName: record, studioUrl: record, tags: record, updatedAt: record, userRoleArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a Studio resource. Currently, this operation only supports updating the displayName of your studio.
#
# PATCH /2020-08-01/studios/{studioId}
# operationId: UpdateStudio
export def "2020-08-01-studios update" [
  studio_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --admin-role-arn: string # The IAM role that Studio Admins will assume when logging in to the Nimble Studio portal.
  --display-name: string # A friendly name for the studio. (format: password)
  --user-role-arn: string # The IAM role that Studio Users will assume when logging in to the Nimble Studio portal.
]: any -> record<studio: record<adminRoleArn: record, arn: record, createdAt: record, displayName: record, homeRegion: record, ssoClientId: record, state: record, statusCode: record, statusMessage: record, studioEncryptionConfiguration: record<keyArn: record, keyType: record>, studioId: record, studioName: record, studioUrl: record, tags: record, updatedAt: record, userRoleArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}"))
  let req_body = {"adminRoleArn": $admin_role_arn, "displayName": $display_name, "userRoleArn": $user_role_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a studio component resource.
#
# DELETE /2020-08-01/studios/{studioId}/studio-components/{studioComponentId}
# operationId: DeleteStudioComponent
export def "2020-08-01-studios-studio-components delete" [
  studio_id: string
  studio_component_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> record<studioComponent: record<arn: record, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: record, createdBy: record, description: record, ec2SecurityGroupIds: record, initializationScripts: record, name: record, runtimeRoleArn: record, scriptParameters: record, secureInitializationRoleArn: record, state: record, statusCode: record, statusMessage: record, studioComponentId: record, subtype: record, tags: record, type: record, updatedAt: record, updatedBy: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($studio_component_id | is-empty) { error make --unspanned { msg: "path parameter 'studioComponentId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), studio_component_id: (encode-path-segment $studio_component_id)} | format pattern "/2020-08-01/studios/{studio_id}/studio-components/{studio_component_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a studio component resource.
#
# GET /2020-08-01/studios/{studioId}/studio-components/{studioComponentId}
# operationId: GetStudioComponent
export def "2020-08-01-studios-studio-components get" [
  studio_id: string
  studio_component_id: string
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
]: nothing -> record<studioComponent: record<arn: record, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: record, createdBy: record, description: record, ec2SecurityGroupIds: record, initializationScripts: record, name: record, runtimeRoleArn: record, scriptParameters: record, secureInitializationRoleArn: record, state: record, statusCode: record, statusMessage: record, studioComponentId: record, subtype: record, tags: record, type: record, updatedAt: record, updatedBy: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($studio_component_id | is-empty) { error make --unspanned { msg: "path parameter 'studioComponentId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), studio_component_id: (encode-path-segment $studio_component_id)} | format pattern "/2020-08-01/studios/{studio_id}/studio-components/{studio_component_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a studio component resource.
#
# PATCH /2020-08-01/studios/{studioId}/studio-components/{studioComponentId}
# operationId: UpdateStudioComponent
# --configuration shape: {activeDirectoryConfiguration?: any, computeFarmConfiguration?: any, licenseServiceConfiguration?: any, sharedFileSystemConfiguration?: any}
# --initializationScripts item shape: {launchProfileProtocolVersion?: any, platform?: any, runContext?: any, script?: any}
# --scriptParameters item shape: {key?: any, value?: any}
export def "2020-08-01-studios-studio-components update" [
  studio_id: string
  studio_component_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --configuration: record # The configuration of the studio component, based on component type. — shape: {activeDirectoryConfiguration?: any, computeFarmConfiguration?: any, licenseServiceConfiguration?: any, sharedFileSystemConfiguration?: any}
  --description: string # The description. (format: password)
  --ec2-security-group-ids: list<string> # The EC2 security groups that control access to the studio component.
  --initialization-scripts: list # Initialization scripts for studio components. — item shape: {launchProfileProtocolVersion?: any, platform?: any, runContext?: any, script?: any}
  --name: string # The name for the studio component. (format: password)
  --runtime-role-arn: string # An IAM role attached to a Studio Component that gives the studio component access to Amazon Web Services resources at anytime while the instance is running.
  --script-parameters: list # Parameters for the studio component scripts. — item shape: {key?: any, value?: any}
  --secure-initialization-role-arn: string # An IAM role attached to Studio Component when the system initialization script runs which give the studio component access to Amazon Web Services resources when the system initialization script runs.
  --subtype: string@subtype-completer # The specific subtype of a studio component.
  --type: string@type-completer # The type of the studio component.
]: any -> record<studioComponent: record<arn: record, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: record, createdBy: record, description: record, ec2SecurityGroupIds: record, initializationScripts: record, name: record, runtimeRoleArn: record, scriptParameters: record, secureInitializationRoleArn: record, state: record, statusCode: record, statusMessage: record, studioComponentId: record, subtype: record, tags: record, type: record, updatedAt: record, updatedBy: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($studio_component_id | is-empty) { error make --unspanned { msg: "path parameter 'studioComponentId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), studio_component_id: (encode-path-segment $studio_component_id)} | format pattern "/2020-08-01/studios/{studio_id}/studio-components/{studio_component_id}"))
  let req_body = {"configuration": $configuration, "description": $description, "ec2SecurityGroupIds": $ec2_security_group_ids, "initializationScripts": $initialization_scripts, "name": $name, "runtimeRoleArn": $runtime_role_arn, "scriptParameters": $script_parameters, "secureInitializationRoleArn": $secure_initialization_role_arn, "subtype": $subtype, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a user from studio membership.
#
# DELETE /2020-08-01/studios/{studioId}/membership/{principalId}
# operationId: DeleteStudioMember
export def "2020-08-01-studios-membership delete-member" [
  studio_id: string
  principal_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($principal_id | is-empty) { error make --unspanned { msg: "path parameter 'principalId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), principal_id: (encode-path-segment $principal_id)} | format pattern "/2020-08-01/studios/{studio_id}/membership/{principal_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a user's membership in a studio.
#
# GET /2020-08-01/studios/{studioId}/membership/{principalId}
# operationId: GetStudioMember
export def "2020-08-01-studios-membership get-member" [
  studio_id: string
  principal_id: string
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
]: nothing -> record<member: record<identityStoreId: record, persona: record, principalId: record, sid: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($principal_id | is-empty) { error make --unspanned { msg: "path parameter 'principalId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), principal_id: (encode-path-segment $principal_id)} | format pattern "/2020-08-01/studios/{studio_id}/membership/{principal_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get EULA.
#
# GET /2020-08-01/eulas/{eulaId}
# operationId: GetEula
export def "2020-08-01-eulas get" [
  eula_id: string
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
]: nothing -> record<eula: record<content: record, createdAt: record, eulaId: record, name: record, updatedAt: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($eula_id | is-empty) { error make --unspanned { msg: "path parameter 'eulaId' must be non-empty" } }
  let full_url = (build-url $base ({eula_id: (encode-path-segment $eula_id)} | format pattern "/2020-08-01/eulas/{eula_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Launch profile details include the launch profile resource and summary information of resources that are used by, or available to, the launch profile. This includes the name and description of all studio components used by the launch profiles, and the name and description of streaming images that can be used with this launch profile.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/details
# operationId: GetLaunchProfileDetails
export def "2020-08-01-studios-launch-profiles-details get" [
  studio_id: string
  launch_profile_id: string
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
]: nothing -> record<launchProfile: record<arn: record, createdAt: record, createdBy: record, description: record, ec2SubnetIds: record, launchProfileId: record, launchProfileProtocolVersions: record, name: record, state: record, statusCode: record, statusMessage: record, streamConfiguration: record<automaticTerminationMode: record, clipboardMode: record, ec2InstanceTypes: record, maxSessionLengthInMinutes: record, maxStoppedSessionLengthInMinutes: record, sessionBackup: record, sessionPersistenceMode: record, sessionStorage: record, streamingImageIds: record, volumeConfiguration: record>, studioComponentIds: record, tags: record, updatedAt: record, updatedBy: record, validationResults: record>, streamingImages: record, studioComponentSummaries: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/details"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a launch profile initialization.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/init
# operationId: GetLaunchProfileInitialization
export def "2020-08-01-studios-launch-profiles-init get-initialization" [
  studio_id: string
  launch_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --launch-profile-protocol-versions: list # The launch profile protocol versions supported by the client.
  --launch-purpose: string # The launch purpose.
  --platform: string # The platform where this Launch Profile will be used, either Windows or Linux.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<launchProfileInitialization: record<activeDirectory: record<computerAttributes: record, directoryId: record, directoryName: record, dnsIpAddresses: record, organizationalUnitDistinguishedName: record, studioComponentId: record, studioComponentName: record>, ec2SecurityGroupIds: record, launchProfileId: record, launchProfileProtocolVersion: record, launchPurpose: record, name: record, platform: record, systemInitializationScripts: record, userInitializationScripts: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  let qp = [(serialize-qp "launchProfileProtocolVersions" $launch_profile_protocol_versions "multi") (serialize-qp "launchPurpose" $launch_purpose "scalar") (serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/init") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"launchProfileProtocolVersions": $launch_profile_protocol_versions, "launchPurpose": $launch_purpose, "platform": $platform} | compact), body: null}
}

# Gets StreamingSessionBackup resource. Invoke this operation to poll for a streaming session backup while stopping a streaming session.
#
# GET /2020-08-01/studios/{studioId}/streaming-session-backups/{backupId}
# operationId: GetStreamingSessionBackup
export def "2020-08-01-studios-streaming-session-backups get" [
  studio_id: string
  backup_id: string
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
]: nothing -> record<streamingSessionBackup: record<arn: record, backupId: record, createdAt: record, launchProfileId: record, ownedBy: record, sessionId: record, state: string, statusCode: record, statusMessage: record, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($backup_id | is-empty) { error make --unspanned { msg: "path parameter 'backupId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), backup_id: (encode-path-segment $backup_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-session-backups/{backup_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a StreamingSessionStream for a streaming session. Invoke this operation to poll the resource after invoking CreateStreamingSessionStream. After the StreamingSessionStream changes to the READY state, the url property will contain a stream to be used with the DCV streaming client.
#
# GET /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/streams/{streamId}
# operationId: GetStreamingSessionStream
export def "2020-08-01-studios-streaming-sessions-streams get" [
  studio_id: string
  session_id: string
  stream_id: string
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
]: nothing -> record<stream: record<createdAt: record, createdBy: record, expiresAt: record, ownedBy: record, state: record, statusCode: record, streamId: record, url: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  if ($stream_id | is-empty) { error make --unspanned { msg: "path parameter 'streamId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), session_id: (encode-path-segment $session_id), stream_id: (encode-path-segment $stream_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions/{session_id}/streams/{stream_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List EULAs.
#
# GET /2020-08-01/eulas
# operationId: ListEulas
export def "2020-08-01-eulas list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --eula-ids: list # The list of EULA IDs that should be returned
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<eulas: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eulaIds" $eula_ids "multi") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2020-08-01/eulas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"eulaIds": $eula_ids, "nextToken": $next_token} | compact), body: null}
}

# Get all users in a given launch profile membership.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership
# operationId: ListLaunchProfileMembers
export def "2020-08-01-studios-launch-profiles-membership list-members" [
  studio_id: string
  launch_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The max number of results to return in the response.
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<members: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/membership") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Add/update users with given persona to launch profile membership.
#
# POST /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership
# operationId: PutLaunchProfileMembers
# --members item shape: {persona: any, principalId: any}
export def "2020-08-01-studios-launch-profiles-membership update-members" [
  studio_id: string
  launch_profile_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  identity_store_id: string # The ID of the identity store.
  members: list # A list of members. — item shape: {persona: any, principalId: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/membership"))
  let req_body = {"identityStoreId": $identity_store_id, "members": $members} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the backups of a streaming session in a studio.
#
# GET /2020-08-01/studios/{studioId}/streaming-session-backups
# operationId: ListStreamingSessionBackups
export def "2020-08-01-studios-streaming-session-backups list" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --owned-by: string # The user ID of the user that owns the streaming session.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<nextToken: record, streamingSessionBackups: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "ownedBy" $owned_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-session-backups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token, "ownedBy": $owned_by} | compact), body: null}
}

# Get all users in a given studio membership. ListStudioMembers only returns admin members.
#
# GET /2020-08-01/studios/{studioId}/membership
# operationId: ListStudioMembers
export def "2020-08-01-studios-membership list-members" [
  studio_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The max number of results to return in the response.
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<members: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/membership") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# Add/update users with given persona to studio membership.
#
# POST /2020-08-01/studios/{studioId}/membership
# operationId: PutStudioMembers
# --members item shape: {persona: any, principalId: any}
export def "2020-08-01-studios-membership update-members" [
  studio_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  identity_store_id: string # The ID of the identity store.
  members: list # A list of members. — item shape: {persona: any, principalId: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/membership"))
  let req_body = {"identityStoreId": $identity_store_id, "members": $members} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the tags for a resource, given its Amazon Resource Names (ARN). This operation supports ARNs for all resource types in Nimble Studio that support tags, including studio, studio component, launch profile, streaming image, and streaming session. All resources that can be tagged will contain an ARN property, so you do not have to create this ARN yourself.
#
# GET /2020-08-01/tags/{resourceArn}
# operationId: ListTagsForResource
export def "2020-08-01-tags list-for-resource" [
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
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/2020-08-01/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates tags for a resource, given its ARN.
#
# POST /2020-08-01/tags/{resourceArn}
# operationId: TagResource
export def "2020-08-01-tags tag-resource" [
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
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/2020-08-01/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Transitions sessions from the STOPPED state into the READY state. The START_IN_PROGRESS state is the intermediate state between the STOPPED and READY states.
#
# POST /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/start
# operationId: StartStreamingSession
export def "2020-08-01-studios-streaming-sessions-start start" [
  studio_id: string
  session_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --backup-id: string # The ID of the backup.
]: any -> record<session: record<arn: record, automaticTerminationMode: record, backupMode: record, createdAt: record, createdBy: record, ec2InstanceType: record, launchProfileId: record, maxBackupsToRetain: record, ownedBy: record, sessionId: record, sessionPersistenceMode: record, startedAt: record, startedBy: record, startedFromBackupId: record, state: record, statusCode: record, statusMessage: record, stopAt: record, stoppedAt: record, stoppedBy: record, streamingImageId: record, tags: record, terminateAt: record, updatedAt: record, updatedBy: record, volumeConfiguration: record<iops: record, size: record, throughput: record>, volumeRetentionMode: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), session_id: (encode-path-segment $session_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions/{session_id}/start"))
  let req_body = {"backupId": $backup_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Repairs the IAM Identity Center configuration for a given studio. If the studio has a valid IAM Identity Center configuration currently associated with it, this operation will fail with a validation error. If the studio does not have a valid IAM Identity Center configuration currently associated with it, then a new IAM Identity Center application is created for the studio and the studio is changed to the READY state. After the IAM Identity Center application is repaired, you must use the Amazon Nimble Studio console to add administrators and users to your studio.
#
# PUT /2020-08-01/studios/{studioId}/sso-configuration
# operationId: StartStudioSSOConfigurationRepair
export def "2020-08-01-studios-sso-configuration start-repair" [
  studio_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
]: nothing -> record<studio: record<adminRoleArn: record, arn: record, createdAt: record, displayName: record, homeRegion: record, ssoClientId: record, state: record, statusCode: record, statusMessage: record, studioEncryptionConfiguration: record<keyArn: record, keyType: record>, studioId: record, studioName: record, studioUrl: record, tags: record, updatedAt: record, userRoleArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/sso-configuration"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Transitions sessions from the READY state into the STOPPED state. The STOP_IN_PROGRESS state is the intermediate state between the READY and STOPPED states.
#
# POST /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/stop
# operationId: StopStreamingSession
export def "2020-08-01-studios-streaming-sessions-stop stop" [
  studio_id: string
  session_id: string
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
  --x-amz-client-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request. If you don’t specify a client token, the Amazon Web Services SDK automatically generates a client token and uses it for the request to ensure idempotency.
  --volume-retention-mode: string@volume-retention-mode-completer # Adds additional instructions to a streaming session stop action to either retain the EBS volumes or delete the EBS volumes.
]: any -> record<session: record<arn: record, automaticTerminationMode: record, backupMode: record, createdAt: record, createdBy: record, ec2InstanceType: record, launchProfileId: record, maxBackupsToRetain: record, ownedBy: record, sessionId: record, sessionPersistenceMode: record, startedAt: record, startedBy: record, startedFromBackupId: record, state: record, statusCode: record, statusMessage: record, stopAt: record, stoppedAt: record, stoppedBy: record, streamingImageId: record, tags: record, terminateAt: record, updatedAt: record, updatedBy: record, volumeConfiguration: record<iops: record, size: record, throughput: record>, volumeRetentionMode: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), session_id: (encode-path-segment $session_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions/{session_id}/stop"))
  let req_body = {"volumeRetentionMode": $volume_retention_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the tags for a resource.
#
# DELETE /2020-08-01/tags/{resourceArn}
# operationId: UntagResource
export def "2020-08-01-tags untag-resource" [
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
  --tag-keys: list # One or more tag keys. Specify only the tag keys, not the tag values.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/2020-08-01/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}
