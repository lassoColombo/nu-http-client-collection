# Auto-generated client for AWS MediaConnect v2018-11-14
# Source: https://api.apis.guru/v2/specs/amazonaws.com/mediaconnect/2018-11-14/openapi.json
# Auth: --token flag or $env.AWS_MEDIACONNECT_TOKEN

const BASE_URL = "http://mediaconnect.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_MEDIACONNECT_TOKEN | default "" }
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

def base-url-completer [] { ["http://mediaconnect.us-east-1.amazonaws.com" "http://mediaconnect.us-east-2.amazonaws.com" "http://mediaconnect.us-west-1.amazonaws.com" "http://mediaconnect.us-west-2.amazonaws.com" "http://mediaconnect.us-gov-west-1.amazonaws.com" "http://mediaconnect.us-gov-east-1.amazonaws.com" "http://mediaconnect.ca-central-1.amazonaws.com" "http://mediaconnect.eu-north-1.amazonaws.com" "http://mediaconnect.eu-west-1.amazonaws.com" "http://mediaconnect.eu-west-2.amazonaws.com" "http://mediaconnect.eu-west-3.amazonaws.com" "http://mediaconnect.eu-central-1.amazonaws.com" "http://mediaconnect.eu-south-1.amazonaws.com" "http://mediaconnect.af-south-1.amazonaws.com" "http://mediaconnect.ap-northeast-1.amazonaws.com" "http://mediaconnect.ap-northeast-2.amazonaws.com" "http://mediaconnect.ap-northeast-3.amazonaws.com" "http://mediaconnect.ap-southeast-1.amazonaws.com" "http://mediaconnect.ap-southeast-2.amazonaws.com" "http://mediaconnect.ap-east-1.amazonaws.com" "http://mediaconnect.ap-south-1.amazonaws.com" "http://mediaconnect.sa-east-1.amazonaws.com" "http://mediaconnect.me-south-1.amazonaws.com" "https://mediaconnect.us-east-1.amazonaws.com" "https://mediaconnect.us-east-2.amazonaws.com" "https://mediaconnect.us-west-1.amazonaws.com" "https://mediaconnect.us-west-2.amazonaws.com" "https://mediaconnect.us-gov-west-1.amazonaws.com" "https://mediaconnect.us-gov-east-1.amazonaws.com" "https://mediaconnect.ca-central-1.amazonaws.com" "https://mediaconnect.eu-north-1.amazonaws.com" "https://mediaconnect.eu-west-1.amazonaws.com" "https://mediaconnect.eu-west-2.amazonaws.com" "https://mediaconnect.eu-west-3.amazonaws.com" "https://mediaconnect.eu-central-1.amazonaws.com" "https://mediaconnect.eu-south-1.amazonaws.com" "https://mediaconnect.af-south-1.amazonaws.com" "https://mediaconnect.ap-northeast-1.amazonaws.com" "https://mediaconnect.ap-northeast-2.amazonaws.com" "https://mediaconnect.ap-northeast-3.amazonaws.com" "https://mediaconnect.ap-southeast-1.amazonaws.com" "https://mediaconnect.ap-southeast-2.amazonaws.com" "https://mediaconnect.ap-east-1.amazonaws.com" "https://mediaconnect.ap-south-1.amazonaws.com" "https://mediaconnect.sa-east-1.amazonaws.com" "https://mediaconnect.me-south-1.amazonaws.com" "http://mediaconnect.cn-north-1.amazonaws.com.cn" "http://mediaconnect.cn-northwest-1.amazonaws.com.cn" "https://mediaconnect.cn-north-1.amazonaws.com.cn" "https://mediaconnect.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def bridge-placement-completer [] { ["AVAILABLE" "LOCKED"] }
def media-stream-type-completer [] { ["ancillary-data" "audio" "video"] }
def protocol-completer [] { ["cdi" "fujitsu-qos" "rist" "rtp" "rtp-fec" "srt-caller" "srt-listener" "st2110-jpegxs" "udp" "zixi-pull" "zixi-push"] }
def entitlement-status-completer [] { ["DISABLED" "ENABLED"] }
def desired-state-completer [] { ["ACTIVE" "DELETED" "STANDBY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bridges-outputs create" } } | get name | first)
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

# Adds outputs to an existing bridge.
#
# POST /v1/bridges/{bridgeArn}/outputs
# operationId: AddBridgeOutputs
# --outputs item shape: {NetworkOutput?: any}
export def "bridges-outputs create" [
  bridge_arn: string
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
  outputs: list # The outputs that you want to add to this bridge. — item shape: {NetworkOutput?: any}
]: any -> record<BridgeArn: record, Outputs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bridge_arn | is-empty) { error make --unspanned { msg: "path parameter 'bridgeArn' must be non-empty" } }
  let full_url = (build-url $base ({bridge_arn: (encode-path-segment $bridge_arn)} | format pattern "/v1/bridges/{bridge_arn}/outputs"))
  let req_body = {"outputs": $outputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds sources to an existing bridge.
#
# POST /v1/bridges/{bridgeArn}/sources
# operationId: AddBridgeSources
# --sources item shape: {FlowSource?: any, NetworkSource?: any}
export def "bridges-sources create" [
  bridge_arn: string
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
  sources: list # The sources that you want to add to this bridge. — item shape: {FlowSource?: any, NetworkSource?: any}
]: any -> record<BridgeArn: record, Sources: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bridge_arn | is-empty) { error make --unspanned { msg: "path parameter 'bridgeArn' must be non-empty" } }
  let full_url = (build-url $base ({bridge_arn: (encode-path-segment $bridge_arn)} | format pattern "/v1/bridges/{bridge_arn}/sources"))
  let req_body = {"sources": $sources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds media streams to an existing flow. After you add a media stream to a flow, you can associate it with a source and/or an output that uses the ST 2110 JPEG XS or CDI protocol.
#
# POST /v1/flows/{flowArn}/mediaStreams
# operationId: AddFlowMediaStreams
# --mediaStreams item shape: {Attributes?: any, ClockRate?: any, Description?: any, MediaStreamId: any, MediaStreamName: any, MediaStreamType: any, VideoFormat?: any}
export def "flows-media-streams create" [
  flow_arn: string
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
  media_streams: list # The media streams that you want to add to the flow. — item shape: {Attributes?: any, ClockRate?: any, Description?: any, MediaStreamId: any, MediaStreamName: any, MediaStreamType: any, VideoFormat?: any}
]: any -> record<FlowArn: record, MediaStreams: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn)} | format pattern "/v1/flows/{flow_arn}/mediaStreams"))
  let req_body = {"mediaStreams": $media_streams} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds outputs to an existing flow. You can create up to 50 outputs per flow.
#
# POST /v1/flows/{flowArn}/outputs
# operationId: AddFlowOutputs
# --outputs item shape: {CidrAllowList?: any, Description?: any, Destination?: any, Encryption?: any, MaxLatency?: any, MediaStreamOutputConfigurations?: any, MinLatency?: any, Name?: any, Port?: any, Protocol: any, RemoteId?: any, SenderControlPort?: any, SmoothingLatency?: any, StreamId?: any, VpcInterfaceAttachment?: any}
export def "flows-outputs create" [
  flow_arn: string
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
  outputs: list # A list of outputs that you want to add. — item shape: {CidrAllowList?: any, Description?: any, Destination?: any, Encryption?: any, MaxLatency?: any, MediaStreamOutputConfigurations?: any, MinLatency?: any, Name?: any, Port?: any, Protocol: any, RemoteId?: any, SenderControlPort?: any, SmoothingLatency?: any, StreamId?: any, VpcInterfaceAttachment?: any}
]: any -> record<FlowArn: record, Outputs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn)} | format pattern "/v1/flows/{flow_arn}/outputs"))
  let req_body = {"outputs": $outputs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds Sources to flow
#
# POST /v1/flows/{flowArn}/source
# operationId: AddFlowSources
# --sources item shape: {Decryption?: any, Description?: any, EntitlementArn?: any, IngestPort?: any, MaxBitrate?: any, MaxLatency?: any, MaxSyncBuffer?: any, MediaStreamSourceConfigurations?: any, MinLatency?: any, Name?: any, Protocol?: any, SenderControlPort?: any, SenderIpAddress?: any, SourceListenerAddress?: any, SourceListenerPort?: any, StreamId?: any, VpcInterfaceName?: any, WhitelistCidr?: any, GatewayBridgeSource?: any}
export def "flows-source create" [
  flow_arn: string
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
  sources: list # A list of sources that you want to add. — item shape: {Decryption?: any, Description?: any, EntitlementArn?: any, IngestPort?: any, MaxBitrate?: any, MaxLatency?: any, MaxSyncBuffer?: any, MediaStreamSourceConfigurations?: any, MinLatency?: any, Name?: any, Protocol?: any, SenderControlPort?: any, SenderIpAddress?: any, SourceListenerAddress?: any, SourceListenerPort?: any, StreamId?: any, VpcInterfaceName?: any, WhitelistCidr?: any, GatewayBridgeSource?: any}
]: any -> record<FlowArn: record, Sources: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn)} | format pattern "/v1/flows/{flow_arn}/source"))
  let req_body = {"sources": $sources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds VPC interfaces to flow
#
# POST /v1/flows/{flowArn}/vpcInterfaces
# operationId: AddFlowVpcInterfaces
# --vpcInterfaces item shape: {Name: any, NetworkInterfaceType?: any, RoleArn: any, SecurityGroupIds: any, SubnetId: any}
export def "flows-vpc-interfaces create" [
  flow_arn: string
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
  vpc_interfaces: list # A list of VPC interfaces that you want to add. — item shape: {Name: any, NetworkInterfaceType?: any, RoleArn: any, SecurityGroupIds: any, SubnetId: any}
]: any -> record<FlowArn: record, VpcInterfaces: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn)} | format pattern "/v1/flows/{flow_arn}/vpcInterfaces"))
  let req_body = {"vpcInterfaces": $vpc_interfaces} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a new bridge. The request must include one source.
#
# POST /v1/bridges
# operationId: CreateBridge
# --egressGatewayBridge shape: {MaxBitrate?: any}
# --ingressGatewayBridge shape: {MaxBitrate?: any, MaxOutputs?: any}
# --outputs item shape: {NetworkOutput?: any}
# --sourceFailoverConfig shape: {FailoverMode?: any, RecoveryWindow?: any, SourcePriority?: any, State?: any}
# --sources item shape: {FlowSource?: any, NetworkSource?: any}
export def "bridges create" [
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
  --egress-gateway-bridge: record # Create a bridge with the egress bridge type. An egress bridge is a cloud-to-ground bridge. The content comes from an existing MediaConnect flow and is delivered to your premises. — shape: {MaxBitrate?: any}
  --ingress-gateway-bridge: record # Create a bridge with the ingress bridge type. An ingress bridge is a ground-to-cloud bridge. The content originates at your premises and is delivered to the cloud. — shape: {MaxBitrate?: any, MaxOutputs?: any}
  name: string # The name of the bridge. This name can not be modified after the bridge is created.
  --outputs: list # The outputs that you want to add to this bridge. — item shape: {NetworkOutput?: any}
  placement_arn: string # The bridge placement Amazon Resource Number (ARN).
  --source-failover-config: record # The settings for source failover. — shape: {FailoverMode?: any, RecoveryWindow?: any, SourcePriority?: any, State?: any}
  sources: list # The sources that you want to add to this bridge. — item shape: {FlowSource?: any, NetworkSource?: any}
]: any -> record<Bridge: record<BridgeArn: record, BridgeMessages: record, BridgeState: record, EgressGatewayBridge: record<InstanceId: record, MaxBitrate: record>, IngressGatewayBridge: record<InstanceId: record, MaxBitrate: record, MaxOutputs: record>, Name: record, Outputs: record, PlacementArn: record, SourceFailoverConfig: record<FailoverMode: record, RecoveryWindow: record, SourcePriority: record, State: record>, Sources: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bridges")
  let req_body = {"egressGatewayBridge": $egress_gateway_bridge, "ingressGatewayBridge": $ingress_gateway_bridge, "name": $name, "outputs": $outputs, "placementArn": $placement_arn, "sourceFailoverConfig": $source_failover_config, "sources": $sources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Displays a list of bridges that are associated with this account and an optionally specified Arn. This request returns a paginated result.
#
# GET /v1/bridges
# operationId: ListBridges
export def "bridges list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-arn: string # Filter the list results to display only the bridges associated with the selected Amazon Resource Name (ARN).
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListBridges request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListBridges request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListBridges request a second time and specify the NextToken value.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Bridges: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterArn" $filter_arn "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/bridges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filterArn": $filter_arn, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates a new flow. The request must include one source. The request optionally can include outputs (up to 50) and entitlements (up to 50).
#
# POST /v1/flows
# operationId: CreateFlow
# --entitlements item shape: {DataTransferSubscriberFeePercent?: any, Description?: any, Encryption?: any, EntitlementStatus?: any, Name?: any, Subscribers: any}
# --mediaStreams item shape: {Attributes?: any, ClockRate?: any, Description?: any, MediaStreamId: any, MediaStreamName: any, MediaStreamType: any, VideoFormat?: any}
# --outputs item shape: {CidrAllowList?: any, Description?: any, Destination?: any, Encryption?: any, MaxLatency?: any, MediaStreamOutputConfigurations?: any, MinLatency?: any, Name?: any, Port?: any, Protocol: any, RemoteId?: any, SenderControlPort?: any, SmoothingLatency?: any, StreamId?: any, VpcInterfaceAttachment?: any}
# --source shape: {Decryption?: any, Description?: any, EntitlementArn?: any, IngestPort?: any, MaxBitrate?: any, MaxLatency?: any, MaxSyncBuffer?: any, MediaStreamSourceConfigurations?: any, MinLatency?: any, Name?: any, Protocol?: any, SenderControlPort?: any, SenderIpAddress?: any, SourceListenerAddress?: any, SourceListenerPort?: any, StreamId?: any, VpcInterfaceName?: any, WhitelistCidr?: any, GatewayBridgeSource?: any}
# --sourceFailoverConfig shape: {FailoverMode?: any, RecoveryWindow?: any, SourcePriority?: any, State?: any}
# --sources item shape: {Decryption?: any, Description?: any, EntitlementArn?: any, IngestPort?: any, MaxBitrate?: any, MaxLatency?: any, MaxSyncBuffer?: any, MediaStreamSourceConfigurations?: any, MinLatency?: any, Name?: any, Protocol?: any, SenderControlPort?: any, SenderIpAddress?: any, SourceListenerAddress?: any, SourceListenerPort?: any, StreamId?: any, VpcInterfaceName?: any, WhitelistCidr?: any, GatewayBridgeSource?: any}
# --vpcInterfaces item shape: {Name: any, NetworkInterfaceType?: any, RoleArn: any, SecurityGroupIds: any, SubnetId: any}
# --maintenance shape: {MaintenanceDay?: any, MaintenanceStartHour?: any}
export def "flows create" [
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
  --availability-zone: string # The Availability Zone that you want to create the flow in. These options are limited to the Availability Zones within the current AWS Region.
  --entitlements: list # The entitlements that you want to grant on a flow. — item shape: {DataTransferSubscriberFeePercent?: any, Description?: any, Encryption?: any, EntitlementStatus?: any, Name?: any, Subscribers: any}
  --media-streams: list # The media streams that you want to add to the flow. You can associate these media streams with sources and outputs on the flow. — item shape: {Attributes?: any, ClockRate?: any, Description?: any, MediaStreamId: any, MediaStreamName: any, MediaStreamType: any, VideoFormat?: any}
  name: string # The name of the flow.
  --outputs: list # The outputs that you want to add to this flow. — item shape: {CidrAllowList?: any, Description?: any, Destination?: any, Encryption?: any, MaxLatency?: any, MediaStreamOutputConfigurations?: any, MinLatency?: any, Name?: any, Port?: any, Protocol: any, RemoteId?: any, SenderControlPort?: any, SmoothingLatency?: any, StreamId?: any, VpcInterfaceAttachment?: any}
  --body-source: record # The settings for the source of the flow. — shape: {Decryption?: any, Description?: any, EntitlementArn?: any, IngestPort?: any, MaxBitrate?: any, MaxLatency?: any, MaxSyncBuffer?: any, MediaStreamSourceConfigurations?: any, MinLatency?: any, Name?: any, Protocol?: any, SenderControlPort?: any, SenderIpAddress?: any, SourceListenerAddress?: any, SourceListenerPort?: any, StreamId?: any, VpcInterfaceName?: any, WhitelistCidr?: any, GatewayBridgeSource?: any}
  --source-failover-config: record # The settings for source failover. — shape: {FailoverMode?: any, RecoveryWindow?: any, SourcePriority?: any, State?: any}
  --sources: list # item shape: {Decryption?: any, Description?: any, EntitlementArn?: any, IngestPort?: any, MaxBitrate?: any, MaxLatency?: any, MaxSyncBuffer?: any, MediaStreamSourceConfigurations?: any, MinLatency?: any, Name?: any, Protocol?: any, SenderControlPort?: any, SenderIpAddress?: any, SourceListenerAddress?: any, SourceListenerPort?: any, StreamId?: any, VpcInterfaceName?: any, WhitelistCidr?: any, GatewayBridgeSource?: any}
  --vpc-interfaces: list # The VPC interfaces you want on the flow. — item shape: {Name: any, NetworkInterfaceType?: any, RoleArn: any, SecurityGroupIds: any, SubnetId: any}
  --maintenance: record # Create maintenance setting for a flow — shape: {MaintenanceDay?: any, MaintenanceStartHour?: any}
]: any -> record<Flow: record<AvailabilityZone: record, Description: record, EgressIp: record, Entitlements: record, FlowArn: record, MediaStreams: record, Name: record, Outputs: record, Source: record<DataTransferSubscriberFeePercent: record, Decryption: record, Description: record, EntitlementArn: record, IngestIp: record, IngestPort: record, MediaStreamSourceConfigurations: record, Name: record, SenderControlPort: record, SenderIpAddress: record, SourceArn: record, Transport: record, VpcInterfaceName: record, WhitelistCidr: record, GatewayBridgeSource: record>, SourceFailoverConfig: record<FailoverMode: record, RecoveryWindow: record, SourcePriority: record, State: record>, Sources: record, Status: record, VpcInterfaces: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartHour: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/flows")
  let req_body = {"availabilityZone": $availability_zone, "entitlements": $entitlements, "mediaStreams": $media_streams, "name": $name, "outputs": $outputs, "source": $body_source, "sourceFailoverConfig": $source_failover_config, "sources": $sources, "vpcInterfaces": $vpc_interfaces, "maintenance": $maintenance} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Displays a list of flows that are associated with this account. This request returns a paginated result.
#
# GET /v1/flows
# operationId: ListFlows
export def "flows list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListFlows request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListFlows request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListFlows request a second time and specify the NextToken value.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Flows: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/flows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates a new gateway. The request must include at least one network (up to 4).
#
# POST /v1/gateways
# operationId: CreateGateway
# --networks item shape: {CidrBlock: any, Name: any}
export def "gateways create" [
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
  egress_cidr_blocks: list<string> # The range of IP addresses that are allowed to contribute content or initiate output requests for flows communicating with this gateway. These IP addresses should be in the form of a Classless Inter-Domain Routing (CIDR) block; for example, 10.0.0.0/16.
  name: string # The name of the gateway. This name can not be modified after the gateway is created.
  networks: list # The list of networks that you want to add. — item shape: {CidrBlock: any, Name: any}
]: any -> record<Gateway: record<EgressCidrBlocks: record, GatewayArn: record, GatewayMessages: record, GatewayState: record, Name: record, Networks: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/gateways")
  let req_body = {"egressCidrBlocks": $egress_cidr_blocks, "name": $name, "networks": $networks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Displays a list of gateways that are associated with this account. This request returns a paginated result.
#
# GET /v1/gateways
# operationId: ListGateways
export def "gateways list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListGateways request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListGateways request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListGateways request a second time and specify the NextToken value.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Gateways: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/gateways" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Deletes a bridge. Before you can delete a bridge, you must stop the bridge.
#
# DELETE /v1/bridges/{bridgeArn}
# operationId: DeleteBridge
export def "bridges delete" [
  bridge_arn: string
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
]: nothing -> record<BridgeArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bridge_arn | is-empty) { error make --unspanned { msg: "path parameter 'bridgeArn' must be non-empty" } }
  let full_url = (build-url $base ({bridge_arn: (encode-path-segment $bridge_arn)} | format pattern "/v1/bridges/{bridge_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Displays the details of a bridge.
#
# GET /v1/bridges/{bridgeArn}
# operationId: DescribeBridge
export def "bridges get" [
  bridge_arn: string
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
]: nothing -> record<Bridge: record<BridgeArn: record, BridgeMessages: record, BridgeState: record, EgressGatewayBridge: record<InstanceId: record, MaxBitrate: record>, IngressGatewayBridge: record<InstanceId: record, MaxBitrate: record, MaxOutputs: record>, Name: record, Outputs: record, PlacementArn: record, SourceFailoverConfig: record<FailoverMode: record, RecoveryWindow: record, SourcePriority: record, State: record>, Sources: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bridge_arn | is-empty) { error make --unspanned { msg: "path parameter 'bridgeArn' must be non-empty" } }
  let full_url = (build-url $base ({bridge_arn: (encode-path-segment $bridge_arn)} | format pattern "/v1/bridges/{bridge_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the bridge
#
# PUT /v1/bridges/{bridgeArn}
# operationId: UpdateBridge
# --egressGatewayBridge shape: {MaxBitrate?: any}
# --ingressGatewayBridge shape: {MaxBitrate?: any, MaxOutputs?: any}
# --sourceFailoverConfig shape: {FailoverMode?: any, RecoveryWindow?: any, SourcePriority?: any, State?: any}
export def "bridges update" [
  bridge_arn: string
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
  --egress-gateway-bridge: record # shape: {MaxBitrate?: any}
  --ingress-gateway-bridge: record # shape: {MaxBitrate?: any, MaxOutputs?: any}
  --source-failover-config: record # The settings for source failover. — shape: {FailoverMode?: any, RecoveryWindow?: any, SourcePriority?: any, State?: any}
]: any -> record<Bridge: record<BridgeArn: record, BridgeMessages: record, BridgeState: record, EgressGatewayBridge: record<InstanceId: record, MaxBitrate: record>, IngressGatewayBridge: record<InstanceId: record, MaxBitrate: record, MaxOutputs: record>, Name: record, Outputs: record, PlacementArn: record, SourceFailoverConfig: record<FailoverMode: record, RecoveryWindow: record, SourcePriority: record, State: record>, Sources: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bridge_arn | is-empty) { error make --unspanned { msg: "path parameter 'bridgeArn' must be non-empty" } }
  let full_url = (build-url $base ({bridge_arn: (encode-path-segment $bridge_arn)} | format pattern "/v1/bridges/{bridge_arn}"))
  let req_body = {"egressGatewayBridge": $egress_gateway_bridge, "ingressGatewayBridge": $ingress_gateway_bridge, "sourceFailoverConfig": $source_failover_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a flow. Before you can delete a flow, you must stop the flow.
#
# DELETE /v1/flows/{flowArn}
# operationId: DeleteFlow
export def "flows delete" [
  flow_arn: string
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
]: nothing -> record<FlowArn: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn)} | format pattern "/v1/flows/{flow_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
#
# GET /v1/flows/{flowArn}
# operationId: DescribeFlow
export def "flows get" [
  flow_arn: string
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
]: nothing -> record<Flow: record<AvailabilityZone: record, Description: record, EgressIp: record, Entitlements: record, FlowArn: record, MediaStreams: record, Name: record, Outputs: record, Source: record<DataTransferSubscriberFeePercent: record, Decryption: record, Description: record, EntitlementArn: record, IngestIp: record, IngestPort: record, MediaStreamSourceConfigurations: record, Name: record, SenderControlPort: record, SenderIpAddress: record, SourceArn: record, Transport: record, VpcInterfaceName: record, WhitelistCidr: record, GatewayBridgeSource: record>, SourceFailoverConfig: record<FailoverMode: record, RecoveryWindow: record, SourcePriority: record, State: record>, Sources: record, Status: record, VpcInterfaces: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartHour: record>>, Messages: record<Errors: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn)} | format pattern "/v1/flows/{flow_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates flow
#
# PUT /v1/flows/{flowArn}
# operationId: UpdateFlow
# --sourceFailoverConfig shape: {FailoverMode?: any, RecoveryWindow?: any, SourcePriority?: any, State?: any}
# --maintenance shape: {MaintenanceDay?: any, MaintenanceScheduledDate?: any, MaintenanceStartHour?: any}
export def "flows update" [
  flow_arn: string
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
  --source-failover-config: record # The settings for source failover. — shape: {FailoverMode?: any, RecoveryWindow?: any, SourcePriority?: any, State?: any}
  --maintenance: record # Update maintenance setting for a flow — shape: {MaintenanceDay?: any, MaintenanceScheduledDate?: any, MaintenanceStartHour?: any}
]: any -> record<Flow: record<AvailabilityZone: record, Description: record, EgressIp: record, Entitlements: record, FlowArn: record, MediaStreams: record, Name: record, Outputs: record, Source: record<DataTransferSubscriberFeePercent: record, Decryption: record, Description: record, EntitlementArn: record, IngestIp: record, IngestPort: record, MediaStreamSourceConfigurations: record, Name: record, SenderControlPort: record, SenderIpAddress: record, SourceArn: record, Transport: record, VpcInterfaceName: record, WhitelistCidr: record, GatewayBridgeSource: record>, SourceFailoverConfig: record<FailoverMode: record, RecoveryWindow: record, SourcePriority: record, State: record>, Sources: record, Status: record, VpcInterfaces: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartHour: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn)} | format pattern "/v1/flows/{flow_arn}"))
  let req_body = {"sourceFailoverConfig": $source_failover_config, "maintenance": $maintenance} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a gateway. Before you can delete a gateway, you must deregister its instances and delete its bridges.
#
# DELETE /v1/gateways/{gatewayArn}
# operationId: DeleteGateway
export def "gateways delete" [
  gateway_arn: string
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
]: nothing -> record<GatewayArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($gateway_arn | is-empty) { error make --unspanned { msg: "path parameter 'gatewayArn' must be non-empty" } }
  let full_url = (build-url $base ({gateway_arn: (encode-path-segment $gateway_arn)} | format pattern "/v1/gateways/{gateway_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Displays the details of a gateway. The response includes the gateway ARN, name, and CIDR blocks, as well as details about the networks.
#
# GET /v1/gateways/{gatewayArn}
# operationId: DescribeGateway
export def "gateways get" [
  gateway_arn: string
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
]: nothing -> record<Gateway: record<EgressCidrBlocks: record, GatewayArn: record, GatewayMessages: record, GatewayState: record, Name: record, Networks: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($gateway_arn | is-empty) { error make --unspanned { msg: "path parameter 'gatewayArn' must be non-empty" } }
  let full_url = (build-url $base ({gateway_arn: (encode-path-segment $gateway_arn)} | format pattern "/v1/gateways/{gateway_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deregisters an instance. Before you deregister an instance, all bridges running on the instance must be stopped. If you want to deregister an instance without stopping the bridges, you must use the --force option.
#
# DELETE /v1/gateway-instances/{gatewayInstanceArn}
# operationId: DeregisterGatewayInstance
export def "gateway-instances delete-deregister" [
  gateway_instance_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Force the deregistration of an instance. Force will deregister an instance, even if there are bridges running on it.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<GatewayInstanceArn: record, InstanceState: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($gateway_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'gatewayInstanceArn' must be non-empty" } }
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({gateway_instance_arn: (encode-path-segment $gateway_instance_arn)} | format pattern "/v1/gateway-instances/{gateway_instance_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"force": $force} | compact), body: null}
}

# Displays the details of an instance.
#
# GET /v1/gateway-instances/{gatewayInstanceArn}
# operationId: DescribeGatewayInstance
export def "gateway-instances get" [
  gateway_instance_arn: string
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
]: nothing -> record<GatewayInstance: record<BridgePlacement: record, ConnectionStatus: record, GatewayArn: record, GatewayInstanceArn: record, InstanceId: record, InstanceMessages: record, InstanceState: record, RunningBridgeCount: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($gateway_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'gatewayInstanceArn' must be non-empty" } }
  let full_url = (build-url $base ({gateway_instance_arn: (encode-path-segment $gateway_instance_arn)} | format pattern "/v1/gateway-instances/{gateway_instance_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the configuration of an existing Gateway Instance.
#
# PUT /v1/gateway-instances/{gatewayInstanceArn}
# operationId: UpdateGatewayInstance
export def "gateway-instances update" [
  gateway_instance_arn: string
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
  --bridge-placement: string@bridge-placement-completer # The availability of the instance to host new bridges. The bridgePlacement property can be LOCKED or AVAILABLE. If it is LOCKED, no new bridges can be deployed to this instance. If it is AVAILABLE, new bridges can be added to this instance.
]: any -> record<BridgePlacement: record, GatewayInstanceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($gateway_instance_arn | is-empty) { error make --unspanned { msg: "path parameter 'gatewayInstanceArn' must be non-empty" } }
  let full_url = (build-url $base ({gateway_instance_arn: (encode-path-segment $gateway_instance_arn)} | format pattern "/v1/gateway-instances/{gateway_instance_arn}"))
  let req_body = {"bridgePlacement": $bridge_placement} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Displays the details of an offering. The response includes the offering description, duration, outbound bandwidth, price, and Amazon Resource Name (ARN).
#
# GET /v1/offerings/{offeringArn}
# operationId: DescribeOffering
export def "offerings get" [
  offering_arn: string
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
]: nothing -> record<Offering: record<CurrencyCode: record, Duration: record, DurationUnits: record, OfferingArn: record, OfferingDescription: record, PricePerUnit: record, PriceUnits: record, ResourceSpecification: record<ReservedBitrate: record, ResourceType: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($offering_arn | is-empty) { error make --unspanned { msg: "path parameter 'offeringArn' must be non-empty" } }
  let full_url = (build-url $base ({offering_arn: (encode-path-segment $offering_arn)} | format pattern "/v1/offerings/{offering_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Submits a request to purchase an offering. If you already have an active reservation, you can't purchase another offering.
#
# POST /v1/offerings/{offeringArn}
# operationId: PurchaseOffering
export def "offerings create-purchase" [
  offering_arn: string
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
  reservation_name: string # The name that you want to use for the reservation.
  start: string # The date and time that you want the reservation to begin, in Coordinated Universal Time (UTC). You can specify any date and time between 12:00am on the first day of the current month to the current time on today's date, inclusive. Specify the start in a 24-hour notation. Use the following format: YYYY-MM-DDTHH:mm:SSZ, where T and Z are literal characters. For example, to specify 11:30pm on March 5, 2020, enter 2020-03-05T23:30:00Z.
]: any -> record<Reservation: record<CurrencyCode: record, Duration: record, DurationUnits: record, End: record, OfferingArn: record, OfferingDescription: record, PricePerUnit: record, PriceUnits: record, ReservationArn: record, ReservationName: record, ReservationState: record, ResourceSpecification: record<ReservedBitrate: record, ResourceType: record>, Start: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($offering_arn | is-empty) { error make --unspanned { msg: "path parameter 'offeringArn' must be non-empty" } }
  let full_url = (build-url $base ({offering_arn: (encode-path-segment $offering_arn)} | format pattern "/v1/offerings/{offering_arn}"))
  let req_body = {"reservationName": $reservation_name, "start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Displays the details of a reservation. The response includes the reservation name, state, start date and time, and the details of the offering that make up the rest of the reservation (such as price, duration, and outbound bandwidth).
#
# GET /v1/reservations/{reservationArn}
# operationId: DescribeReservation
export def "reservations get" [
  reservation_arn: string
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
]: nothing -> record<Reservation: record<CurrencyCode: record, Duration: record, DurationUnits: record, End: record, OfferingArn: record, OfferingDescription: record, PricePerUnit: record, PriceUnits: record, ReservationArn: record, ReservationName: record, ReservationState: record, ResourceSpecification: record<ReservedBitrate: record, ResourceType: record>, Start: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reservation_arn | is-empty) { error make --unspanned { msg: "path parameter 'reservationArn' must be non-empty" } }
  let full_url = (build-url $base ({reservation_arn: (encode-path-segment $reservation_arn)} | format pattern "/v1/reservations/{reservation_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Grants entitlements to an existing flow.
#
# POST /v1/flows/{flowArn}/entitlements
# operationId: GrantFlowEntitlements
# --entitlements item shape: {DataTransferSubscriberFeePercent?: any, Description?: any, Encryption?: any, EntitlementStatus?: any, Name?: any, Subscribers: any}
export def "flows-entitlements create-grant" [
  flow_arn: string
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
  entitlements: list # The list of entitlements that you want to grant. — item shape: {DataTransferSubscriberFeePercent?: any, Description?: any, Encryption?: any, EntitlementStatus?: any, Name?: any, Subscribers: any}
]: any -> record<Entitlements: record, FlowArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn)} | format pattern "/v1/flows/{flow_arn}/entitlements"))
  let req_body = {"entitlements": $entitlements} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
#
# GET /v1/entitlements
# operationId: ListEntitlements
export def "entitlements list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListEntitlements request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 20 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListEntitlements request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListEntitlements request a second time and specify the NextToken value.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Entitlements: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/entitlements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Displays a list of instances associated with the AWS account. This request returns a paginated result. You can use the filterArn property to display only the instances associated with the selected Gateway Amazon Resource Name (ARN).
#
# GET /v1/gateway-instances
# operationId: ListGatewayInstances
export def "gateway-instances list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-arn: string # Filter the list results to display only the instances associated with the selected Gateway Amazon Resource Name (ARN).
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListInstances request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListInstances request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListInstances request a second time and specify the NextToken value.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Instances: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterArn" $filter_arn "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/gateway-instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filterArn": $filter_arn, "maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Displays a list of all offerings that are available to this account in the current AWS Region. If you have an active reservation (which means you've purchased an offering that has already started and hasn't expired yet), your account isn't eligible for other offerings.
#
# GET /v1/offerings
# operationId: ListOfferings
export def "offerings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListOfferings request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListOfferings request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListOfferings request a second time and specify the NextToken value.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, Offerings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/offerings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Displays a list of all reservations that have been purchased by this account in the current AWS Region. This list includes all reservations in all states (such as active and expired).
#
# GET /v1/reservations
# operationId: ListReservations
export def "reservations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return per API request. For example, you submit a ListReservations request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  --next-token: string # The token that identifies which batch of results that you want to see. For example, you submit a ListReservations request with MaxResults set at 5. The service returns the first batch of results (up to 5) and a NextToken value. To see the next batch of results, you can submit the ListOfferings request a second time and specify the NextToken value.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, Reservations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/reservations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# List all tags on an AWS Elemental MediaConnect resource
#
# GET /tags/{resourceArn}
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
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
#
# POST /tags/{resourceArn}
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
  tags: record # A map from tag keys to values. Tag keys can have a maximum character length of 128 characters, and tag values can have a maximum length of 256 characters.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes an output from a bridge.
#
# DELETE /v1/bridges/{bridgeArn}/outputs/{outputName}
# operationId: RemoveBridgeOutput
export def "bridges-outputs delete" [
  bridge_arn: string
  output_name: string
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
]: nothing -> record<BridgeArn: record, OutputName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bridge_arn | is-empty) { error make --unspanned { msg: "path parameter 'bridgeArn' must be non-empty" } }
  if ($output_name | is-empty) { error make --unspanned { msg: "path parameter 'outputName' must be non-empty" } }
  let full_url = (build-url $base ({bridge_arn: (encode-path-segment $bridge_arn), output_name: (encode-path-segment $output_name)} | format pattern "/v1/bridges/{bridge_arn}/outputs/{output_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an existing bridge output.
#
# PUT /v1/bridges/{bridgeArn}/outputs/{outputName}
# operationId: UpdateBridgeOutput
# --networkOutput shape: {IpAddress?: any, NetworkName?: any, Port?: any, Protocol?: any, Ttl?: any}
export def "bridges-outputs update" [
  bridge_arn: string
  output_name: string
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
  --network-output: record # Update an existing network output. — shape: {IpAddress?: any, NetworkName?: any, Port?: any, Protocol?: any, Ttl?: any}
]: any -> record<BridgeArn: record, Output: record<FlowOutput: record<FlowArn: record, FlowSourceArn: record, Name: record>, NetworkOutput: record<IpAddress: record, Name: record, NetworkName: record, Port: record, Protocol: record, Ttl: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bridge_arn | is-empty) { error make --unspanned { msg: "path parameter 'bridgeArn' must be non-empty" } }
  if ($output_name | is-empty) { error make --unspanned { msg: "path parameter 'outputName' must be non-empty" } }
  let full_url = (build-url $base ({bridge_arn: (encode-path-segment $bridge_arn), output_name: (encode-path-segment $output_name)} | format pattern "/v1/bridges/{bridge_arn}/outputs/{output_name}"))
  let req_body = {"networkOutput": $network_output} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes a source from a bridge.
#
# DELETE /v1/bridges/{bridgeArn}/sources/{sourceName}
# operationId: RemoveBridgeSource
export def "bridges-sources delete" [
  bridge_arn: string
  source_name: string
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
]: nothing -> record<BridgeArn: record, SourceName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bridge_arn | is-empty) { error make --unspanned { msg: "path parameter 'bridgeArn' must be non-empty" } }
  if ($source_name | is-empty) { error make --unspanned { msg: "path parameter 'sourceName' must be non-empty" } }
  let full_url = (build-url $base ({bridge_arn: (encode-path-segment $bridge_arn), source_name: (encode-path-segment $source_name)} | format pattern "/v1/bridges/{bridge_arn}/sources/{source_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an existing bridge source.
#
# PUT /v1/bridges/{bridgeArn}/sources/{sourceName}
# operationId: UpdateBridgeSource
# --flowSource shape: {FlowArn?: any, FlowVpcInterfaceAttachment?: any}
# --networkSource shape: {MulticastIp?: any, NetworkName?: any, Port?: any, Protocol?: any}
export def "bridges-sources update" [
  bridge_arn: string
  source_name: string
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
  --flow-source: record # Update the flow source of the bridge. — shape: {FlowArn?: any, FlowVpcInterfaceAttachment?: any}
  --network-source: record # Update the network source of the bridge. — shape: {MulticastIp?: any, NetworkName?: any, Port?: any, Protocol?: any}
]: any -> record<BridgeArn: record, Source: record<FlowSource: record<FlowArn: record, FlowVpcInterfaceAttachment: record, Name: record, OutputArn: record>, NetworkSource: record<MulticastIp: record, Name: record, NetworkName: record, Port: record, Protocol: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bridge_arn | is-empty) { error make --unspanned { msg: "path parameter 'bridgeArn' must be non-empty" } }
  if ($source_name | is-empty) { error make --unspanned { msg: "path parameter 'sourceName' must be non-empty" } }
  let full_url = (build-url $base ({bridge_arn: (encode-path-segment $bridge_arn), source_name: (encode-path-segment $source_name)} | format pattern "/v1/bridges/{bridge_arn}/sources/{source_name}"))
  let req_body = {"flowSource": $flow_source, "networkSource": $network_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes a media stream from a flow. This action is only available if the media stream is not associated with a source or output.
#
# DELETE /v1/flows/{flowArn}/mediaStreams/{mediaStreamName}
# operationId: RemoveFlowMediaStream
export def "flows-media-streams delete" [
  flow_arn: string
  media_stream_name: string
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
]: nothing -> record<FlowArn: record, MediaStreamName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  if ($media_stream_name | is-empty) { error make --unspanned { msg: "path parameter 'mediaStreamName' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn), media_stream_name: (encode-path-segment $media_stream_name)} | format pattern "/v1/flows/{flow_arn}/mediaStreams/{media_stream_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an existing media stream.
#
# PUT /v1/flows/{flowArn}/mediaStreams/{mediaStreamName}
# operationId: UpdateFlowMediaStream
# --attributes shape: {Fmtp?: any, Lang?: any}
export def "flows-media-streams update" [
  flow_arn: string
  media_stream_name: string
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
  --attributes: record # Attributes that are related to the media stream. — shape: {Fmtp?: any, Lang?: any}
  --clock-rate: int # The sample rate (in Hz) for the stream. If the media stream type is video or ancillary data, set this value to 90000. If the media stream type is audio, set this value to either 48000 or 96000.
  --description: string # Description
  --media-stream-type: string@media-stream-type-completer # The type of media stream.
  --video-format: string # The resolution of the video.
]: any -> record<FlowArn: record, MediaStream: record<Attributes: record<Fmtp: record, Lang: record>, ClockRate: record, Description: record, Fmt: record, MediaStreamId: record, MediaStreamName: record, MediaStreamType: record, VideoFormat: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  if ($media_stream_name | is-empty) { error make --unspanned { msg: "path parameter 'mediaStreamName' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn), media_stream_name: (encode-path-segment $media_stream_name)} | format pattern "/v1/flows/{flow_arn}/mediaStreams/{media_stream_name}"))
  let req_body = {"attributes": $attributes, "clockRate": $clock_rate, "description": $description, "mediaStreamType": $media_stream_type, "videoFormat": $video_format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
#
# DELETE /v1/flows/{flowArn}/outputs/{outputArn}
# operationId: RemoveFlowOutput
export def "flows-outputs delete" [
  flow_arn: string
  output_arn: string
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
]: nothing -> record<FlowArn: record, OutputArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  if ($output_arn | is-empty) { error make --unspanned { msg: "path parameter 'outputArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn), output_arn: (encode-path-segment $output_arn)} | format pattern "/v1/flows/{flow_arn}/outputs/{output_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an existing flow output.
#
# PUT /v1/flows/{flowArn}/outputs/{outputArn}
# operationId: UpdateFlowOutput
# --encryption shape: {Algorithm?: any, ConstantInitializationVector?: any, DeviceId?: any, KeyType?: any, Region?: any, ResourceId?: any, RoleArn?: any, SecretArn?: any, Url?: any}
# --mediaStreamOutputConfigurations item shape: {DestinationConfigurations?: any, EncodingName: any, EncodingParameters?: any, MediaStreamName: any}
# --vpcInterfaceAttachment shape: {VpcInterfaceName?: any}
export def "flows-outputs update" [
  flow_arn: string
  output_arn: string
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
  --cidr-allow-list: list<string> # The range of IP addresses that should be allowed to initiate output requests to this flow. These IP addresses should be in the form of a Classless Inter-Domain Routing (CIDR) block; for example, 10.0.0.0/16.
  --description: string # A description of the output. This description appears only on the AWS Elemental MediaConnect console and will not be seen by the end user.
  --destination: string # The IP address where you want to send the output.
  --encryption: record # Information about the encryption of the flow. — shape: {Algorithm?: any, ConstantInitializationVector?: any, DeviceId?: any, KeyType?: any, Region?: any, ResourceId?: any, RoleArn?: any, SecretArn?: any, Url?: any}
  --max-latency: int # The maximum latency in milliseconds. This parameter applies only to RIST-based, Zixi-based, and Fujitsu-based streams.
  --media-stream-output-configurations: list # The media streams that are associated with the output, and the parameters for those associations. — item shape: {DestinationConfigurations?: any, EncodingName: any, EncodingParameters?: any, MediaStreamName: any}
  --min-latency: int # The minimum latency in milliseconds for SRT-based streams. In streams that use the SRT protocol, this value that you set on your MediaConnect source or output represents the minimal potential latency of that connection. The latency of the stream is set to the highest number between the sender’s minimum latency and the receiver’s minimum latency.
  --port: int # The port to use when content is distributed to this output.
  --protocol: string@protocol-completer # The protocol to use for the output.
  --remote-id: string # The remote ID for the Zixi-pull stream.
  --sender-control-port: int # The port that the flow uses to send outbound requests to initiate connection with the sender.
  --sender-ip-address: string # The IP address that the flow communicates with to initiate connection with the sender.
  --smoothing-latency: int # The smoothing latency in milliseconds for RIST, RTP, and RTP-FEC streams.
  --stream-id: string # The stream ID that you want to use for this transport. This parameter applies only to Zixi and SRT caller-based streams.
  --vpc-interface-attachment: record # The settings for attaching a VPC interface to an resource. — shape: {VpcInterfaceName?: any}
]: any -> record<FlowArn: record, Output: record<DataTransferSubscriberFeePercent: record, Description: record, Destination: record, Encryption: record<Algorithm: record, ConstantInitializationVector: record, DeviceId: record, KeyType: record, Region: record, ResourceId: record, RoleArn: record, SecretArn: record, Url: record>, EntitlementArn: record, ListenerAddress: record, MediaLiveInputArn: record, MediaStreamOutputConfigurations: record, Name: record, OutputArn: record, Port: record, Transport: record<CidrAllowList: record, MaxBitrate: record, MaxLatency: record, MaxSyncBuffer: record, MinLatency: record, Protocol: record, RemoteId: record, SenderControlPort: record, SenderIpAddress: record, SmoothingLatency: record, SourceListenerAddress: record, SourceListenerPort: record, StreamId: record>, VpcInterfaceAttachment: record<VpcInterfaceName: record>, BridgeArn: record, BridgePorts: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  if ($output_arn | is-empty) { error make --unspanned { msg: "path parameter 'outputArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn), output_arn: (encode-path-segment $output_arn)} | format pattern "/v1/flows/{flow_arn}/outputs/{output_arn}"))
  let req_body = {"cidrAllowList": $cidr_allow_list, "description": $description, "destination": $destination, "encryption": $encryption, "maxLatency": $max_latency, "mediaStreamOutputConfigurations": $media_stream_output_configurations, "minLatency": $min_latency, "port": $port, "protocol": $protocol, "remoteId": $remote_id, "senderControlPort": $sender_control_port, "senderIpAddress": $sender_ip_address, "smoothingLatency": $smoothing_latency, "streamId": $stream_id, "vpcInterfaceAttachment": $vpc_interface_attachment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes a source from an existing flow. This request can be made only if there is more than one source on the flow.
#
# DELETE /v1/flows/{flowArn}/source/{sourceArn}
# operationId: RemoveFlowSource
export def "flows-source delete" [
  flow_arn: string
  source_arn: string
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
]: nothing -> record<FlowArn: record, SourceArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  if ($source_arn | is-empty) { error make --unspanned { msg: "path parameter 'sourceArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn), source_arn: (encode-path-segment $source_arn)} | format pattern "/v1/flows/{flow_arn}/source/{source_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the source of a flow.
#
# PUT /v1/flows/{flowArn}/source/{sourceArn}
# operationId: UpdateFlowSource
# --decryption shape: {Algorithm?: any, ConstantInitializationVector?: any, DeviceId?: any, KeyType?: any, Region?: any, ResourceId?: any, RoleArn?: any, SecretArn?: any, Url?: any}
# --mediaStreamSourceConfigurations item shape: {EncodingName: any, InputConfigurations?: any, MediaStreamName: any}
# --gatewayBridgeSource shape: {BridgeArn?: any, VpcInterfaceAttachment?: any}
export def "flows-source update" [
  flow_arn: string
  source_arn: string
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
  --decryption: record # Information about the encryption of the flow. — shape: {Algorithm?: any, ConstantInitializationVector?: any, DeviceId?: any, KeyType?: any, Region?: any, ResourceId?: any, RoleArn?: any, SecretArn?: any, Url?: any}
  --description: string # A description for the source. This value is not used or seen outside of the current AWS Elemental MediaConnect account.
  --entitlement-arn: string # The ARN of the entitlement that allows you to subscribe to this flow. The entitlement is set by the flow originator, and the ARN is generated as part of the originator's flow.
  --ingest-port: int # The port that the flow will be listening on for incoming content.
  --max-bitrate: int # The smoothing max bitrate (in bps) for RIST, RTP, and RTP-FEC streams.
  --max-latency: int # The maximum latency in milliseconds. This parameter applies only to RIST-based, Zixi-based, and Fujitsu-based streams.
  --max-sync-buffer: int # The size of the buffer (in milliseconds) to use to sync incoming source data.
  --media-stream-source-configurations: list # The media streams that are associated with the source, and the parameters for those associations. — item shape: {EncodingName: any, InputConfigurations?: any, MediaStreamName: any}
  --min-latency: int # The minimum latency in milliseconds for SRT-based streams. In streams that use the SRT protocol, this value that you set on your MediaConnect source or output represents the minimal potential latency of that connection. The latency of the stream is set to the highest number between the sender’s minimum latency and the receiver’s minimum latency.
  --protocol: string@protocol-completer # The protocol that is used by the source.
  --sender-control-port: int # The port that the flow uses to send outbound requests to initiate connection with the sender.
  --sender-ip-address: string # The IP address that the flow communicates with to initiate connection with the sender.
  --source-listener-address: string # Source IP or domain name for SRT-caller protocol.
  --source-listener-port: int # Source port for SRT-caller protocol.
  --stream-id: string # The stream ID that you want to use for this transport. This parameter applies only to Zixi and SRT caller-based streams.
  --vpc-interface-name: string # The name of the VPC interface to use for this source.
  --whitelist-cidr: string # The range of IP addresses that should be allowed to contribute content to your source. These IP addresses should be in the form of a Classless Inter-Domain Routing (CIDR) block; for example, 10.0.0.0/16.
  --gateway-bridge-source: record # The source configuration for cloud flows receiving a stream from a bridge. — shape: {BridgeArn?: any, VpcInterfaceAttachment?: any}
]: any -> record<FlowArn: record, Source: record<DataTransferSubscriberFeePercent: record, Decryption: record<Algorithm: record, ConstantInitializationVector: record, DeviceId: record, KeyType: record, Region: record, ResourceId: record, RoleArn: record, SecretArn: record, Url: record>, Description: record, EntitlementArn: record, IngestIp: record, IngestPort: record, MediaStreamSourceConfigurations: record, Name: record, SenderControlPort: record, SenderIpAddress: record, SourceArn: record, Transport: record<CidrAllowList: record, MaxBitrate: record, MaxLatency: record, MaxSyncBuffer: record, MinLatency: record, Protocol: record, RemoteId: record, SenderControlPort: record, SenderIpAddress: record, SmoothingLatency: record, SourceListenerAddress: record, SourceListenerPort: record, StreamId: record>, VpcInterfaceName: record, WhitelistCidr: record, GatewayBridgeSource: record<BridgeArn: record, VpcInterfaceAttachment: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  if ($source_arn | is-empty) { error make --unspanned { msg: "path parameter 'sourceArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn), source_arn: (encode-path-segment $source_arn)} | format pattern "/v1/flows/{flow_arn}/source/{source_arn}"))
  let req_body = {"decryption": $decryption, "description": $description, "entitlementArn": $entitlement_arn, "ingestPort": $ingest_port, "maxBitrate": $max_bitrate, "maxLatency": $max_latency, "maxSyncBuffer": $max_sync_buffer, "mediaStreamSourceConfigurations": $media_stream_source_configurations, "minLatency": $min_latency, "protocol": $protocol, "senderControlPort": $sender_control_port, "senderIpAddress": $sender_ip_address, "sourceListenerAddress": $source_listener_address, "sourceListenerPort": $source_listener_port, "streamId": $stream_id, "vpcInterfaceName": $vpc_interface_name, "whitelistCidr": $whitelist_cidr, "gatewayBridgeSource": $gateway_bridge_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes a VPC Interface from an existing flow. This request can be made only on a VPC interface that does not have a Source or Output associated with it. If the VPC interface is referenced by a Source or Output, you must first delete or update the Source or Output to no longer reference the VPC interface.
#
# DELETE /v1/flows/{flowArn}/vpcInterfaces/{vpcInterfaceName}
# operationId: RemoveFlowVpcInterface
export def "flows-vpc-interfaces delete" [
  flow_arn: string
  vpc_interface_name: string
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
]: nothing -> record<FlowArn: record, NonDeletedNetworkInterfaceIds: record, VpcInterfaceName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  if ($vpc_interface_name | is-empty) { error make --unspanned { msg: "path parameter 'vpcInterfaceName' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn), vpc_interface_name: (encode-path-segment $vpc_interface_name)} | format pattern "/v1/flows/{flow_arn}/vpcInterfaces/{vpc_interface_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
#
# DELETE /v1/flows/{flowArn}/entitlements/{entitlementArn}
# operationId: RevokeFlowEntitlement
export def "flows-entitlements delete" [
  flow_arn: string
  entitlement_arn: string
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
]: nothing -> record<EntitlementArn: record, FlowArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  if ($entitlement_arn | is-empty) { error make --unspanned { msg: "path parameter 'entitlementArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn), entitlement_arn: (encode-path-segment $entitlement_arn)} | format pattern "/v1/flows/{flow_arn}/entitlements/{entitlement_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
#
# PUT /v1/flows/{flowArn}/entitlements/{entitlementArn}
# operationId: UpdateFlowEntitlement
# --encryption shape: {Algorithm?: any, ConstantInitializationVector?: any, DeviceId?: any, KeyType?: any, Region?: any, ResourceId?: any, RoleArn?: any, SecretArn?: any, Url?: any}
export def "flows-entitlements update" [
  flow_arn: string
  entitlement_arn: string
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
  --description: string # A description of the entitlement. This description appears only on the AWS Elemental MediaConnect console and will not be seen by the subscriber or end user.
  --encryption: record # Information about the encryption of the flow. — shape: {Algorithm?: any, ConstantInitializationVector?: any, DeviceId?: any, KeyType?: any, Region?: any, ResourceId?: any, RoleArn?: any, SecretArn?: any, Url?: any}
  --entitlement-status: string@entitlement-status-completer # An indication of whether you want to enable the entitlement to allow access, or disable it to stop streaming content to the subscriber’s flow temporarily. If you don’t specify the entitlementStatus field in your request, MediaConnect leaves the value unchanged.
  --subscribers: list<string> # The AWS account IDs that you want to share your content with. The receiving accounts (subscribers) will be allowed to create their own flow using your content as the source.
]: any -> record<Entitlement: record<DataTransferSubscriberFeePercent: record, Description: record, Encryption: record<Algorithm: record, ConstantInitializationVector: record, DeviceId: record, KeyType: record, Region: record, ResourceId: record, RoleArn: record, SecretArn: record, Url: record>, EntitlementArn: record, EntitlementStatus: record, Name: record, Subscribers: record>, FlowArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  if ($entitlement_arn | is-empty) { error make --unspanned { msg: "path parameter 'entitlementArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn), entitlement_arn: (encode-path-segment $entitlement_arn)} | format pattern "/v1/flows/{flow_arn}/entitlements/{entitlement_arn}"))
  let req_body = {"description": $description, "encryption": $encryption, "entitlementStatus": $entitlement_status, "subscribers": $subscribers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Starts a flow.
#
# POST /v1/flows/start/{flowArn}
# operationId: StartFlow
export def "flows-start start" [
  flow_arn: string
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
]: nothing -> record<FlowArn: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn)} | format pattern "/v1/flows/start/{flow_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Stops a flow.
#
# POST /v1/flows/stop/{flowArn}
# operationId: StopFlow
export def "flows-stop stop" [
  flow_arn: string
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
]: nothing -> record<FlowArn: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flow_arn | is-empty) { error make --unspanned { msg: "path parameter 'flowArn' must be non-empty" } }
  let full_url = (build-url $base ({flow_arn: (encode-path-segment $flow_arn)} | format pattern "/v1/flows/stop/{flow_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes specified tags from a resource.
#
# DELETE /tags/{resourceArn}
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
  --tag-keys: list # The keys of the tags to be removed.
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
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}

# Updates the bridge state
#
# PUT /v1/bridges/{bridgeArn}/state
# operationId: UpdateBridgeState
export def "bridges-state update" [
  bridge_arn: string
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
  desired_state: string@desired-state-completer
]: any -> record<BridgeArn: record, DesiredState: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bridge_arn | is-empty) { error make --unspanned { msg: "path parameter 'bridgeArn' must be non-empty" } }
  let full_url = (build-url $base ({bridge_arn: (encode-path-segment $bridge_arn)} | format pattern "/v1/bridges/{bridge_arn}/state"))
  let req_body = {"desiredState": $desired_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
