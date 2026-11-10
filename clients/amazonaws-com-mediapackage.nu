# Auto-generated client for AWS Elemental MediaPackage v2017-10-12
# Source: https://api.apis.guru/v2/specs/amazonaws.com/mediapackage/2017-10-12/openapi.json
# Auth: --token flag or $env.AWS_ELEMENTAL_MEDIAPACKAGE_TOKEN

const BASE_URL = "http://mediapackage.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_ELEMENTAL_MEDIAPACKAGE_TOKEN | default "" }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://mediapackage.us-east-1.amazonaws.com" "http://mediapackage.us-east-2.amazonaws.com" "http://mediapackage.us-west-1.amazonaws.com" "http://mediapackage.us-west-2.amazonaws.com" "http://mediapackage.us-gov-west-1.amazonaws.com" "http://mediapackage.us-gov-east-1.amazonaws.com" "http://mediapackage.ca-central-1.amazonaws.com" "http://mediapackage.eu-north-1.amazonaws.com" "http://mediapackage.eu-west-1.amazonaws.com" "http://mediapackage.eu-west-2.amazonaws.com" "http://mediapackage.eu-west-3.amazonaws.com" "http://mediapackage.eu-central-1.amazonaws.com" "http://mediapackage.eu-south-1.amazonaws.com" "http://mediapackage.af-south-1.amazonaws.com" "http://mediapackage.ap-northeast-1.amazonaws.com" "http://mediapackage.ap-northeast-2.amazonaws.com" "http://mediapackage.ap-northeast-3.amazonaws.com" "http://mediapackage.ap-southeast-1.amazonaws.com" "http://mediapackage.ap-southeast-2.amazonaws.com" "http://mediapackage.ap-east-1.amazonaws.com" "http://mediapackage.ap-south-1.amazonaws.com" "http://mediapackage.sa-east-1.amazonaws.com" "http://mediapackage.me-south-1.amazonaws.com" "https://mediapackage.us-east-1.amazonaws.com" "https://mediapackage.us-east-2.amazonaws.com" "https://mediapackage.us-west-1.amazonaws.com" "https://mediapackage.us-west-2.amazonaws.com" "https://mediapackage.us-gov-west-1.amazonaws.com" "https://mediapackage.us-gov-east-1.amazonaws.com" "https://mediapackage.ca-central-1.amazonaws.com" "https://mediapackage.eu-north-1.amazonaws.com" "https://mediapackage.eu-west-1.amazonaws.com" "https://mediapackage.eu-west-2.amazonaws.com" "https://mediapackage.eu-west-3.amazonaws.com" "https://mediapackage.eu-central-1.amazonaws.com" "https://mediapackage.eu-south-1.amazonaws.com" "https://mediapackage.af-south-1.amazonaws.com" "https://mediapackage.ap-northeast-1.amazonaws.com" "https://mediapackage.ap-northeast-2.amazonaws.com" "https://mediapackage.ap-northeast-3.amazonaws.com" "https://mediapackage.ap-southeast-1.amazonaws.com" "https://mediapackage.ap-southeast-2.amazonaws.com" "https://mediapackage.ap-east-1.amazonaws.com" "https://mediapackage.ap-south-1.amazonaws.com" "https://mediapackage.sa-east-1.amazonaws.com" "https://mediapackage.me-south-1.amazonaws.com" "http://mediapackage.cn-north-1.amazonaws.com.cn" "http://mediapackage.cn-northwest-1.amazonaws.com.cn" "https://mediapackage.cn-north-1.amazonaws.com.cn" "https://mediapackage.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def origination-completer [] { ["ALLOW" "DENY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["configure-logs" "create-channel" "list-channels" "create-harvest-job" "list-harvest-jobs" "create-origin-endpoint" "list-origin-endpoints" "delete-channel" "describe-channel" "update-channel" "delete-origin-endpoint" "describe-origin-endpoint" "update-origin-endpoint" "describe-harvest-job" "list-tags-for-resource" "tag-resource" "rotate-channel-credentials" "rotate-ingest-endpoint-credentials" "untag-resource" "commands"] | sort) } | get name | first)
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

# Changes the Channel's properities to configure log subscription
#
# PUT /channels/{id}/configure_logs
# operationId: ConfigureLogs
export def "configure-logs" [
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
  --egress-access-logs: record # Configure egress access logging. — shape: {LogGroupName?: string}
  --ingress-access-logs: record # Configure ingress access logging. — shape: {LogGroupName?: string}
]: any -> oneof<record<Arn: string, CreatedAt: string, Description: string, EgressAccessLogs: record<LogGroupName: string>, HlsIngest: record<IngestEndpoints: list<record>>, Id: string, IngressAccessLogs: record<LogGroupName: string>, Tags: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/channels/{id}/configure_logs") $auth.query)
  let req_body = {"egressAccessLogs": $egress_access_logs, "ingressAccessLogs": $ingress_access_logs} | compact
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

# Creates a new Channel.
#
# POST /channels
# operationId: CreateChannel
export def "create-channel" [
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
]: any -> oneof<record<Arn: string, CreatedAt: string, Description: string, EgressAccessLogs: record<LogGroupName: string>, HlsIngest: record<IngestEndpoints: list<record>>, Id: string, IngressAccessLogs: record<LogGroupName: string>, Tags: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels" $auth.query)
  let req_body = {"description": $description, "id": $id, "tags": $tags} | compact
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

# Returns a collection of Channels.
#
# GET /channels
# operationId: ListChannels
export def "list-channels" [
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
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Channels: table<Arn: string, CreatedAt: string, Description: string, EgressAccessLogs: record, HlsIngest: record, Id: string, IngressAccessLogs: record, Tags: record>, NextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $qp_max_results "scalar") (serialize-qp "NextToken" $qp_next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $qp_max_results, "NextToken": $qp_next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new HarvestJob record.
#
# POST /harvest_jobs
# operationId: CreateHarvestJob
export def "create-harvest-job" [
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
  s3_destination: record # Configuration parameters for where in an S3 bucket to place the harvested content — shape: {BucketName?: string, ManifestKey?: string, RoleArn?: string}
  start_time: string # The start of the time-window which will be harvested
]: any -> oneof<record<Arn: string, ChannelId: string, CreatedAt: string, EndTime: string, Id: string, OriginEndpointId: string, S3Destination: record<BucketName: string, ManifestKey: string, RoleArn: string>, StartTime: string, Status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/harvest_jobs" $auth.query)
  let req_body = {"endTime": $end_time, "id": $id, "originEndpointId": $origin_endpoint_id, "s3Destination": $s3_destination, "startTime": $start_time} | compact
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

# Returns a collection of HarvestJob records.
#
# GET /harvest_jobs
# operationId: ListHarvestJobs
export def "list-harvest-jobs" [
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
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<HarvestJobs: table<Arn: string, ChannelId: string, CreatedAt: string, EndTime: string, Id: string, OriginEndpointId: string, S3Destination: record, StartTime: string, Status: string>, NextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeChannelId" $include_channel_id "scalar") (serialize-qp "includeStatus" $include_status "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $qp_max_results "scalar") (serialize-qp "NextToken" $qp_next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/harvest_jobs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"includeChannelId": $include_channel_id, "includeStatus": $include_status, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $qp_max_results, "NextToken": $qp_next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new OriginEndpoint record.
#
# POST /origin_endpoints
# operationId: CreateOriginEndpoint
export def "create-origin-endpoint" [
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
  --authorization: record # CDN Authorization credentials — shape: {CdnIdentifierSecret?: string, SecretsRoleArn?: string}
  channel_id: string # The ID of the Channel that the OriginEndpoint will be associated with. This cannot be changed after the OriginEndpoint is created.
  --cmaf-package: record # A Common Media Application Format (CMAF) packaging configuration. — shape: {Encryption?: record, HlsManifests?: list, SegmentDurationSeconds?: int, SegmentPrefix?: string, StreamSelection?: record}
  --dash-package: record # A Dynamic Adaptive Streaming over HTTP (DASH) packaging configuration. — shape: {AdTriggers?: list<string>, AdsOnDeliveryRestrictions?: "NONE"|"RESTRICTED"|"UNRESTRICTED"|"BOTH", Encryption?: record, IncludeIframeOnlyStream?: bool, ManifestLayout?: "FULL"|"COMPACT", ManifestWindowSeconds?: int, MinBufferTimeSeconds?: int, MinUpdatePeriodSeconds?: int, PeriodTriggers?: list<string>, Profile?: "NONE"|"HBBTV_1_5"|"HYBRIDCAST"|"DVB_DASH_2014", SegmentDurationSeconds?: int, SegmentTemplateFormat?: "NUMBER_WITH_TIMELINE"|"TIME_WITH_TIMELINE"|"NUMBER_WITH_DURATION", ... (4 more fields)}
  --description: string # A short text description of the OriginEndpoint.
  --hls-package: record # An HTTP Live Streaming (HLS) packaging configuration. — shape: {AdMarkers?: "NONE"|"SCTE35_ENHANCED"|"PASSTHROUGH"|"DATERANGE", AdTriggers?: list<string>, AdsOnDeliveryRestrictions?: "NONE"|"RESTRICTED"|"UNRESTRICTED"|"BOTH", Encryption?: record, IncludeDvbSubtitles?: bool, IncludeIframeOnlyStream?: bool, PlaylistType?: "NONE"|"EVENT"|"VOD", PlaylistWindowSeconds?: int, ProgramDateTimeIntervalSeconds?: int, SegmentDurationSeconds?: int, StreamSelection?: record, UseAudioRenditionGroup?: bool}
  id: string # The ID of the OriginEndpoint. The ID must be unique within the region and it cannot be changed after the OriginEndpoint is created.
  --manifest-name: string # A short string that will be used as the filename of the OriginEndpoint URL (defaults to "index").
  --mss-package: record # A Microsoft Smooth Streaming (MSS) packaging configuration. — shape: {Encryption?: record, ManifestWindowSeconds?: int, SegmentDurationSeconds?: int, StreamSelection?: record}
  --origination: string@origination-completer # Control whether origination of video is allowed for this OriginEndpoint. If set to ALLOW, the OriginEndpoint may by requested, pursuant to any other form of access control. If set to DENY, the OriginEndpoint may not be requested. This can be helpful for Live to VOD harvesting, or for temporarily disabling origination
  --startover-window-seconds: int # Maximum duration (seconds) of content to retain for startover playback. If not specified, startover playback will be disabled for the OriginEndpoint.
  --tags: record # A collection of tags associated with a resource
  --time-delay-seconds: int # Amount of delay (seconds) to enforce on the playback of live content. If not specified, there will be no time delay in effect for the OriginEndpoint.
  --whitelist: list<string> # A list of source IP CIDR blocks that will be allowed to access the OriginEndpoint.
]: any -> oneof<record<Arn: string, Authorization: record<CdnIdentifierSecret: string, SecretsRoleArn: string>, ChannelId: string, CmafPackage: record<Encryption: record<ConstantInitializationVector: string, EncryptionMethod: string, KeyRotationIntervalSeconds: int, SpekeKeyProvider: record>, HlsManifests: list<record>, SegmentDurationSeconds: int, SegmentPrefix: string, StreamSelection: record<MaxVideoBitsPerSecond: int, MinVideoBitsPerSecond: int, StreamOrder: string>>, CreatedAt: string, DashPackage: record<AdTriggers: list<string>, AdsOnDeliveryRestrictions: string, Encryption: record<KeyRotationIntervalSeconds: int, SpekeKeyProvider: record>, IncludeIframeOnlyStream: bool, ManifestLayout: string, ManifestWindowSeconds: int, MinBufferTimeSeconds: int, MinUpdatePeriodSeconds: int, PeriodTriggers: list<string>, Profile: string, SegmentDurationSeconds: int, SegmentTemplateFormat: string, StreamSelection: record<MaxVideoBitsPerSecond: int, MinVideoBitsPerSecond: int, StreamOrder: string>, SuggestedPresentationDelaySeconds: int, UtcTiming: string, UtcTimingUri: string>, Description: string, HlsPackage: record<AdMarkers: string, AdTriggers: list<string>, AdsOnDeliveryRestrictions: string, Encryption: record<ConstantInitializationVector: string, EncryptionMethod: string, KeyRotationIntervalSeconds: int, RepeatExtXKey: bool, SpekeKeyProvider: record>, IncludeDvbSubtitles: bool, IncludeIframeOnlyStream: bool, PlaylistType: string, PlaylistWindowSeconds: int, ProgramDateTimeIntervalSeconds: int, SegmentDurationSeconds: int, StreamSelection: record<MaxVideoBitsPerSecond: int, MinVideoBitsPerSecond: int, StreamOrder: string>, UseAudioRenditionGroup: bool>, Id: string, ManifestName: string, MssPackage: record<Encryption: record<SpekeKeyProvider: record>, ManifestWindowSeconds: int, SegmentDurationSeconds: int, StreamSelection: record<MaxVideoBitsPerSecond: int, MinVideoBitsPerSecond: int, StreamOrder: string>>, Origination: string, StartoverWindowSeconds: int, Tags: record, TimeDelaySeconds: int, Url: string, Whitelist: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/origin_endpoints" $auth.query)
  let req_body = {"authorization": $authorization, "channelId": $channel_id, "cmafPackage": $cmaf_package, "dashPackage": $dash_package, "description": $description, "hlsPackage": $hls_package, "id": $id, "manifestName": $manifest_name, "mssPackage": $mss_package, "origination": $origination, "startoverWindowSeconds": $startover_window_seconds, "tags": $tags, "timeDelaySeconds": $time_delay_seconds, "whitelist": $whitelist} | compact
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

# Returns a collection of OriginEndpoint records.
#
# GET /origin_endpoints
# operationId: ListOriginEndpoints
export def "list-origin-endpoints" [
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
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<NextToken: string, OriginEndpoints: table<Arn: string, Authorization: record, ChannelId: string, CmafPackage: record, CreatedAt: string, DashPackage: record, Description: string, HlsPackage: record, Id: string, ManifestName: string, MssPackage: record, Origination: string, StartoverWindowSeconds: int, Tags: record, TimeDelaySeconds: int, Url: string, Whitelist: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channelId" $channel_id "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $qp_max_results "scalar") (serialize-qp "NextToken" $qp_next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/origin_endpoints" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"channelId": $channel_id, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $qp_max_results, "NextToken": $qp_next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an existing Channel.
#
# DELETE /channels/{id}
# operationId: DeleteChannel
export def "delete-channel" [
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
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/channels/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets details about a Channel.
#
# GET /channels/{id}
# operationId: DescribeChannel
export def "describe-channel" [
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
]: nothing -> oneof<record<Arn: string, CreatedAt: string, Description: string, EgressAccessLogs: record<LogGroupName: string>, HlsIngest: record<IngestEndpoints: list<record>>, Id: string, IngressAccessLogs: record<LogGroupName: string>, Tags: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/channels/{id}") $auth.query)
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

# Updates an existing Channel.
#
# PUT /channels/{id}
# operationId: UpdateChannel
export def "update-channel" [
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
]: any -> oneof<record<Arn: string, CreatedAt: string, Description: string, EgressAccessLogs: record<LogGroupName: string>, HlsIngest: record<IngestEndpoints: list<record>>, Id: string, IngressAccessLogs: record<LogGroupName: string>, Tags: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/channels/{id}") $auth.query)
  let req_body = {"description": $description} | compact
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

# Deletes an existing OriginEndpoint.
#
# DELETE /origin_endpoints/{id}
# operationId: DeleteOriginEndpoint
export def "delete-origin-endpoint" [
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
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/origin_endpoints/{id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets details about an existing OriginEndpoint.
#
# GET /origin_endpoints/{id}
# operationId: DescribeOriginEndpoint
export def "describe-origin-endpoint" [
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
]: nothing -> oneof<record<Arn: string, Authorization: record<CdnIdentifierSecret: string, SecretsRoleArn: string>, ChannelId: string, CmafPackage: record<Encryption: record<ConstantInitializationVector: string, EncryptionMethod: string, KeyRotationIntervalSeconds: int, SpekeKeyProvider: record>, HlsManifests: list<record>, SegmentDurationSeconds: int, SegmentPrefix: string, StreamSelection: record<MaxVideoBitsPerSecond: int, MinVideoBitsPerSecond: int, StreamOrder: string>>, CreatedAt: string, DashPackage: record<AdTriggers: list<string>, AdsOnDeliveryRestrictions: string, Encryption: record<KeyRotationIntervalSeconds: int, SpekeKeyProvider: record>, IncludeIframeOnlyStream: bool, ManifestLayout: string, ManifestWindowSeconds: int, MinBufferTimeSeconds: int, MinUpdatePeriodSeconds: int, PeriodTriggers: list<string>, Profile: string, SegmentDurationSeconds: int, SegmentTemplateFormat: string, StreamSelection: record<MaxVideoBitsPerSecond: int, MinVideoBitsPerSecond: int, StreamOrder: string>, SuggestedPresentationDelaySeconds: int, UtcTiming: string, UtcTimingUri: string>, Description: string, HlsPackage: record<AdMarkers: string, AdTriggers: list<string>, AdsOnDeliveryRestrictions: string, Encryption: record<ConstantInitializationVector: string, EncryptionMethod: string, KeyRotationIntervalSeconds: int, RepeatExtXKey: bool, SpekeKeyProvider: record>, IncludeDvbSubtitles: bool, IncludeIframeOnlyStream: bool, PlaylistType: string, PlaylistWindowSeconds: int, ProgramDateTimeIntervalSeconds: int, SegmentDurationSeconds: int, StreamSelection: record<MaxVideoBitsPerSecond: int, MinVideoBitsPerSecond: int, StreamOrder: string>, UseAudioRenditionGroup: bool>, Id: string, ManifestName: string, MssPackage: record<Encryption: record<SpekeKeyProvider: record>, ManifestWindowSeconds: int, SegmentDurationSeconds: int, StreamSelection: record<MaxVideoBitsPerSecond: int, MinVideoBitsPerSecond: int, StreamOrder: string>>, Origination: string, StartoverWindowSeconds: int, Tags: record, TimeDelaySeconds: int, Url: string, Whitelist: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/origin_endpoints/{id}") $auth.query)
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

# Updates an existing OriginEndpoint.
#
# PUT /origin_endpoints/{id}
# operationId: UpdateOriginEndpoint
export def "update-origin-endpoint" [
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
  --authorization: record # CDN Authorization credentials — shape: {CdnIdentifierSecret?: string, SecretsRoleArn?: string}
  --cmaf-package: record # A Common Media Application Format (CMAF) packaging configuration. — shape: {Encryption?: record, HlsManifests?: list, SegmentDurationSeconds?: int, SegmentPrefix?: string, StreamSelection?: record}
  --dash-package: record # A Dynamic Adaptive Streaming over HTTP (DASH) packaging configuration. — shape: {AdTriggers?: list<string>, AdsOnDeliveryRestrictions?: "NONE"|"RESTRICTED"|"UNRESTRICTED"|"BOTH", Encryption?: record, IncludeIframeOnlyStream?: bool, ManifestLayout?: "FULL"|"COMPACT", ManifestWindowSeconds?: int, MinBufferTimeSeconds?: int, MinUpdatePeriodSeconds?: int, PeriodTriggers?: list<string>, Profile?: "NONE"|"HBBTV_1_5"|"HYBRIDCAST"|"DVB_DASH_2014", SegmentDurationSeconds?: int, SegmentTemplateFormat?: "NUMBER_WITH_TIMELINE"|"TIME_WITH_TIMELINE"|"NUMBER_WITH_DURATION", ... (4 more fields)}
  --description: string # A short text description of the OriginEndpoint.
  --hls-package: record # An HTTP Live Streaming (HLS) packaging configuration. — shape: {AdMarkers?: "NONE"|"SCTE35_ENHANCED"|"PASSTHROUGH"|"DATERANGE", AdTriggers?: list<string>, AdsOnDeliveryRestrictions?: "NONE"|"RESTRICTED"|"UNRESTRICTED"|"BOTH", Encryption?: record, IncludeDvbSubtitles?: bool, IncludeIframeOnlyStream?: bool, PlaylistType?: "NONE"|"EVENT"|"VOD", PlaylistWindowSeconds?: int, ProgramDateTimeIntervalSeconds?: int, SegmentDurationSeconds?: int, StreamSelection?: record, UseAudioRenditionGroup?: bool}
  --manifest-name: string # A short string that will be appended to the end of the Endpoint URL.
  --mss-package: record # A Microsoft Smooth Streaming (MSS) packaging configuration. — shape: {Encryption?: record, ManifestWindowSeconds?: int, SegmentDurationSeconds?: int, StreamSelection?: record}
  --origination: string@origination-completer # Control whether origination of video is allowed for this OriginEndpoint. If set to ALLOW, the OriginEndpoint may by requested, pursuant to any other form of access control. If set to DENY, the OriginEndpoint may not be requested. This can be helpful for Live to VOD harvesting, or for temporarily disabling origination
  --startover-window-seconds: int # Maximum duration (in seconds) of content to retain for startover playback. If not specified, startover playback will be disabled for the OriginEndpoint.
  --time-delay-seconds: int # Amount of delay (in seconds) to enforce on the playback of live content. If not specified, there will be no time delay in effect for the OriginEndpoint.
  --whitelist: list<string> # A list of source IP CIDR blocks that will be allowed to access the OriginEndpoint.
]: any -> oneof<record<Arn: string, Authorization: record<CdnIdentifierSecret: string, SecretsRoleArn: string>, ChannelId: string, CmafPackage: record<Encryption: record<ConstantInitializationVector: string, EncryptionMethod: string, KeyRotationIntervalSeconds: int, SpekeKeyProvider: record>, HlsManifests: list<record>, SegmentDurationSeconds: int, SegmentPrefix: string, StreamSelection: record<MaxVideoBitsPerSecond: int, MinVideoBitsPerSecond: int, StreamOrder: string>>, CreatedAt: string, DashPackage: record<AdTriggers: list<string>, AdsOnDeliveryRestrictions: string, Encryption: record<KeyRotationIntervalSeconds: int, SpekeKeyProvider: record>, IncludeIframeOnlyStream: bool, ManifestLayout: string, ManifestWindowSeconds: int, MinBufferTimeSeconds: int, MinUpdatePeriodSeconds: int, PeriodTriggers: list<string>, Profile: string, SegmentDurationSeconds: int, SegmentTemplateFormat: string, StreamSelection: record<MaxVideoBitsPerSecond: int, MinVideoBitsPerSecond: int, StreamOrder: string>, SuggestedPresentationDelaySeconds: int, UtcTiming: string, UtcTimingUri: string>, Description: string, HlsPackage: record<AdMarkers: string, AdTriggers: list<string>, AdsOnDeliveryRestrictions: string, Encryption: record<ConstantInitializationVector: string, EncryptionMethod: string, KeyRotationIntervalSeconds: int, RepeatExtXKey: bool, SpekeKeyProvider: record>, IncludeDvbSubtitles: bool, IncludeIframeOnlyStream: bool, PlaylistType: string, PlaylistWindowSeconds: int, ProgramDateTimeIntervalSeconds: int, SegmentDurationSeconds: int, StreamSelection: record<MaxVideoBitsPerSecond: int, MinVideoBitsPerSecond: int, StreamOrder: string>, UseAudioRenditionGroup: bool>, Id: string, ManifestName: string, MssPackage: record<Encryption: record<SpekeKeyProvider: record>, ManifestWindowSeconds: int, SegmentDurationSeconds: int, StreamSelection: record<MaxVideoBitsPerSecond: int, MinVideoBitsPerSecond: int, StreamOrder: string>>, Origination: string, StartoverWindowSeconds: int, Tags: record, TimeDelaySeconds: int, Url: string, Whitelist: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/origin_endpoints/{id}") $auth.query)
  let req_body = {"authorization": $authorization, "cmafPackage": $cmaf_package, "dashPackage": $dash_package, "description": $description, "hlsPackage": $hls_package, "manifestName": $manifest_name, "mssPackage": $mss_package, "origination": $origination, "startoverWindowSeconds": $startover_window_seconds, "timeDelaySeconds": $time_delay_seconds, "whitelist": $whitelist} | compact
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

# Gets details about an existing HarvestJob.
#
# GET /harvest_jobs/{id}
# operationId: DescribeHarvestJob
export def "describe-harvest-job" [
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
]: nothing -> oneof<record<Arn: string, ChannelId: string, CreatedAt: string, EndTime: string, Id: string, OriginEndpointId: string, S3Destination: record<BucketName: string, ManifestKey: string, RoleArn: string>, StartTime: string, Status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/harvest_jobs/{id}") $auth.query)
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

# GET /tags/{resource-arn}
#
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
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
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

# POST /tags/{resource-arn}
#
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
  tags: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $auth.query)
  let req_body = {"tags": $tags} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
#
# PUT /channels/{id}/credentials
# DEPRECATED
# operationId: RotateChannelCredentials
@deprecated
export def "rotate-channel-credentials" [
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
]: nothing -> oneof<record<Arn: string, CreatedAt: string, Description: string, EgressAccessLogs: record<LogGroupName: string>, HlsIngest: record<IngestEndpoints: list<record>>, Id: string, IngressAccessLogs: record<LogGroupName: string>, Tags: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/channels/{id}/credentials") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
#
# PUT /channels/{id}/ingest_endpoints/{ingest_endpoint_id}/credentials
# operationId: RotateIngestEndpointCredentials
export def "rotate-ingest-endpoint-credentials" [
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
]: nothing -> oneof<record<Arn: string, CreatedAt: string, Description: string, EgressAccessLogs: record<LogGroupName: string>, HlsIngest: record<IngestEndpoints: list<record>>, Id: string, IngressAccessLogs: record<LogGroupName: string>, Tags: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($ingest_endpoint_id | is-empty) { error make --unspanned { msg: "path parameter 'ingest_endpoint_id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), ingest_endpoint_id: (encode-path-segment $ingest_endpoint_id)} | format pattern "/channels/{id}/ingest_endpoints/{ingest_endpoint_id}/credentials") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# DELETE /tags/{resource-arn}
#
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
  --tag-keys: list # The key(s) of tag to be deleted (required)
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}
