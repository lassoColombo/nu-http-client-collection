# Auto-generated client for AmazonNimbleStudio v2020-08-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/nimble/2020-08-01/openapi.json
# Auth: --token flag or $env.AMAZONNIMBLESTUDIO_TOKEN

const BASE_URL = "http://nimble.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZONNIMBLESTUDIO_TOKEN | default "" }
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
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-eulas" "list-eula-acceptances" "create-launch-profile" "list-launch-profiles" "create-streaming-image" "list-streaming-images" "create-streaming-session" "list-streaming-sessions" "create-streaming-session-stream" "create-studio" "list-studios" "create-studio-component" "list-studio-components" "delete-launch-profile" "get-launch-profile" "update-launch-profile" "delete-launch-profile-member" "get-launch-profile-member" "update-launch-profile-member" "delete-streaming-image" "get-streaming-image" "update-streaming-image" "delete-streaming-session" "get-streaming-session" "delete-studio" "get-studio" "update-studio" "delete-studio-component" "get-studio-component" "update-studio-component" "delete-studio-member" "get-studio-member" "get-eula" "get-launch-profile-details" "get-launch-profile-initialization" "get-streaming-session-backup" "get-streaming-session-stream" "list-eulas" "list-launch-profile-members" "put-launch-profile-members" "list-streaming-session-backups" "list-studio-members" "put-studio-members" "list-tags-for-resource" "tag-resource" "start-streaming-session" "start-studio-sso-configuration-repair" "stop-streaming-session" "untag-resource" "commands"] | sort) } | get name | first)
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

# Accept EULAs.
#
# POST /2020-08-01/studios/{studioId}/eula-acceptances
# operationId: AcceptEulas
export def "accept-eulas" [
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
]: any -> oneof<record<eulaAcceptances: table<acceptedAt: string, acceptedBy: string, accepteeId: string, eulaAcceptanceId: string, eulaId: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/eula-acceptances") $auth.query)
  let req_body = {"eulaIds": $eula_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
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

# List EULA acceptances.
#
# GET /2020-08-01/studios/{studioId}/eula-acceptances
# operationId: ListEulaAcceptances
export def "list-eula-acceptances" [
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
]: nothing -> oneof<record<eulaAcceptances: table<acceptedAt: string, acceptedBy: string, accepteeId: string, eulaAcceptanceId: string, eulaId: string>, nextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "eulaIds" $eula_ids "multi") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/eula-acceptances") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"eulaIds": $eula_ids, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a launch profile.
#
# POST /2020-08-01/studios/{studioId}/launch-profiles
# operationId: CreateLaunchProfile
export def "create-launch-profile" [
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
  stream_configuration: record # Configuration for streaming workstations created using this launch profile. — shape: {automaticTerminationMode?: "DEACTIVATED"|"ACTIVATED", clipboardMode?: "ENABLED"|"DISABLED", ec2InstanceTypes?: list<string>, maxSessionLengthInMinutes?: int, maxStoppedSessionLengthInMinutes?: int, sessionBackup?: record, sessionPersistenceMode?: "DEACTIVATED"|"ACTIVATED", sessionStorage?: record, streamingImageIds?: list<string>, volumeConfiguration?: record}
  studio_component_ids: list<string> # Unique identifiers for a collection of studio components that can be used with this launch profile.
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
]: any -> oneof<record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles") $auth.query)
  let req_body = {"description": $description, "ec2SubnetIds": $ec2_subnet_ids, "launchProfileProtocolVersions": $launch_profile_protocol_versions, "name": $name, "streamConfiguration": $stream_configuration, "studioComponentIds": $studio_component_ids, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
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

# List all the launch profiles a studio.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles
# operationId: ListLaunchProfiles
export def "list-launch-profiles" [
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
]: nothing -> oneof<record<launchProfiles: table<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list, launchProfileId: string, launchProfileProtocolVersions: list, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record, studioComponentIds: list, tags: record, updatedAt: string, updatedBy: string, validationResults: list>, nextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "principalId" $principal_id "scalar") (serialize-qp "states" $states "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token, "principalId": $principal_id, "states": $states} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a streaming image resource in a studio.
#
# POST /2020-08-01/studios/{studioId}/streaming-images
# operationId: CreateStreamingImage
export def "create-streaming-image" [
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
]: any -> oneof<record<streamingImage: record<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record<keyArn: string, keyType: string>, eulaIds: list<string>, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-images") $auth.query)
  let req_body = {"description": $description, "ec2ImageId": $ec2_image_id, "name": $name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
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

# List the streaming image resources available to this studio. This list will contain both images provided by Amazon Web Services, as well as streaming images that you have created in your studio.
#
# GET /2020-08-01/studios/{studioId}/streaming-images
# operationId: ListStreamingImages
export def "list-streaming-images" [
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
]: nothing -> oneof<record<nextToken: string, streamingImages: table<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record, eulaIds: list, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-images") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token, "owner": $owner} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a streaming session in a studio. After invoking this operation, you must poll GetStreamingSession until the streaming session is in the READY state.
#
# POST /2020-08-01/studios/{studioId}/streaming-sessions
# operationId: CreateStreamingSession
export def "create-streaming-session" [
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
]: any -> oneof<record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions") $auth.query)
  let req_body = {"ec2InstanceType": $ec2_instance_type, "launchProfileId": $launch_profile_id, "ownedBy": $owned_by, "streamingImageId": $streaming_image_id, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
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

# Lists the streaming sessions in a studio.
#
# GET /2020-08-01/studios/{studioId}/streaming-sessions
# operationId: ListStreamingSessions
export def "list-streaming-sessions" [
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
]: nothing -> oneof<record<nextToken: string, sessions: table<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record, volumeRetentionMode: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "createdBy" $created_by "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "ownedBy" $owned_by "scalar") (serialize-qp "sessionIds" $session_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"createdBy": $created_by, "nextToken": $next_token, "ownedBy": $owned_by, "sessionIds": $session_ids} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a streaming session stream for a streaming session. After invoking this API, invoke GetStreamingSessionStream with the returned streamId to poll the resource until it is in the READY state.
#
# POST /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/streams
# operationId: CreateStreamingSessionStream
export def "create-streaming-session-stream" [
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
]: any -> oneof<record<stream: record<createdAt: string, createdBy: string, expiresAt: string, ownedBy: string, state: string, statusCode: string, streamId: string, url: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), session_id: (encode-path-segment $session_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions/{session_id}/streams") $auth.query)
  let req_body = {"expirationInSeconds": $expiration_in_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
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

# Create a new studio. When creating a studio, two IAM roles must be provided: the admin role and the user role. These roles are assumed by your users when they log in to the Nimble Studio portal. The user role must have the AmazonNimbleStudio-StudioUser managed policy attached for the portal to function properly. The admin role must have the AmazonNimbleStudio-StudioAdmin managed policy attached for the portal to function properly. You may optionally specify a KMS key in the StudioEncryptionConfiguration. In Nimble Studio, resource names, descriptions, initialization scripts, and other data you provide are always encrypted at rest using an KMS key. By default, this key is owned by Amazon Web Services and managed on your behalf. You may provide your own KMS key when calling CreateStudio to encrypt this data using a key you own and manage. When providing an KMS key during studio creation, Nimble Studio creates KMS grants in your account to provide your studio user and admin roles access to these KMS keys. If you delete this grant, the studio will no longer be accessible to your portal users. If you delete the studio KMS key, your studio will no longer be accessible.
#
# POST /2020-08-01/studios
# operationId: CreateStudio
export def "create-studio" [
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
  --studio-encryption-configuration: record # Configuration of the encryption method that is used for the studio. — shape: {keyArn?: string, keyType?: "AWS_OWNED_KEY"|"CUSTOMER_MANAGED_KEY"}
  studio_name: string # The studio name that is used in the URL of the Nimble Studio portal when accessed by Nimble Studio users.
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
  user_role_arn: string # The IAM role that studio users will assume when logging in to the Nimble Studio portal.
]: any -> oneof<record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2020-08-01/studios" $auth.query)
  let req_body = {"adminRoleArn": $admin_role_arn, "displayName": $display_name, "studioEncryptionConfiguration": $studio_encryption_configuration, "studioName": $studio_name, "tags": $tags, "userRoleArn": $user_role_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
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

# List studios in your Amazon Web Services accounts in the requested Amazon Web Services Region.
#
# GET /2020-08-01/studios
# operationId: ListStudios
export def "list-studios" [
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
]: nothing -> oneof<record<nextToken: string, studios: table<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2020-08-01/studios" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a studio component resource.
#
# POST /2020-08-01/studios/{studioId}/studio-components
# operationId: CreateStudioComponent
export def "create-studio-component" [
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
  --configuration: record # The configuration of the studio component, based on component type. — shape: {activeDirectoryConfiguration?: record, computeFarmConfiguration?: record, licenseServiceConfiguration?: record, sharedFileSystemConfiguration?: record}
  --description: string # The description. (format: password)
  --ec2-security-group-ids: list<string> # The EC2 security groups that control access to the studio component.
  --initialization-scripts: list # Initialization scripts for studio components. — item shape: {launchProfileProtocolVersion?: string, platform?: "LINUX"|"WINDOWS", runContext?: "SYSTEM_INITIALIZATION"|"USER_INITIALIZATION", script?: string}
  name: string # The name for the studio component. (format: password)
  --runtime-role-arn: string # An IAM role attached to a Studio Component that gives the studio component access to Amazon Web Services resources at anytime while the instance is running.
  --script-parameters: list # Parameters for the studio component scripts. — item shape: {key?: string, value?: string}
  --secure-initialization-role-arn: string # An IAM role attached to Studio Component when the system initialization script runs which give the studio component access to Amazon Web Services resources when the system initialization script runs.
  --subtype: string@subtype-completer # The specific subtype of a studio component.
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
  type: string@type-completer # The type of the studio component.
]: any -> oneof<record<studioComponent: record<arn: string, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list<string>, initializationScripts: list<record>, name: string, runtimeRoleArn: string, scriptParameters: list<record>, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/studio-components") $auth.query)
  let req_body = {"configuration": $configuration, "description": $description, "ec2SecurityGroupIds": $ec2_security_group_ids, "initializationScripts": $initialization_scripts, "name": $name, "runtimeRoleArn": $runtime_role_arn, "scriptParameters": $script_parameters, "secureInitializationRoleArn": $secure_initialization_role_arn, "subtype": $subtype, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
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

# Lists the StudioComponents in a studio.
#
# GET /2020-08-01/studios/{studioId}/studio-components
# operationId: ListStudioComponents
export def "list-studio-components" [
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
]: nothing -> oneof<record<nextToken: string, studioComponents: table<arn: string, configuration: record, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list, initializationScripts: list, name: string, runtimeRoleArn: string, scriptParameters: list, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "states" $states "multi") (serialize-qp "types" $types "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/studio-components") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token, "states": $states, "types": $types} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Permanently delete a launch profile.
#
# DELETE /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}
# operationId: DeleteLaunchProfile
export def "delete-launch-profile" [
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
]: nothing -> oneof<record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get a launch profile.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}
# operationId: GetLaunchProfile
export def "get-launch-profile" [
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
]: nothing -> oneof<record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update a launch profile.
#
# PATCH /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}
# operationId: UpdateLaunchProfile
export def "update-launch-profile" [
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
  --stream-configuration: record # Configuration for streaming workstations created using this launch profile. — shape: {automaticTerminationMode?: "DEACTIVATED"|"ACTIVATED", clipboardMode?: "ENABLED"|"DISABLED", ec2InstanceTypes?: list<string>, maxSessionLengthInMinutes?: int, maxStoppedSessionLengthInMinutes?: int, sessionBackup?: record, sessionPersistenceMode?: "DEACTIVATED"|"ACTIVATED", sessionStorage?: record, streamingImageIds?: list<string>, volumeConfiguration?: record}
  --studio-component-ids: list<string> # Unique identifiers for a collection of studio components that can be used with this launch profile.
]: any -> oneof<record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}") $auth.query)
  let req_body = {"description": $description, "launchProfileProtocolVersions": $launch_profile_protocol_versions, "name": $name, "streamConfiguration": $stream_configuration, "studioComponentIds": $studio_component_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Delete a user from launch profile membership.
#
# DELETE /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership/{principalId}
# operationId: DeleteLaunchProfileMember
export def "delete-launch-profile-member" [
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
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  if ($principal_id | is-empty) { error make --unspanned { msg: "path parameter 'principalId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id), principal_id: (encode-path-segment $principal_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/membership/{principal_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get a user persona in launch profile membership.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership/{principalId}
# operationId: GetLaunchProfileMember
export def "get-launch-profile-member" [
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
]: nothing -> oneof<record<member: record<identityStoreId: string, persona: string, principalId: string, sid: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  if ($principal_id | is-empty) { error make --unspanned { msg: "path parameter 'principalId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id), principal_id: (encode-path-segment $principal_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/membership/{principal_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update a user persona in launch profile membership.
#
# PATCH /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership/{principalId}
# operationId: UpdateLaunchProfileMember
export def "update-launch-profile-member" [
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
]: any -> oneof<record<member: record<identityStoreId: string, persona: string, principalId: string, sid: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  if ($principal_id | is-empty) { error make --unspanned { msg: "path parameter 'principalId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id), principal_id: (encode-path-segment $principal_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/membership/{principal_id}") $auth.query)
  let req_body = {"persona": $persona} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Delete streaming image.
#
# DELETE /2020-08-01/studios/{studioId}/streaming-images/{streamingImageId}
# operationId: DeleteStreamingImage
export def "delete-streaming-image" [
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
]: nothing -> oneof<record<streamingImage: record<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record<keyArn: string, keyType: string>, eulaIds: list<string>, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($streaming_image_id | is-empty) { error make --unspanned { msg: "path parameter 'streamingImageId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), streaming_image_id: (encode-path-segment $streaming_image_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-images/{streaming_image_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get streaming image.
#
# GET /2020-08-01/studios/{studioId}/streaming-images/{streamingImageId}
# operationId: GetStreamingImage
export def "get-streaming-image" [
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
]: nothing -> oneof<record<streamingImage: record<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record<keyArn: string, keyType: string>, eulaIds: list<string>, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($streaming_image_id | is-empty) { error make --unspanned { msg: "path parameter 'streamingImageId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), streaming_image_id: (encode-path-segment $streaming_image_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-images/{streaming_image_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update streaming image.
#
# PATCH /2020-08-01/studios/{studioId}/streaming-images/{streamingImageId}
# operationId: UpdateStreamingImage
export def "update-streaming-image" [
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
]: any -> oneof<record<streamingImage: record<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record<keyArn: string, keyType: string>, eulaIds: list<string>, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($streaming_image_id | is-empty) { error make --unspanned { msg: "path parameter 'streamingImageId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), streaming_image_id: (encode-path-segment $streaming_image_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-images/{streaming_image_id}") $auth.query)
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes streaming session resource. After invoking this operation, use GetStreamingSession to poll the resource until it transitions to a DELETED state. A streaming session will count against your streaming session quota until it is marked DELETED.
#
# DELETE /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}
# operationId: DeleteStreamingSession
export def "delete-streaming-session" [
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
]: nothing -> oneof<record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), session_id: (encode-path-segment $session_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions/{session_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets StreamingSession resource. Invoke this operation to poll for a streaming session state while creating or deleting a session.
#
# GET /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}
# operationId: GetStreamingSession
export def "get-streaming-session" [
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
]: nothing -> oneof<record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), session_id: (encode-path-segment $session_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions/{session_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Delete a studio resource.
#
# DELETE /2020-08-01/studios/{studioId}
# operationId: DeleteStudio
export def "delete-studio" [
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
]: nothing -> oneof<record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get a studio resource.
#
# GET /2020-08-01/studios/{studioId}
# operationId: GetStudio
export def "get-studio" [
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
]: nothing -> oneof<record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update a Studio resource. Currently, this operation only supports updating the displayName of your studio.
#
# PATCH /2020-08-01/studios/{studioId}
# operationId: UpdateStudio
export def "update-studio" [
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
]: any -> oneof<record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}") $auth.query)
  let req_body = {"adminRoleArn": $admin_role_arn, "displayName": $display_name, "userRoleArn": $user_role_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes a studio component resource.
#
# DELETE /2020-08-01/studios/{studioId}/studio-components/{studioComponentId}
# operationId: DeleteStudioComponent
export def "delete-studio-component" [
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
]: nothing -> oneof<record<studioComponent: record<arn: string, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list<string>, initializationScripts: list<record>, name: string, runtimeRoleArn: string, scriptParameters: list<record>, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($studio_component_id | is-empty) { error make --unspanned { msg: "path parameter 'studioComponentId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), studio_component_id: (encode-path-segment $studio_component_id)} | format pattern "/2020-08-01/studios/{studio_id}/studio-components/{studio_component_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets a studio component resource.
#
# GET /2020-08-01/studios/{studioId}/studio-components/{studioComponentId}
# operationId: GetStudioComponent
export def "get-studio-component" [
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
]: nothing -> oneof<record<studioComponent: record<arn: string, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list<string>, initializationScripts: list<record>, name: string, runtimeRoleArn: string, scriptParameters: list<record>, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($studio_component_id | is-empty) { error make --unspanned { msg: "path parameter 'studioComponentId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), studio_component_id: (encode-path-segment $studio_component_id)} | format pattern "/2020-08-01/studios/{studio_id}/studio-components/{studio_component_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates a studio component resource.
#
# PATCH /2020-08-01/studios/{studioId}/studio-components/{studioComponentId}
# operationId: UpdateStudioComponent
export def "update-studio-component" [
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
  --configuration: record # The configuration of the studio component, based on component type. — shape: {activeDirectoryConfiguration?: record, computeFarmConfiguration?: record, licenseServiceConfiguration?: record, sharedFileSystemConfiguration?: record}
  --description: string # The description. (format: password)
  --ec2-security-group-ids: list<string> # The EC2 security groups that control access to the studio component.
  --initialization-scripts: list # Initialization scripts for studio components. — item shape: {launchProfileProtocolVersion?: string, platform?: "LINUX"|"WINDOWS", runContext?: "SYSTEM_INITIALIZATION"|"USER_INITIALIZATION", script?: string}
  --name: string # The name for the studio component. (format: password)
  --runtime-role-arn: string # An IAM role attached to a Studio Component that gives the studio component access to Amazon Web Services resources at anytime while the instance is running.
  --script-parameters: list # Parameters for the studio component scripts. — item shape: {key?: string, value?: string}
  --secure-initialization-role-arn: string # An IAM role attached to Studio Component when the system initialization script runs which give the studio component access to Amazon Web Services resources when the system initialization script runs.
  --subtype: string@subtype-completer # The specific subtype of a studio component.
  --type: string@type-completer # The type of the studio component.
]: any -> oneof<record<studioComponent: record<arn: string, configuration: record<activeDirectoryConfiguration: record, computeFarmConfiguration: record, licenseServiceConfiguration: record, sharedFileSystemConfiguration: record>, createdAt: string, createdBy: string, description: string, ec2SecurityGroupIds: list<string>, initializationScripts: list<record>, name: string, runtimeRoleArn: string, scriptParameters: list<record>, secureInitializationRoleArn: string, state: string, statusCode: string, statusMessage: string, studioComponentId: string, subtype: string, tags: record, type: string, updatedAt: string, updatedBy: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($studio_component_id | is-empty) { error make --unspanned { msg: "path parameter 'studioComponentId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), studio_component_id: (encode-path-segment $studio_component_id)} | format pattern "/2020-08-01/studios/{studio_id}/studio-components/{studio_component_id}") $auth.query)
  let req_body = {"configuration": $configuration, "description": $description, "ec2SecurityGroupIds": $ec2_security_group_ids, "initializationScripts": $initialization_scripts, "name": $name, "runtimeRoleArn": $runtime_role_arn, "scriptParameters": $script_parameters, "secureInitializationRoleArn": $secure_initialization_role_arn, "subtype": $subtype, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Delete a user from studio membership.
#
# DELETE /2020-08-01/studios/{studioId}/membership/{principalId}
# operationId: DeleteStudioMember
export def "delete-studio-member" [
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
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($principal_id | is-empty) { error make --unspanned { msg: "path parameter 'principalId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), principal_id: (encode-path-segment $principal_id)} | format pattern "/2020-08-01/studios/{studio_id}/membership/{principal_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get a user's membership in a studio.
#
# GET /2020-08-01/studios/{studioId}/membership/{principalId}
# operationId: GetStudioMember
export def "get-studio-member" [
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
]: nothing -> oneof<record<member: record<identityStoreId: string, persona: string, principalId: string, sid: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($principal_id | is-empty) { error make --unspanned { msg: "path parameter 'principalId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), principal_id: (encode-path-segment $principal_id)} | format pattern "/2020-08-01/studios/{studio_id}/membership/{principal_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get EULA.
#
# GET /2020-08-01/eulas/{eulaId}
# operationId: GetEula
export def "get-eula" [
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
]: nothing -> oneof<record<eula: record<content: string, createdAt: string, eulaId: string, name: string, updatedAt: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($eula_id | is-empty) { error make --unspanned { msg: "path parameter 'eulaId' must be non-empty" } }
  let full_url = (build-url $base ({eula_id: (encode-path-segment $eula_id)} | format pattern "/2020-08-01/eulas/{eula_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Launch profile details include the launch profile resource and summary information of resources that are used by, or available to, the launch profile. This includes the name and description of all studio components used by the launch profiles, and the name and description of streaming images that can be used with this launch profile.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/details
# operationId: GetLaunchProfileDetails
export def "get-launch-profile-details" [
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
]: nothing -> oneof<record<launchProfile: record<arn: string, createdAt: string, createdBy: string, description: string, ec2SubnetIds: list<string>, launchProfileId: string, launchProfileProtocolVersions: list<string>, name: string, state: string, statusCode: string, statusMessage: string, streamConfiguration: record<automaticTerminationMode: string, clipboardMode: string, ec2InstanceTypes: list, maxSessionLengthInMinutes: int, maxStoppedSessionLengthInMinutes: int, sessionBackup: record, sessionPersistenceMode: string, sessionStorage: record, streamingImageIds: list, volumeConfiguration: record>, studioComponentIds: list<string>, tags: record, updatedAt: string, updatedBy: string, validationResults: list<record>>, streamingImages: table<arn: string, description: string, ec2ImageId: string, encryptionConfiguration: record, eulaIds: list, name: string, owner: string, platform: string, state: string, statusCode: string, statusMessage: string, streamingImageId: string, tags: record>, studioComponentSummaries: table<createdAt: string, createdBy: string, description: string, name: string, studioComponentId: string, subtype: string, type: string, updatedAt: string, updatedBy: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/details") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get a launch profile initialization.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/init
# operationId: GetLaunchProfileInitialization
export def "get-launch-profile-initialization" [
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
  --launch-profile-protocol-versions: list # The launch profile protocol versions supported by the client. (required)
  --launch-purpose: string # The launch purpose. (required)
  --platform: string # The platform where this Launch Profile will be used, either Windows or Linux. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<launchProfileInitialization: record<activeDirectory: record<computerAttributes: list, directoryId: string, directoryName: string, dnsIpAddresses: list, organizationalUnitDistinguishedName: string, studioComponentId: string, studioComponentName: string>, ec2SecurityGroupIds: list<string>, launchProfileId: string, launchProfileProtocolVersion: string, launchPurpose: string, name: string, platform: string, systemInitializationScripts: list<record>, userInitializationScripts: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  if ($launch_profile_protocol_versions == null) { error make --unspanned { msg: "required query parameter 'launchProfileProtocolVersions' missing: pass --launch-profile-protocol-versions" } }
  if ($launch_purpose == null) { error make --unspanned { msg: "required query parameter 'launchPurpose' missing: pass --launch-purpose" } }
  if ($platform == null) { error make --unspanned { msg: "required query parameter 'platform' missing: pass --platform" } }
  let qp = [(serialize-qp "launchProfileProtocolVersions" $launch_profile_protocol_versions "multi") (serialize-qp "launchPurpose" $launch_purpose "scalar") (serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/init") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"launchProfileProtocolVersions": $launch_profile_protocol_versions, "launchPurpose": $launch_purpose, "platform": $platform} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets StreamingSessionBackup resource. Invoke this operation to poll for a streaming session backup while stopping a streaming session.
#
# GET /2020-08-01/studios/{studioId}/streaming-session-backups/{backupId}
# operationId: GetStreamingSessionBackup
export def "get-streaming-session-backup" [
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
]: nothing -> oneof<record<streamingSessionBackup: record<arn: string, backupId: string, createdAt: string, launchProfileId: string, ownedBy: string, sessionId: string, state: string, statusCode: string, statusMessage: string, tags: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($backup_id | is-empty) { error make --unspanned { msg: "path parameter 'backupId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), backup_id: (encode-path-segment $backup_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-session-backups/{backup_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets a StreamingSessionStream for a streaming session. Invoke this operation to poll the resource after invoking CreateStreamingSessionStream. After the StreamingSessionStream changes to the READY state, the url property will contain a stream to be used with the DCV streaming client.
#
# GET /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/streams/{streamId}
# operationId: GetStreamingSessionStream
export def "get-streaming-session-stream" [
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
]: nothing -> oneof<record<stream: record<createdAt: string, createdBy: string, expiresAt: string, ownedBy: string, state: string, statusCode: string, streamId: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  if ($stream_id | is-empty) { error make --unspanned { msg: "path parameter 'streamId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), session_id: (encode-path-segment $session_id), stream_id: (encode-path-segment $stream_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions/{session_id}/streams/{stream_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List EULAs.
#
# GET /2020-08-01/eulas
# operationId: ListEulas
export def "list-eulas" [
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
]: nothing -> oneof<record<eulas: table<content: string, createdAt: string, eulaId: string, name: string, updatedAt: string>, nextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eulaIds" $eula_ids "multi") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2020-08-01/eulas" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"eulaIds": $eula_ids, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all users in a given launch profile membership.
#
# GET /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership
# operationId: ListLaunchProfileMembers
export def "list-launch-profile-members" [
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
]: nothing -> oneof<record<members: table<identityStoreId: string, persona: string, principalId: string, sid: string>, nextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/membership") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add/update users with given persona to launch profile membership.
#
# POST /2020-08-01/studios/{studioId}/launch-profiles/{launchProfileId}/membership
# operationId: PutLaunchProfileMembers
export def "put-launch-profile-members" [
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
  members: list # A list of members. — item shape: {persona: "USER", principalId: string}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($launch_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'launchProfileId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), launch_profile_id: (encode-path-segment $launch_profile_id)} | format pattern "/2020-08-01/studios/{studio_id}/launch-profiles/{launch_profile_id}/membership") $auth.query)
  let req_body = {"identityStoreId": $identity_store_id, "members": $members} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
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

# Lists the backups of a streaming session in a studio.
#
# GET /2020-08-01/studios/{studioId}/streaming-session-backups
# operationId: ListStreamingSessionBackups
export def "list-streaming-session-backups" [
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
]: nothing -> oneof<record<nextToken: string, streamingSessionBackups: table<arn: string, backupId: string, createdAt: string, launchProfileId: string, ownedBy: string, sessionId: string, state: string, statusCode: string, statusMessage: string, tags: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "ownedBy" $owned_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-session-backups") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token, "ownedBy": $owned_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all users in a given studio membership. ListStudioMembers only returns admin members.
#
# GET /2020-08-01/studios/{studioId}/membership
# operationId: ListStudioMembers
export def "list-studio-members" [
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
]: nothing -> oneof<record<members: table<identityStoreId: string, persona: string, principalId: string, sid: string>, nextToken: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/membership") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add/update users with given persona to studio membership.
#
# POST /2020-08-01/studios/{studioId}/membership
# operationId: PutStudioMembers
export def "put-studio-members" [
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
  members: list # A list of members. — item shape: {persona: "ADMINISTRATOR", principalId: string}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/membership") $auth.query)
  let req_body = {"identityStoreId": $identity_store_id, "members": $members} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
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

# Gets the tags for a resource, given its Amazon Resource Names (ARN). This operation supports ARNs for all resource types in Nimble Studio that support tags, including studio, studio component, launch profile, streaming image, and streaming session. All resources that can be tagged will contain an ARN property, so you do not have to create this ARN yourself.
#
# GET /2020-08-01/tags/{resourceArn}
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
]: nothing -> oneof<record<tags: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/2020-08-01/tags/{resource_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates tags for a resource, given its ARN.
#
# POST /2020-08-01/tags/{resourceArn}
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
  --tags: record # A collection of labels, in the form of key-value pairs, that apply to this resource.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/2020-08-01/tags/{resource_arn}") $auth.query)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Transitions sessions from the STOPPED state into the READY state. The START_IN_PROGRESS state is the intermediate state between the STOPPED and READY states.
#
# POST /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/start
# operationId: StartStreamingSession
export def "start-streaming-session" [
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
]: any -> oneof<record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), session_id: (encode-path-segment $session_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions/{session_id}/start") $auth.query)
  let req_body = {"backupId": $backup_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
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

# Repairs the IAM Identity Center configuration for a given studio. If the studio has a valid IAM Identity Center configuration currently associated with it, this operation will fail with a validation error. If the studio does not have a valid IAM Identity Center configuration currently associated with it, then a new IAM Identity Center application is created for the studio and the studio is changed to the READY state. After the IAM Identity Center application is repaired, you must use the Amazon Nimble Studio console to add administrators and users to your studio.
#
# PUT /2020-08-01/studios/{studioId}/sso-configuration
# operationId: StartStudioSSOConfigurationRepair
export def "start-studio-sso-configuration-repair" [
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
]: nothing -> oneof<record<studio: record<adminRoleArn: string, arn: string, createdAt: string, displayName: string, homeRegion: string, ssoClientId: string, state: string, statusCode: string, statusMessage: string, studioEncryptionConfiguration: record<keyArn: string, keyType: string>, studioId: string, studioName: string, studioUrl: string, tags: record, updatedAt: string, userRoleArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id)} | format pattern "/2020-08-01/studios/{studio_id}/sso-configuration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Transitions sessions from the READY state into the STOPPED state. The STOP_IN_PROGRESS state is the intermediate state between the READY and STOPPED states.
#
# POST /2020-08-01/studios/{studioId}/streaming-sessions/{sessionId}/stop
# operationId: StopStreamingSession
export def "stop-streaming-session" [
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
]: any -> oneof<record<session: record<arn: string, automaticTerminationMode: string, backupMode: string, createdAt: string, createdBy: string, ec2InstanceType: string, launchProfileId: string, maxBackupsToRetain: int, ownedBy: string, sessionId: string, sessionPersistenceMode: string, startedAt: string, startedBy: string, startedFromBackupId: string, state: string, statusCode: string, statusMessage: string, stopAt: string, stoppedAt: string, stoppedBy: string, streamingImageId: string, tags: record, terminateAt: string, updatedAt: string, updatedBy: string, volumeConfiguration: record<iops: int, size: int, throughput: int>, volumeRetentionMode: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($studio_id | is-empty) { error make --unspanned { msg: "path parameter 'studioId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({studio_id: (encode-path-segment $studio_id), session_id: (encode-path-segment $session_id)} | format pattern "/2020-08-01/studios/{studio_id}/streaming-sessions/{session_id}/stop") $auth.query)
  let req_body = {"volumeRetentionMode": $volume_retention_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Client-Token": $x_amz_client_token} | compact
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

# Deletes the tags for a resource.
#
# DELETE /2020-08-01/tags/{resourceArn}
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
  --tag-keys: list # One or more tag keys. Specify only the tag keys, not the tag values. (required)
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
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  if ($tag_keys == null) { error make --unspanned { msg: "required query parameter 'tagKeys' missing: pass --tag-keys" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/2020-08-01/tags/{resource_arn}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
