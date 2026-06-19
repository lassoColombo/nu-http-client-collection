# Auto-generated client for Control API v1 v1.0.14
# Source: https://api.apis.guru/v2/specs/ably.net/control/1.0.14/openapi.json
# Auth: --token flag or $env.CONTROL_API_V1_TOKEN

const BASE_URL = "https://control.ably.net/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONTROL_API_V1_TOKEN | default "" }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://control.ably.net/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["disabled" "enabled"] }
def request-mode-completer [] { ["batch" "single"] }
def rule-type-completer [] { ["amqp" "amqp/external" "aws/kinesis" "aws/lambda" "aws/sqs" "http" "http/azure-function" "http/cloudflare-worker" "http/google-cloud-function" "http/ifttt" "http/zapier" "unsupported"] }
def rule-type-completer-1 [] { ["amqp" "amqp/external" "aws/kinesis" "aws/lambda" "aws/sqs" "http" "http/azure-function" "http/cloudflare-worker" "http/google-cloud-function" "http/ifttt" "http/zapier"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts-apps get" } } | get name | first)
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

# Lists apps
#
# GET /accounts/{account_id}/apps
export def "accounts-apps get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<_links: record, accountId: string, apnsUseSandboxEndpoint: bool, id: string, name: string, status: string, tlsOnly: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/apps"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates an app
#
# POST /accounts/{account_id}/apps
export def "accounts-apps create" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apns-certificate: string # The Apple Push Notification service certificate. (nullable)
  --apns-private-key: string # The Apple Push Notification service private key. (nullable)
  --apns-use-sandbox-endpoint: oneof<nothing, bool> # The Apple Push Notification service sandbox endpoint. (nullable)
  --fcm-key: string # The Firebase Cloud Messaging key. (nullable, e.g. false)
  name: string # The name of the application for your reference only. (e.g. My App)
  --status: string@status-completer # The status of the application. Can be `enabled` or `disabled`. Enabled means available to accept inbound connections and all services are available. (e.g. enabled)
  --tls-only: oneof<nothing, bool> # Enforce TLS for all connections. (nullable, e.g. true)
]: any -> record<_links: record, accountId: string, apnsUseSandboxEndpoint: bool, id: string, name: string, status: string, tlsOnly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}/apps"))
  let req_body = {"apnsCertificate": $apns_certificate, "apnsPrivateKey": $apns_private_key, "apnsUseSandboxEndpoint": $apns_use_sandbox_endpoint, "fcmKey": $fcm_key, "name": $name, "status": $status, "tlsOnly": $tls_only} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists app keys
#
# GET /apps/{app_id}/keys
export def "apps-keys get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<appId: string, capability: record, created: int, id: string, key: string, modified: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a key
#
# POST /apps/{app_id}/keys
export def "apps-keys create" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  capabilities: list<string> # The capabilities that this key has. More information on capabilities can be found in the Ably documentation (https://ably.com/documentation/core-features/authentication#capabilities-explained).
  channels: string # Specify the channels and queues that this key can be used with.
  name: string # The name for your API key. This is a friendly name for your reference.
]: any -> record<appId: string, capability: record, created: int, id: string, key: string, modified: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/keys"))
  let req_body = {"capabilities": $capabilities, "channels": $channels, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates a key
#
# PATCH /apps/{app_id}/keys/{key_id}
export def "apps-keys update" [
  app_id: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --capabilities: list<string> # The capabilities that this key has. More information on capabilities can be found in the Ably documentation (https://ably.com/documentation/core-features/authentication#capabilities-explained).
  --channels: string # Specify the channels and queues that this key can be used with.
  --name: string # The name for your API key. This is a friendly name for your reference.
]: any -> record<appId: string, capability: record, created: int, id: string, key: string, modified: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), key_id: (encode-path-segment $key_id)} | format pattern "/apps/{app_id}/keys/{key_id}"))
  let req_body = {"capabilities": $capabilities, "channels": $channels, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Revokes a key
#
# POST /apps/{app_id}/keys/{key_id}/revoke
export def "apps-keys-revoke create" [
  app_id: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($key_id | is-empty) { error make --unspanned { msg: "path parameter 'key_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), key_id: (encode-path-segment $key_id)} | format pattern "/apps/{app_id}/keys/{key_id}/revoke"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists namespaces
#
# GET /apps/{app_id}/namespaces
export def "apps-namespaces get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<authenticated: bool, created: int, id: string, modified: int, persistLast: bool, persisted: bool, pushEnabled: bool, tlsOnly: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/namespaces"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a namespace
#
# POST /apps/{app_id}/namespaces
export def "apps-namespaces create" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authenticated: oneof<nothing, bool> # If `true`, clients will not be permitted to use (including to attach, publish, or subscribe) any channels within this namespace unless they are identified, that is, authenticated using a client ID. See the Ably Knowledge base (https://knowledge.ably.com/authenticated-and-identified-clients) for more details. (default: false, e.g. false)
  id: string # The namespace or channel name that the channel rule will apply to. For example, if you specify `namespace` the namespace will be set to `namespace` and will match with channels `namespace:*` and `namespace`. (e.g. namespace)
  --persist-last: oneof<nothing, bool> # If `true`, the last message published on a channel will be stored for 365 days. You can access the stored message only by using the channel rewind mechanism and attaching with rewind=1. Please note that for each message stored, an additional message is deducted from your monthly allocation. (default: false, e.g. false)
  --persisted: oneof<nothing, bool> # If `true`, all messages on a channel will be stored for 24 hours. You can access stored messages via the History API. Please note that for each message stored, an additional message is deducted from your monthly allocation. (default: false, e.g. false)
  --push-enabled: oneof<nothing, bool> # If `true`, publishing messages with a push payload in the extras field is permitted and can trigger the delivery of a native push notification to registered devices for the channel. (default: false, e.g. false)
  --tls-only: oneof<nothing, bool> # If `true`, only clients that are connected using TLS will be permitted to subscribe to any channels within this namespace. (default: false, e.g. false)
]: any -> record<authenticated: bool, created: int, id: string, modified: int, persistLast: bool, persisted: bool, pushEnabled: bool, tlsOnly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/namespaces"))
  let req_body = {"authenticated": $authenticated, "id": $id, "persistLast": $persist_last, "persisted": $persisted, "pushEnabled": $push_enabled, "tlsOnly": $tls_only} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a namespace
#
# DELETE /apps/{app_id}/namespaces/{namespace_id}
export def "apps-namespaces delete" [
  app_id: string
  namespace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($namespace_id | is-empty) { error make --unspanned { msg: "path parameter 'namespace_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), namespace_id: (encode-path-segment $namespace_id)} | format pattern "/apps/{app_id}/namespaces/{namespace_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a namespace
#
# PATCH /apps/{app_id}/namespaces/{namespace_id}
export def "apps-namespaces update" [
  app_id: string
  namespace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authenticated: oneof<nothing, bool> # If `true`, clients will not be permitted to use (including to attach, publish, or subscribe) any channels within this namespace unless they are identified, that is, authenticated using a client ID. See the Ably knowledge base/a> for more details. (default: false, e.g. false)
  --persist-last: oneof<nothing, bool> # If `true`, the last message published on a channel will be stored for 365 days. You can access the stored message only by using the channel rewind mechanism and attaching with rewind=1. Please note that for each message stored, an additional message is deducted from your monthly allocation. (default: false, e.g. false)
  --persisted: oneof<nothing, bool> # If `true`, all messages on a channel will be stored for 24 hours. You can access stored messages via the History API. Please note that for each message stored, an additional message is deducted from your monthly allocation. (default: false, e.g. false)
  --push-enabled: oneof<nothing, bool> # If `true`, publishing messages with a push payload in the extras field is permitted and can trigger the delivery of a native push notification to registered devices for the channel. (default: false, e.g. false)
  --tls-only: oneof<nothing, bool> # If `true`, only clients that are connected using TLS will be permitted to subscribe to any channels within this namespace. (default: false, e.g. false)
]: any -> record<authenticated: bool, created: int, id: string, modified: int, persistLast: bool, persisted: bool, pushEnabled: bool, tlsOnly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($namespace_id | is-empty) { error make --unspanned { msg: "path parameter 'namespace_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), namespace_id: (encode-path-segment $namespace_id)} | format pattern "/apps/{app_id}/namespaces/{namespace_id}"))
  let req_body = {"authenticated": $authenticated, "persistLast": $persist_last, "persisted": $persisted, "pushEnabled": $push_enabled, "tlsOnly": $tls_only} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists queues
#
# GET /apps/{app_id}/queues
export def "apps-queues get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<amqp: record<queueName: string, uri: string>, appId: string, deadletter: bool, deadletterId: string, id: string, maxLength: int, messages: record<ready: int, total: int, unacknowledged: int>, name: string, region: string, state: string, stats: record<acknowledgementRate: float, deliveryRate: float, publishRate: float>, stomp: record<destination: string, host: string, uri: string>, ttl: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/queues"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a queue
#
# POST /apps/{app_id}/queues
export def "apps-queues create" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  max_length: int # Message limit in number of messages. (e.g. 10000)
  name: string # A friendly name for your queue. (e.g. My queue)
  region: string # The data center region. US East (Virginia) or EU West (Ireland). Values are `us-east-1-a` or `eu-west-1-a`. (e.g. us-east-1-a)
  ttl: int # TTL in minutes. (e.g. 60)
]: any -> record<amqp: record<queueName: string, uri: string>, appId: string, deadletter: bool, deadletterId: string, id: string, maxLength: int, messages: record<ready: int, total: int, unacknowledged: int>, name: string, region: string, state: string, stats: record<acknowledgementRate: float, deliveryRate: float, publishRate: float>, stomp: record<destination: string, host: string, uri: string>, ttl: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/queues"))
  let req_body = {"maxLength": $max_length, "name": $name, "region": $region, "ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a queue
#
# DELETE /apps/{app_id}/queues/{queue_id}
export def "apps-queues delete" [
  app_id: string
  queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($queue_id | is-empty) { error make --unspanned { msg: "path parameter 'queue_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), queue_id: (encode-path-segment $queue_id)} | format pattern "/apps/{app_id}/queues/{queue_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists Reactor rules
#
# GET /apps/{app_id}/rules
export def "apps-rules list" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/rules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a Reactor rule
#
# POST /apps/{app_id}/rules
# Discriminator (request): ruleType = amqp, amqp/external, aws/kinesis, aws/lambda, aws/sqs, http, http/azure-function, http/cloudflare-worker, http/google-cloud-function, http/ifttt, http/zapier, unsupported
# --source shape: {channelFilter: string, type: "channel.message"|"channel.presence"|"channel.lifecycle"|"channel.occupancy"}
# --target shape: {enveloped?: bool, format: "json"|"msgpack", headers?: list, signingKeyId?: string, url: string}
export def "apps-rules create" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --request-mode: string@request-mode-completer # This is Single Request mode or Batch Request mode. Single Request mode sends each event separately to the endpoint specified by the rule. Batch Request mode rolls up multiple events into the same request. You can read more about the difference between single and batched events in the Ably documentation (https://ably.com/documentation/general/events#batching). (e.g. single)
  rule_type: string@rule-type-completer # The type of rule. See the documentation (https://ably.com/integrations) for further information.
  --body-source: record # shape: {channelFilter: string, type: "channel.message"|"channel.presence"|"channel.lifecycle"|"channel.occupancy"}
  --status: string@status-completer # The status of the rule. Rules can be enabled or disabled. (e.g. enabled)
  --target: record # shape: {enveloped?: bool, format: "json"|"msgpack", headers?: list, signingKeyId?: string, url: string}
  --links: record # nullable
  --body-app-id: string # The Ably application ID. (e.g. 28GY6a)
  --created: float # Unix timestamp representing the date and time of creation of the rule. (e.g. 1602844091815)
  --id: string # The rule ID. (e.g. 83IzAB)
  --modified: float # Unix timestamp representing the date and time of last modification of the rule. (e.g. 1614679682091)
  --version: string # API version. Events and the format of their payloads are versioned. Please see the Events documentation (https://ably.com/documentation/general/events).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/rules"))
  let req_body = {"requestMode": $request_mode, "ruleType": $rule_type, "source": $body_source, "status": $status, "target": $target, "_links": $links, "appId": $body_app_id, "created": $created, "id": $id, "modified": $modified, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a Reactor rule
#
# DELETE /apps/{app_id}/rules/{rule_id}
export def "apps-rules delete" [
  app_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'rule_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/apps/{app_id}/rules/{rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a reactor rule by rule ID
#
# GET /apps/{app_id}/rules/{rule_id}
# Discriminator (response): ruleType = amqp, amqp/external, aws/kinesis, aws/lambda, aws/sqs, http, http/azure-function, http/cloudflare-worker, http/google-cloud-function, http/ifttt, http/zapier
export def "apps-rules get" [
  app_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'rule_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/apps/{app_id}/rules/{rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a Reactor rule
#
# PATCH /apps/{app_id}/rules/{rule_id}
# Discriminator (request): ruleType = amqp, amqp/external, aws/kinesis, aws/lambda, aws/sqs, http, http/azure-function, http/cloudflare-worker, http/google-cloud-function, http/ifttt, http/zapier
# --source shape: {channelFilter: string, type: "channel.message"|"channel.presence"|"channel.lifecycle"|"channel.occupancy"}
# --target shape: {enveloped?: bool, format?: "json"|"msgpack", headers?: list, signingKeyId?: string, url?: string}
export def "apps-rules update" [
  app_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --request-mode: string@request-mode-completer # This is Single Request mode or Batch Request mode. Single Request mode sends each event separately to the endpoint specified by the rule. Batch Request mode rolls up multiple events into the same request. You can read more about the difference between single and batched events in the Ably documentation (https://ably.com/documentation/general/events#batching). (e.g. single)
  rule_type: string@rule-type-completer-1 # The type of rule. See the documentation (https://ably.com/integrations) for further information.
  --body-source: record # shape: {channelFilter: string, type: "channel.message"|"channel.presence"|"channel.lifecycle"|"channel.occupancy"}
  --status: string@status-completer # The status of the rule. Rules can be enabled or disabled. (e.g. enabled)
  --target: record # shape: {enveloped?: bool, format?: "json"|"msgpack", headers?: list, signingKeyId?: string, url?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'rule_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/apps/{app_id}/rules/{rule_id}"))
  let req_body = {"requestMode": $request_mode, "ruleType": $rule_type, "source": $body_source, "status": $status, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an app
#
# DELETE /apps/{id}
export def "apps delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/apps/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an app
#
# PATCH /apps/{id}
export def "apps update" [
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
  --apns-certificate: string # The Apple Push Notification service certificate. (nullable)
  --apns-private-key: string # The Apple Push Notification service private key. (nullable)
  --apns-use-sandbox-endpoint: oneof<nothing, bool> # The Apple Push Notification service sandbox endpoint. (nullable)
  --fcm-key: string # The Firebase Cloud Messaging key. (nullable, e.g. false)
  --name: string # The name of the application for your reference only. (e.g. My App)
  --status: string@status-completer # The status of the application. Can be `enabled` or `disabled`. Enabled means available to accept inbound connections and all services are available. (e.g. enabled)
  --tls-only: oneof<nothing, bool> # Enforce TLS for all connections. (nullable, e.g. true)
]: any -> record<_links: record, accountId: string, apnsUseSandboxEndpoint: bool, id: string, name: string, status: string, tlsOnly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/apps/{id}"))
  let req_body = {"apnsCertificate": $apns_certificate, "apnsPrivateKey": $apns_private_key, "apnsUseSandboxEndpoint": $apns_use_sandbox_endpoint, "fcmKey": $fcm_key, "name": $name, "status": $status, "tlsOnly": $tls_only} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates app's APNs info from a `.p12` file
#
# POST /apps/{id}/pkcs12
export def "apps-pkcs12 create" [
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
  p12_file: string # The `.p12` file containing the app's APNs information. (format: binary)
  p12_pass: string # The password for the corresponding `.p12` file.
]: any -> record<_links: record, accountId: string, apnsUseSandboxEndpoint: bool, id: string, name: string, status: string, tlsOnly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/apps/{id}/pkcs12"))
  let req_body = {"p12File": $p12_file, "p12Pass": $p12_pass} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["p12File"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Get token details
#
# GET /me
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: record<id: string, name: string>, token: record<capabilities: list<string>, id: int, name: string>, user: record<email: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
