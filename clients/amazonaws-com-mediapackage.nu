# Auto-generated client for AWS Elemental MediaPackage v2017-10-12
# Source: https://api.apis.guru/v2/specs/amazonaws.com/mediapackage/2017-10-12/openapi.json
# Auth: --token flag or $env.AWS_ELEMENTAL_MEDIAPACKAGE_TOKEN

const BASE_URL = "http://mediapackage.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_ELEMENTAL_MEDIAPACKAGE_TOKEN | default "" }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["http://mediapackage.us-east-1.amazonaws.com" "http://mediapackage.us-east-2.amazonaws.com" "http://mediapackage.us-west-1.amazonaws.com" "http://mediapackage.us-west-2.amazonaws.com" "http://mediapackage.us-gov-west-1.amazonaws.com" "http://mediapackage.us-gov-east-1.amazonaws.com" "http://mediapackage.ca-central-1.amazonaws.com" "http://mediapackage.eu-north-1.amazonaws.com" "http://mediapackage.eu-west-1.amazonaws.com" "http://mediapackage.eu-west-2.amazonaws.com" "http://mediapackage.eu-west-3.amazonaws.com" "http://mediapackage.eu-central-1.amazonaws.com" "http://mediapackage.eu-south-1.amazonaws.com" "http://mediapackage.af-south-1.amazonaws.com" "http://mediapackage.ap-northeast-1.amazonaws.com" "http://mediapackage.ap-northeast-2.amazonaws.com" "http://mediapackage.ap-northeast-3.amazonaws.com" "http://mediapackage.ap-southeast-1.amazonaws.com" "http://mediapackage.ap-southeast-2.amazonaws.com" "http://mediapackage.ap-east-1.amazonaws.com" "http://mediapackage.ap-south-1.amazonaws.com" "http://mediapackage.sa-east-1.amazonaws.com" "http://mediapackage.me-south-1.amazonaws.com" "https://mediapackage.us-east-1.amazonaws.com" "https://mediapackage.us-east-2.amazonaws.com" "https://mediapackage.us-west-1.amazonaws.com" "https://mediapackage.us-west-2.amazonaws.com" "https://mediapackage.us-gov-west-1.amazonaws.com" "https://mediapackage.us-gov-east-1.amazonaws.com" "https://mediapackage.ca-central-1.amazonaws.com" "https://mediapackage.eu-north-1.amazonaws.com" "https://mediapackage.eu-west-1.amazonaws.com" "https://mediapackage.eu-west-2.amazonaws.com" "https://mediapackage.eu-west-3.amazonaws.com" "https://mediapackage.eu-central-1.amazonaws.com" "https://mediapackage.eu-south-1.amazonaws.com" "https://mediapackage.af-south-1.amazonaws.com" "https://mediapackage.ap-northeast-1.amazonaws.com" "https://mediapackage.ap-northeast-2.amazonaws.com" "https://mediapackage.ap-northeast-3.amazonaws.com" "https://mediapackage.ap-southeast-1.amazonaws.com" "https://mediapackage.ap-southeast-2.amazonaws.com" "https://mediapackage.ap-east-1.amazonaws.com" "https://mediapackage.ap-south-1.amazonaws.com" "https://mediapackage.sa-east-1.amazonaws.com" "https://mediapackage.me-south-1.amazonaws.com" "http://mediapackage.cn-north-1.amazonaws.com.cn" "http://mediapackage.cn-northwest-1.amazonaws.com.cn" "https://mediapackage.cn-north-1.amazonaws.com.cn" "https://mediapackage.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def origination-completer [] { ["ALLOW" "DENY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "channels-configure-logs logs" } } | get name | first)
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

# Changes the Channel's properities to configure log subscription
#
# PUT /channels/{id}/configure_logs
# operationId: ConfigureLogs
# --egressAccessLogs shape: {LogGroupName?: any}
# --ingressAccessLogs shape: {LogGroupName?: any}
export def "channels-configure-logs logs" [
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
  --egress-access-logs: record # Configure egress access logging. — shape: {LogGroupName?: any}
  --ingress-access-logs: record # Configure ingress access logging. — shape: {LogGroupName?: any}
]: any -> record<Arn: record, CreatedAt: record, Description: record, EgressAccessLogs: record<LogGroupName: record>, HlsIngest: record<IngestEndpoints: record>, Id: record, IngressAccessLogs: record<LogGroupName: record>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/channels/{id}/configure_logs"))
  let req_body = {"egressAccessLogs": $egress_access_logs, "ingressAccessLogs": $ingress_access_logs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a new Channel.
#
# POST /channels
# operationId: CreateChannel
export def "channels create" [
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
  --description: string # A short text description of the Channel.
  id: string # The ID of the Channel. The ID must be unique within the region and it cannot be changed after a Channel is created.
  --tags: record # A collection of tags associated with a resource
]: any -> record<Arn: record, CreatedAt: record, Description: record, EgressAccessLogs: record<LogGroupName: record>, HlsIngest: record<IngestEndpoints: record>, Id: record, IngressAccessLogs: record<LogGroupName: record>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels")
  let req_body = {"description": $description, "id": $id, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a collection of Channels.
#
# GET /channels
# operationId: ListChannels
export def "channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # Upper bound on number of records to return.
  --next-token: string # A token used to resume pagination from the end of a previous request.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Channels: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates a new HarvestJob record.
#
# POST /harvest_jobs
# operationId: CreateHarvestJob
# --s3Destination shape: {BucketName?: any, ManifestKey?: any, RoleArn?: any}
export def "harvest-jobs create" [
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
  end_time: string # The end of the time-window which will be harvested
  id: string # The ID of the HarvestJob. The ID must be unique within the region and it cannot be changed after the HarvestJob is submitted
  origin_endpoint_id: string # The ID of the OriginEndpoint that the HarvestJob will harvest from. This cannot be changed after the HarvestJob is submitted.
  s3_destination: record # Configuration parameters for where in an S3 bucket to place the harvested content — shape: {BucketName?: any, ManifestKey?: any, RoleArn?: any}
  start_time: string # The start of the time-window which will be harvested
]: any -> record<Arn: record, ChannelId: record, CreatedAt: record, EndTime: record, Id: record, OriginEndpointId: record, S3Destination: record<BucketName: record, ManifestKey: record, RoleArn: record>, StartTime: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/harvest_jobs")
  let req_body = {"endTime": $end_time, "id": $id, "originEndpointId": $origin_endpoint_id, "s3Destination": $s3_destination, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a collection of HarvestJob records.
#
# GET /harvest_jobs
# operationId: ListHarvestJobs
export def "harvest-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-channel-id: string # When specified, the request will return only HarvestJobs associated with the given Channel ID.
  --include-status: string # When specified, the request will return only HarvestJobs in the given status.
  --max-results: int # The upper bound on the number of records to return.
  --next-token: string # A token used to resume pagination from the end of a previous request.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<HarvestJobs: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeChannelId" $include_channel_id "scalar") (serialize-qp "includeStatus" $include_status "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/harvest_jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includeChannelId": $include_channel_id, "includeStatus": $include_status, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates a new OriginEndpoint record.
#
# POST /origin_endpoints
# operationId: CreateOriginEndpoint
# --authorization shape: {CdnIdentifierSecret?: any, SecretsRoleArn?: any}
# --cmafPackage shape: {Encryption?: any, HlsManifests?: any, SegmentDurationSeconds?: any, SegmentPrefix?: any, StreamSelection?: any}
# --dashPackage shape: {AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeIframeOnlyStream?: any, ManifestLayout?: any, ManifestWindowSeconds?: any, MinBufferTimeSeconds?: any, MinUpdatePeriodSeconds?: any, PeriodTriggers?: any, Profile?: any, SegmentDurationSeconds?: any, SegmentTemplateFormat?: any, StreamSelection?: any, SuggestedPresentationDelaySeconds?: any, UtcTiming?: any, UtcTimingUri?: any}
# --hlsPackage shape: {AdMarkers?: any, AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeDvbSubtitles?: any, IncludeIframeOnlyStream?: any, PlaylistType?: any, PlaylistWindowSeconds?: any, ProgramDateTimeIntervalSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any, UseAudioRenditionGroup?: any}
# --mssPackage shape: {Encryption?: any, ManifestWindowSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any}
export def "origin-endpoints create" [
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
  --authorization: record # CDN Authorization credentials — shape: {CdnIdentifierSecret?: any, SecretsRoleArn?: any}
  channel_id: string # The ID of the Channel that the OriginEndpoint will be associated with. This cannot be changed after the OriginEndpoint is created.
  --cmaf-package: record # A Common Media Application Format (CMAF) packaging configuration. — shape: {Encryption?: any, HlsManifests?: any, SegmentDurationSeconds?: any, SegmentPrefix?: any, StreamSelection?: any}
  --dash-package: record # A Dynamic Adaptive Streaming over HTTP (DASH) packaging configuration. — shape: {AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeIframeOnlyStream?: any, ManifestLayout?: any, ManifestWindowSeconds?: any, MinBufferTimeSeconds?: any, MinUpdatePeriodSeconds?: any, PeriodTriggers?: any, Profile?: any, SegmentDurationSeconds?: any, SegmentTemplateFormat?: any, StreamSelection?: any, SuggestedPresentationDelaySeconds?: any, UtcTiming?: any, UtcTimingUri?: any}
  --description: string # A short text description of the OriginEndpoint.
  --hls-package: record # An HTTP Live Streaming (HLS) packaging configuration. — shape: {AdMarkers?: any, AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeDvbSubtitles?: any, IncludeIframeOnlyStream?: any, PlaylistType?: any, PlaylistWindowSeconds?: any, ProgramDateTimeIntervalSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any, UseAudioRenditionGroup?: any}
  id: string # The ID of the OriginEndpoint. The ID must be unique within the region and it cannot be changed after the OriginEndpoint is created.
  --manifest-name: string # A short string that will be used as the filename of the OriginEndpoint URL (defaults to "index").
  --mss-package: record # A Microsoft Smooth Streaming (MSS) packaging configuration. — shape: {Encryption?: any, ManifestWindowSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any}
  --origination: string@origination-completer # Control whether origination of video is allowed for this OriginEndpoint. If set to ALLOW, the OriginEndpoint may by requested, pursuant to any other form of access control. If set to DENY, the OriginEndpoint may not be requested. This can be helpful for Live to VOD harvesting, or for temporarily disabling origination
  --startover-window-seconds: int # Maximum duration (seconds) of content to retain for startover playback. If not specified, startover playback will be disabled for the OriginEndpoint.
  --tags: record # A collection of tags associated with a resource
  --time-delay-seconds: int # Amount of delay (seconds) to enforce on the playback of live content. If not specified, there will be no time delay in effect for the OriginEndpoint.
  --whitelist: list<string> # A list of source IP CIDR blocks that will be allowed to access the OriginEndpoint.
]: any -> record<Arn: record, Authorization: record<CdnIdentifierSecret: record, SecretsRoleArn: record>, ChannelId: record, CmafPackage: record<Encryption: record<ConstantInitializationVector: record, EncryptionMethod: record, KeyRotationIntervalSeconds: record, SpekeKeyProvider: record>, HlsManifests: record, SegmentDurationSeconds: record, SegmentPrefix: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>>, CreatedAt: record, DashPackage: record<AdTriggers: record, AdsOnDeliveryRestrictions: record, Encryption: record<KeyRotationIntervalSeconds: record, SpekeKeyProvider: record>, IncludeIframeOnlyStream: record, ManifestLayout: record, ManifestWindowSeconds: record, MinBufferTimeSeconds: record, MinUpdatePeriodSeconds: record, PeriodTriggers: record, Profile: record, SegmentDurationSeconds: record, SegmentTemplateFormat: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>, SuggestedPresentationDelaySeconds: record, UtcTiming: record, UtcTimingUri: record>, Description: record, HlsPackage: record<AdMarkers: record, AdTriggers: record, AdsOnDeliveryRestrictions: record, Encryption: record<ConstantInitializationVector: record, EncryptionMethod: record, KeyRotationIntervalSeconds: record, RepeatExtXKey: record, SpekeKeyProvider: record>, IncludeDvbSubtitles: record, IncludeIframeOnlyStream: record, PlaylistType: record, PlaylistWindowSeconds: record, ProgramDateTimeIntervalSeconds: record, SegmentDurationSeconds: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>, UseAudioRenditionGroup: record>, Id: record, ManifestName: record, MssPackage: record<Encryption: record<SpekeKeyProvider: record>, ManifestWindowSeconds: record, SegmentDurationSeconds: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>>, Origination: record, StartoverWindowSeconds: record, Tags: record, TimeDelaySeconds: record, Url: record, Whitelist: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/origin_endpoints")
  let req_body = {"authorization": $authorization, "channelId": $channel_id, "cmafPackage": $cmaf_package, "dashPackage": $dash_package, "description": $description, "hlsPackage": $hls_package, "id": $id, "manifestName": $manifest_name, "mssPackage": $mss_package, "origination": $origination, "startoverWindowSeconds": $startover_window_seconds, "tags": $tags, "timeDelaySeconds": $time_delay_seconds, "whitelist": $whitelist} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a collection of OriginEndpoint records.
#
# GET /origin_endpoints
# operationId: ListOriginEndpoints
export def "origin-endpoints list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-id: string # When specified, the request will return only OriginEndpoints associated with the given Channel ID.
  --max-results: int # The upper bound on the number of records to return.
  --next-token: string # A token used to resume pagination from the end of a previous request.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, OriginEndpoints: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channelId" $channel_id "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/origin_endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"channelId": $channel_id, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Deletes an existing Channel.
#
# DELETE /channels/{id}
# operationId: DeleteChannel
export def "channels delete" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/channels/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets details about a Channel.
#
# GET /channels/{id}
# operationId: DescribeChannel
export def "channels get" [
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
]: nothing -> record<Arn: record, CreatedAt: record, Description: record, EgressAccessLogs: record<LogGroupName: record>, HlsIngest: record<IngestEndpoints: record>, Id: record, IngressAccessLogs: record<LogGroupName: record>, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/channels/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an existing Channel.
#
# PUT /channels/{id}
# operationId: UpdateChannel
export def "channels update" [
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
  --description: string # A short text description of the Channel.
]: any -> record<Arn: record, CreatedAt: record, Description: record, EgressAccessLogs: record<LogGroupName: record>, HlsIngest: record<IngestEndpoints: record>, Id: record, IngressAccessLogs: record<LogGroupName: record>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/channels/{id}"))
  let req_body = {"description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an existing OriginEndpoint.
#
# DELETE /origin_endpoints/{id}
# operationId: DeleteOriginEndpoint
export def "origin-endpoints delete" [
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/origin_endpoints/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets details about an existing OriginEndpoint.
#
# GET /origin_endpoints/{id}
# operationId: DescribeOriginEndpoint
export def "origin-endpoints get" [
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
]: nothing -> record<Arn: record, Authorization: record<CdnIdentifierSecret: record, SecretsRoleArn: record>, ChannelId: record, CmafPackage: record<Encryption: record<ConstantInitializationVector: record, EncryptionMethod: record, KeyRotationIntervalSeconds: record, SpekeKeyProvider: record>, HlsManifests: record, SegmentDurationSeconds: record, SegmentPrefix: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>>, CreatedAt: record, DashPackage: record<AdTriggers: record, AdsOnDeliveryRestrictions: record, Encryption: record<KeyRotationIntervalSeconds: record, SpekeKeyProvider: record>, IncludeIframeOnlyStream: record, ManifestLayout: record, ManifestWindowSeconds: record, MinBufferTimeSeconds: record, MinUpdatePeriodSeconds: record, PeriodTriggers: record, Profile: record, SegmentDurationSeconds: record, SegmentTemplateFormat: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>, SuggestedPresentationDelaySeconds: record, UtcTiming: record, UtcTimingUri: record>, Description: record, HlsPackage: record<AdMarkers: record, AdTriggers: record, AdsOnDeliveryRestrictions: record, Encryption: record<ConstantInitializationVector: record, EncryptionMethod: record, KeyRotationIntervalSeconds: record, RepeatExtXKey: record, SpekeKeyProvider: record>, IncludeDvbSubtitles: record, IncludeIframeOnlyStream: record, PlaylistType: record, PlaylistWindowSeconds: record, ProgramDateTimeIntervalSeconds: record, SegmentDurationSeconds: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>, UseAudioRenditionGroup: record>, Id: record, ManifestName: record, MssPackage: record<Encryption: record<SpekeKeyProvider: record>, ManifestWindowSeconds: record, SegmentDurationSeconds: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>>, Origination: record, StartoverWindowSeconds: record, Tags: record, TimeDelaySeconds: record, Url: record, Whitelist: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/origin_endpoints/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an existing OriginEndpoint.
#
# PUT /origin_endpoints/{id}
# operationId: UpdateOriginEndpoint
# --authorization shape: {CdnIdentifierSecret?: any, SecretsRoleArn?: any}
# --cmafPackage shape: {Encryption?: any, HlsManifests?: any, SegmentDurationSeconds?: any, SegmentPrefix?: any, StreamSelection?: any}
# --dashPackage shape: {AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeIframeOnlyStream?: any, ManifestLayout?: any, ManifestWindowSeconds?: any, MinBufferTimeSeconds?: any, MinUpdatePeriodSeconds?: any, PeriodTriggers?: any, Profile?: any, SegmentDurationSeconds?: any, SegmentTemplateFormat?: any, StreamSelection?: any, SuggestedPresentationDelaySeconds?: any, UtcTiming?: any, UtcTimingUri?: any}
# --hlsPackage shape: {AdMarkers?: any, AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeDvbSubtitles?: any, IncludeIframeOnlyStream?: any, PlaylistType?: any, PlaylistWindowSeconds?: any, ProgramDateTimeIntervalSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any, UseAudioRenditionGroup?: any}
# --mssPackage shape: {Encryption?: any, ManifestWindowSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any}
export def "origin-endpoints update" [
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
  --authorization: record # CDN Authorization credentials — shape: {CdnIdentifierSecret?: any, SecretsRoleArn?: any}
  --cmaf-package: record # A Common Media Application Format (CMAF) packaging configuration. — shape: {Encryption?: any, HlsManifests?: any, SegmentDurationSeconds?: any, SegmentPrefix?: any, StreamSelection?: any}
  --dash-package: record # A Dynamic Adaptive Streaming over HTTP (DASH) packaging configuration. — shape: {AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeIframeOnlyStream?: any, ManifestLayout?: any, ManifestWindowSeconds?: any, MinBufferTimeSeconds?: any, MinUpdatePeriodSeconds?: any, PeriodTriggers?: any, Profile?: any, SegmentDurationSeconds?: any, SegmentTemplateFormat?: any, StreamSelection?: any, SuggestedPresentationDelaySeconds?: any, UtcTiming?: any, UtcTimingUri?: any}
  --description: string # A short text description of the OriginEndpoint.
  --hls-package: record # An HTTP Live Streaming (HLS) packaging configuration. — shape: {AdMarkers?: any, AdTriggers?: any, AdsOnDeliveryRestrictions?: any, Encryption?: any, IncludeDvbSubtitles?: any, IncludeIframeOnlyStream?: any, PlaylistType?: any, PlaylistWindowSeconds?: any, ProgramDateTimeIntervalSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any, UseAudioRenditionGroup?: any}
  --manifest-name: string # A short string that will be appended to the end of the Endpoint URL.
  --mss-package: record # A Microsoft Smooth Streaming (MSS) packaging configuration. — shape: {Encryption?: any, ManifestWindowSeconds?: any, SegmentDurationSeconds?: any, StreamSelection?: any}
  --origination: string@origination-completer # Control whether origination of video is allowed for this OriginEndpoint. If set to ALLOW, the OriginEndpoint may by requested, pursuant to any other form of access control. If set to DENY, the OriginEndpoint may not be requested. This can be helpful for Live to VOD harvesting, or for temporarily disabling origination
  --startover-window-seconds: int # Maximum duration (in seconds) of content to retain for startover playback. If not specified, startover playback will be disabled for the OriginEndpoint.
  --time-delay-seconds: int # Amount of delay (in seconds) to enforce on the playback of live content. If not specified, there will be no time delay in effect for the OriginEndpoint.
  --whitelist: list<string> # A list of source IP CIDR blocks that will be allowed to access the OriginEndpoint.
]: any -> record<Arn: record, Authorization: record<CdnIdentifierSecret: record, SecretsRoleArn: record>, ChannelId: record, CmafPackage: record<Encryption: record<ConstantInitializationVector: record, EncryptionMethod: record, KeyRotationIntervalSeconds: record, SpekeKeyProvider: record>, HlsManifests: record, SegmentDurationSeconds: record, SegmentPrefix: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>>, CreatedAt: record, DashPackage: record<AdTriggers: record, AdsOnDeliveryRestrictions: record, Encryption: record<KeyRotationIntervalSeconds: record, SpekeKeyProvider: record>, IncludeIframeOnlyStream: record, ManifestLayout: record, ManifestWindowSeconds: record, MinBufferTimeSeconds: record, MinUpdatePeriodSeconds: record, PeriodTriggers: record, Profile: record, SegmentDurationSeconds: record, SegmentTemplateFormat: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>, SuggestedPresentationDelaySeconds: record, UtcTiming: record, UtcTimingUri: record>, Description: record, HlsPackage: record<AdMarkers: record, AdTriggers: record, AdsOnDeliveryRestrictions: record, Encryption: record<ConstantInitializationVector: record, EncryptionMethod: record, KeyRotationIntervalSeconds: record, RepeatExtXKey: record, SpekeKeyProvider: record>, IncludeDvbSubtitles: record, IncludeIframeOnlyStream: record, PlaylistType: record, PlaylistWindowSeconds: record, ProgramDateTimeIntervalSeconds: record, SegmentDurationSeconds: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>, UseAudioRenditionGroup: record>, Id: record, ManifestName: record, MssPackage: record<Encryption: record<SpekeKeyProvider: record>, ManifestWindowSeconds: record, SegmentDurationSeconds: record, StreamSelection: record<MaxVideoBitsPerSecond: record, MinVideoBitsPerSecond: record, StreamOrder: record>>, Origination: record, StartoverWindowSeconds: record, Tags: record, TimeDelaySeconds: record, Url: record, Whitelist: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/origin_endpoints/{id}"))
  let req_body = {"authorization": $authorization, "cmafPackage": $cmaf_package, "dashPackage": $dash_package, "description": $description, "hlsPackage": $hls_package, "manifestName": $manifest_name, "mssPackage": $mss_package, "origination": $origination, "startoverWindowSeconds": $startover_window_seconds, "timeDelaySeconds": $time_delay_seconds, "whitelist": $whitelist} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets details about an existing HarvestJob.
#
# GET /harvest_jobs/{id}
# operationId: DescribeHarvestJob
export def "harvest-jobs get" [
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
]: nothing -> record<Arn: record, ChannelId: record, CreatedAt: record, EndTime: record, Id: record, OriginEndpointId: record, S3Destination: record<BucketName: record, ManifestKey: record, RoleArn: record>, StartTime: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/harvest_jobs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /tags/{resource-arn}
#
# operationId: ListTagsForResource
export def "tags list" [
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
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /tags/{resource-arn}
#
# operationId: TagResource
export def "tags tag" [
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
  tags: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
#
# PUT /channels/{id}/credentials
# DEPRECATED
# operationId: RotateChannelCredentials
@deprecated
export def "channels-credentials update-rotate" [
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
]: nothing -> record<Arn: record, CreatedAt: record, Description: record, EgressAccessLogs: record<LogGroupName: record>, HlsIngest: record<IngestEndpoints: record>, Id: record, IngressAccessLogs: record<LogGroupName: record>, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/channels/{id}/credentials"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
#
# PUT /channels/{id}/ingest_endpoints/{ingest_endpoint_id}/credentials
# operationId: RotateIngestEndpointCredentials
export def "channels-ingest-endpoints-credentials update-rotate" [
  id: string
  ingest_endpoint_id: string
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
]: nothing -> record<Arn: record, CreatedAt: record, Description: record, EgressAccessLogs: record<LogGroupName: record>, HlsIngest: record<IngestEndpoints: record>, Id: record, IngressAccessLogs: record<LogGroupName: record>, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($ingest_endpoint_id | is-empty) { error make --unspanned { msg: "path parameter 'ingest_endpoint_id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), ingest_endpoint_id: (encode-path-segment $ingest_endpoint_id)} | format pattern "/channels/{id}/ingest_endpoints/{ingest_endpoint_id}/credentials"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE /tags/{resource-arn}
#
# operationId: UntagResource
export def "tags untag" [
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
  --tag-keys: list # The key(s) of tag to be deleted
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
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}
