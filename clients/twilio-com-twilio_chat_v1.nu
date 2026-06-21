# Auto-generated client for Twilio - Chat v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_chat_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_CHAT_TOKEN

const BASE_URL = "https://chat.twilio.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_CHAT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://chat.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def type-completer [] { ["apn" "fcm" "gcm"] }
def type-completer-1 [] { ["private" "public"] }
def order-completer [] { ["asc" "desc"] }
def type-completer-2 [] { ["channel" "deployment"] }
def webhook-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-channel-add-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-channel-added-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-channel-destroy-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-channel-destroyed-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-channel-update-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-channel-updated-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-member-add-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-member-added-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-member-remove-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-member-removed-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-message-remove-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-message-removed-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-message-send-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-message-sent-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-message-update-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def webhooks-on-message-updated-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "credentials list" } } | get name | first)
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

# GET /v1/Credentials
#
# operationId: ListCredential
export def "credentials list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<credentials: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Credentials
#
# operationId: CreateCredential
export def "credentials create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # [GCM only] The API key for the project that was obtained from the Google Developer console for your GCM Service application credential.
  --certificate: string # [APN only] The URL encoded representation of the certificate. For example, `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEFBQAwgZYxCzAJBgNV.....A== -----END CERTIFICATE-----`
  --friendly-name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --private-key: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fGgvCI1l9s+cmBY3WIz+cUDqmxiieR. -----END RSA PRIVATE KEY-----`
  --sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
  type: string@type-completer
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base "/v1/Credentials")
  let req_body = {"ApiKey": $api_key, "Certificate": $certificate, "FriendlyName": $friendly_name, "PrivateKey": $private_key, "Sandbox": $sandbox, "Secret": $secret, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /v1/Credentials/{Sid}
#
# operationId: DeleteCredential
export def "credentials delete" [
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Credentials/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Credentials/{Sid}
#
# operationId: FetchCredential
export def "credentials get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Credentials/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Credentials/{Sid}
#
# operationId: UpdateCredential
export def "credentials update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # [GCM only] The API key for the project that was obtained from the Google Developer console for your GCM Service application credential.
  --certificate: string # [APN only] The URL encoded representation of the certificate. For example, `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEFBQAwgZYxCzAJBgNV.....A== -----END CERTIFICATE-----`
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --private-key: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fGgvCI1l9s+cmBY3WIz+cUDqmxiieR. -----END RSA PRIVATE KEY-----`
  --sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Credentials/{sid}"))
  let req_body = {"ApiKey": $api_key, "Certificate": $certificate, "FriendlyName": $friendly_name, "PrivateKey": $private_key, "Sandbox": $sandbox, "Secret": $secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Services
#
# operationId: ListService
export def "services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list, webhook_method: string, webhooks: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Services
#
# operationId: CreateService
export def "services create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string, webhooks: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base "/v1/Services")
  let req_body = {"FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Services/{ServiceSid}/Channels
#
# operationId: ListChannel
export def "services-channels list" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: list<string> # The visibility of the Channels to read. Can be: `public` or `private` and defaults to `public`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<channels: table<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let qp = [(serialize-qp "Type" $type "multi") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Channels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Type": $type, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Services/{ServiceSid}/Channels
#
# operationId: CreateChannel
export def "services-channels create" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # A valid JSON string that contains application-specific data.
  --friendly-name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --type: string@type-completer-1
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL. This value must be 64 characters or less in length and be unique within the Service.
]: any -> record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Channels"))
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name, "Type": $type, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites
#
# operationId: ListInvite
export def "services-channels-invites list" [
  service_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: list<string> # The [User](https://www.twilio.com/docs/api/chat/rest/v1/user)'s `identity` value of the resources to read. See [access tokens](https://www.twilio.com/docs/api/chat/guides/create-tokens) for more details.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<invites: table<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  let qp = [(serialize-qp "Identity" $identity "multi") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Invites") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Identity": $identity, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites
#
# operationId: CreateInvite
export def "services-channels-invites create" [
  service_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  identity: string # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/api/chat/rest/v1/user) within the [Service](https://www.twilio.com/docs/api/chat/rest/v1/service). See [access tokens](https://www.twilio.com/docs/api/chat/guides/create-tokens) for more info.
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) assigned to the new member.
]: any -> record<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Invites"))
  let req_body = {"Identity": $identity, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites/{Sid}
#
# operationId: DeleteInvite
export def "services-channels-invites delete" [
  service_sid: string
  channel_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Invites/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites/{Sid}
#
# operationId: FetchInvite
export def "services-channels-invites get" [
  service_sid: string
  channel_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Invites/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members
#
# operationId: ListMember
export def "services-channels-members list" [
  service_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: list<string> # The [User](https://www.twilio.com/docs/api/chat/rest/v1/user)'s `identity` value of the resources to read. See [access tokens](https://www.twilio.com/docs/api/chat/guides/create-tokens) for more details.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<members: table<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  let qp = [(serialize-qp "Identity" $identity "multi") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Identity": $identity, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members
#
# operationId: CreateMember
export def "services-channels-members create" [
  service_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  identity: string # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/api/chat/rest/v1/user) within the [Service](https://www.twilio.com/docs/api/chat/rest/services). See [access tokens](https://www.twilio.com/docs/api/chat/guides/create-tokens) for more details.
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) to assign to the member. The default roles are those specified on the [Service](https://www.twilio.com/docs/chat/api/services).
]: any -> record<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Members"))
  let req_body = {"Identity": $identity, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
#
# operationId: DeleteMember
export def "services-channels-members delete" [
  service_sid: string
  channel_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Members/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
#
# operationId: FetchMember
export def "services-channels-members get" [
  service_sid: string
  channel_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Members/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
#
# operationId: UpdateMember
export def "services-channels-members update" [
  service_sid: string
  channel_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-consumed-message-index: int # The index of the last [Message](https://www.twilio.com/docs/api/chat/rest/messages) that the Member has read within the [Channel](https://www.twilio.com/docs/api/chat/rest/channels). (nullable)
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) to assign to the member. The default roles are those specified on the [Service](https://www.twilio.com/docs/chat/api/services).
]: any -> record<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Members/{sid}"))
  let req_body = {"LastConsumedMessageIndex": $last_consumed_message_index, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages
#
# operationId: ListMessage
export def "services-channels-messages list" [
  service_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer # The sort order of the returned messages. Can be: `asc` (ascending) or `desc` (descending) with `asc` as the default.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<messages: table<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  let qp = [(serialize-qp "Order" $order "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Messages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Order": $order, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages
#
# operationId: CreateMessage
export def "services-channels-messages create" [
  service_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # A valid JSON string that contains application-specific data.
  body: string # The message to send to the channel. Can also be an empty string or `null`, which sets the value as an empty string. You can send structured data in the body by serializing it as a string.
  --body-from: string # The [identity](https://www.twilio.com/docs/api/chat/guides/identity) of the new message's author. The default value is `system`.
]: any -> record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Messages"))
  let req_body = {"Attributes": $attributes, "Body": $body, "From": $body_from} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
#
# operationId: DeleteMessage
export def "services-channels-messages delete" [
  service_sid: string
  channel_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Messages/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
#
# operationId: FetchMessage
export def "services-channels-messages get" [
  service_sid: string
  channel_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Messages/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
#
# operationId: UpdateMessage
export def "services-channels-messages update" [
  service_sid: string
  channel_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # A valid JSON string that contains application-specific data.
  --body: string # The message to send to the channel. Can also be an empty string or `null`, which sets the value as an empty string. You can send structured data in the body by serializing it as a string.
]: any -> record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Channels/{channel_sid}/Messages/{sid}"))
  let req_body = {"Attributes": $attributes, "Body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /v1/Services/{ServiceSid}/Channels/{Sid}
#
# operationId: DeleteChannel
export def "services-channels delete" [
  service_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Channels/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Services/{ServiceSid}/Channels/{Sid}
#
# operationId: FetchChannel
export def "services-channels get" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Channels/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Services/{ServiceSid}/Channels/{Sid}
#
# operationId: UpdateChannel
export def "services-channels update" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # A valid JSON string that contains application-specific data.
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL. This value must be 64 characters or less in length and be unique within the Service.
]: any -> record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Channels/{sid}"))
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Services/{ServiceSid}/Roles
#
# operationId: ListRole
export def "services-roles list" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, roles: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list, service_sid: string, sid: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Roles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Services/{ServiceSid}/Roles
#
# operationId: CreateRole
export def "services-roles create" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  permission: list<string> # A permission that you grant to the new role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. The values for this parameter depend on the role's `type` and are described in the documentation.
  type: string@type-completer-2
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Roles"))
  let req_body = {"FriendlyName": $friendly_name, "Permission": $permission, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /v1/Services/{ServiceSid}/Roles/{Sid}
#
# operationId: DeleteRole
export def "services-roles delete" [
  service_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Roles/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Services/{ServiceSid}/Roles/{Sid}
#
# operationId: FetchRole
export def "services-roles get" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Roles/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Services/{ServiceSid}/Roles/{Sid}
#
# operationId: UpdateRole
export def "services-roles update" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  permission: list<string> # A permission that you grant to the role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. The values for this parameter depend on the role's `type` and are described in the documentation.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Roles/{sid}"))
  let req_body = {"Permission": $permission} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Services/{ServiceSid}/Users
#
# operationId: ListUser
export def "services-users list" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, users: table<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Services/{ServiceSid}/Users
#
# operationId: CreateUser
export def "services-users create" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # A valid JSON string that contains application-specific data.
  --friendly-name: string # A descriptive string that you create to describe the new resource. This value is often used for display purposes.
  identity: string # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/api/chat/rest/v1/user) within the [Service](https://www.twilio.com/docs/api/chat/rest/v1/service). This value is often a username or email address. See the Identity documentation for more details.
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) assigned to the new User.
]: any -> record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/Users"))
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name, "Identity": $identity, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /v1/Services/{ServiceSid}/Users/{Sid}
#
# operationId: DeleteUser
export def "services-users delete" [
  service_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Users/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Services/{ServiceSid}/Users/{Sid}
#
# operationId: FetchUser
export def "services-users get" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Users/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Services/{ServiceSid}/Users/{Sid}
#
# operationId: UpdateUser
export def "services-users update" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # A valid JSON string that contains application-specific data.
  --friendly-name: string # A descriptive string that you create to describe the resource. It is often used for display purposes.
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) assigned to this user.
]: any -> record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/Users/{sid}"))
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# List all Channels for a given User.
#
# GET /v1/Services/{ServiceSid}/Users/{UserSid}/Channels
# operationId: ListUserChannel
export def "services-users-channels list" [
  service_sid: string
  user_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<channels: table<account_sid: string, channel_sid: string, last_consumed_message_index: int, links: record, member_sid: string, service_sid: string, status: string, unread_messages_count: int>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($user_sid | is-empty) { error make --unspanned { msg: "path parameter 'UserSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), user_sid: (encode-path-segment $user_sid)} | format pattern "/v1/Services/{service_sid}/Users/{user_sid}/Channels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# DELETE /v1/Services/{Sid}
#
# operationId: DeleteService
export def "services delete" [
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Services/{Sid}
#
# operationId: FetchService
export def "services get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string, webhooks: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Services/{Sid}
#
# operationId: UpdateService
export def "services update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --consumption-report-interval: int # DEPRECATED. The interval in seconds between consumption reports submission batches from client endpoints.
  --default-channel-creator-role-sid: string # The channel role assigned to a channel creator when they join a new channel. See the [Roles endpoint](https://www.twilio.com/docs/chat/api/roles) for more details.
  --default-channel-role-sid: string # The channel role assigned to users when they are added to a channel. See the [Roles endpoint](https://www.twilio.com/docs/chat/api/roles) for more details.
  --default-service-role-sid: string # The service role assigned to users when they are added to the service. See the [Roles endpoint](https://www.twilio.com/docs/chat/api/roles) for more details.
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --limits-channel-members: int # The maximum number of Members that can be added to Channels within this Service. Can be up to 1,000.
  --limits-user-channels: int # The maximum number of Channels Users can be a Member of within this Service. Can be up to 1,000.
  --notifications-added-to-channel-enabled: oneof<nothing, bool> # Whether to send a notification when a member is added to a channel. Can be: `true` or `false` and the default is `false`.
  --notifications-added-to-channel-template: string # The template to use to create the notification text displayed when a member is added to a channel and `notifications.added_to_channel.enabled` is `true`.
  --notifications-invited-to-channel-enabled: oneof<nothing, bool> # Whether to send a notification when a user is invited to a channel. Can be: `true` or `false` and the default is `false`.
  --notifications-invited-to-channel-template: string # The template to use to create the notification text displayed when a user is invited to a channel and `notifications.invited_to_channel.enabled` is `true`.
  --notifications-new-message-enabled: oneof<nothing, bool> # Whether to send a notification when a new message is added to a channel. Can be: `true` or `false` and the default is `false`.
  --notifications-new-message-template: string # The template to use to create the notification text displayed when a new message is added to a channel and `notifications.new_message.enabled` is `true`.
  --notifications-removed-from-channel-enabled: oneof<nothing, bool> # Whether to send a notification to a user when they are removed from a channel. Can be: `true` or `false` and the default is `false`.
  --notifications-removed-from-channel-template: string # The template to use to create the notification text displayed to a user when they are removed from a channel and `notifications.removed_from_channel.enabled` is `true`.
  --post-webhook-url: string # The URL for post-event webhooks, which are called by using the `webhook_method`. See [Webhook Events](https://www.twilio.com/docs/api/chat/webhooks) for more details. (format: uri)
  --pre-webhook-url: string # The URL for pre-event webhooks, which are called by using the `webhook_method`. See [Webhook Events](https://www.twilio.com/docs/api/chat/webhooks) for more details. (format: uri)
  --reachability-enabled: oneof<nothing, bool> # Whether to enable the [Reachability Indicator](https://www.twilio.com/docs/chat/reachability-indicator) for this Service instance. The default is `false`.
  --read-status-enabled: oneof<nothing, bool> # Whether to enable the [Message Consumption Horizon](https://www.twilio.com/docs/chat/consumption-horizon) feature. The default is `true`.
  --typing-indicator-timeout: int # How long in seconds after a `started typing` event until clients should assume that user is no longer typing, even if no `ended typing` message was received. The default is 5 seconds.
  --webhook-filters: list<string> # The list of WebHook events that are enabled for this Service instance. See [Webhook Events](https://www.twilio.com/docs/chat/webhook-events) for more details.
  --webhook-method: string@webhook-method-completer # The HTTP method to use for calls to the `pre_webhook_url` and `post_webhook_url` webhooks. Can be: `POST` or `GET` and the default is `POST`. See [Webhook Events](https://www.twilio.com/docs/chat/webhook-events) for more details. (format: http-method)
  --webhooks-on-channel-add-method: string@webhooks-on-channel-add-method-completer # The HTTP method to use when calling the `webhooks.on_channel_add.url`. (format: http-method)
  --webhooks-on-channel-add-url: string # The URL of the webhook to call in response to the `on_channel_add` event using the `webhooks.on_channel_add.method` HTTP method. (format: uri)
  --webhooks-on-channel-added-method: string@webhooks-on-channel-added-method-completer # The URL of the webhook to call in response to the `on_channel_added` event`. (format: http-method)
  --webhooks-on-channel-added-url: string # The URL of the webhook to call in response to the `on_channel_added` event using the `webhooks.on_channel_added.method` HTTP method. (format: uri)
  --webhooks-on-channel-destroy-method: string@webhooks-on-channel-destroy-method-completer # The HTTP method to use when calling the `webhooks.on_channel_destroy.url`. (format: http-method)
  --webhooks-on-channel-destroy-url: string # The URL of the webhook to call in response to the `on_channel_destroy` event using the `webhooks.on_channel_destroy.method` HTTP method. (format: uri)
  --webhooks-on-channel-destroyed-method: string@webhooks-on-channel-destroyed-method-completer # The HTTP method to use when calling the `webhooks.on_channel_destroyed.url`. (format: http-method)
  --webhooks-on-channel-destroyed-url: string # The URL of the webhook to call in response to the `on_channel_added` event using the `webhooks.on_channel_destroyed.method` HTTP method. (format: uri)
  --webhooks-on-channel-update-method: string@webhooks-on-channel-update-method-completer # The HTTP method to use when calling the `webhooks.on_channel_update.url`. (format: http-method)
  --webhooks-on-channel-update-url: string # The URL of the webhook to call in response to the `on_channel_update` event using the `webhooks.on_channel_update.method` HTTP method. (format: uri)
  --webhooks-on-channel-updated-method: string@webhooks-on-channel-updated-method-completer # The HTTP method to use when calling the `webhooks.on_channel_updated.url`. (format: http-method)
  --webhooks-on-channel-updated-url: string # The URL of the webhook to call in response to the `on_channel_updated` event using the `webhooks.on_channel_updated.method` HTTP method. (format: uri)
  --webhooks-on-member-add-method: string@webhooks-on-member-add-method-completer # The HTTP method to use when calling the `webhooks.on_member_add.url`. (format: http-method)
  --webhooks-on-member-add-url: string # The URL of the webhook to call in response to the `on_member_add` event using the `webhooks.on_member_add.method` HTTP method. (format: uri)
  --webhooks-on-member-added-method: string@webhooks-on-member-added-method-completer # The HTTP method to use when calling the `webhooks.on_channel_updated.url`. (format: http-method)
  --webhooks-on-member-added-url: string # The URL of the webhook to call in response to the `on_channel_updated` event using the `webhooks.on_channel_updated.method` HTTP method. (format: uri)
  --webhooks-on-member-remove-method: string@webhooks-on-member-remove-method-completer # The HTTP method to use when calling the `webhooks.on_member_remove.url`. (format: http-method)
  --webhooks-on-member-remove-url: string # The URL of the webhook to call in response to the `on_member_remove` event using the `webhooks.on_member_remove.method` HTTP method. (format: uri)
  --webhooks-on-member-removed-method: string@webhooks-on-member-removed-method-completer # The HTTP method to use when calling the `webhooks.on_member_removed.url`. (format: http-method)
  --webhooks-on-member-removed-url: string # The URL of the webhook to call in response to the `on_member_removed` event using the `webhooks.on_member_removed.method` HTTP method. (format: uri)
  --webhooks-on-message-remove-method: string@webhooks-on-message-remove-method-completer # The HTTP method to use when calling the `webhooks.on_message_remove.url`. (format: http-method)
  --webhooks-on-message-remove-url: string # The URL of the webhook to call in response to the `on_message_remove` event using the `webhooks.on_message_remove.method` HTTP method. (format: uri)
  --webhooks-on-message-removed-method: string@webhooks-on-message-removed-method-completer # The HTTP method to use when calling the `webhooks.on_message_removed.url`. (format: http-method)
  --webhooks-on-message-removed-url: string # The URL of the webhook to call in response to the `on_message_removed` event using the `webhooks.on_message_removed.method` HTTP method. (format: uri)
  --webhooks-on-message-send-method: string@webhooks-on-message-send-method-completer # The HTTP method to use when calling the `webhooks.on_message_send.url`. (format: http-method)
  --webhooks-on-message-send-url: string # The URL of the webhook to call in response to the `on_message_send` event using the `webhooks.on_message_send.method` HTTP method. (format: uri)
  --webhooks-on-message-sent-method: string@webhooks-on-message-sent-method-completer # The URL of the webhook to call in response to the `on_message_sent` event`. (format: http-method)
  --webhooks-on-message-sent-url: string # The URL of the webhook to call in response to the `on_message_sent` event using the `webhooks.on_message_sent.method` HTTP method. (format: uri)
  --webhooks-on-message-update-method: string@webhooks-on-message-update-method-completer # The HTTP method to use when calling the `webhooks.on_message_update.url`. (format: http-method)
  --webhooks-on-message-update-url: string # The URL of the webhook to call in response to the `on_message_update` event using the `webhooks.on_message_update.method` HTTP method. (format: uri)
  --webhooks-on-message-updated-method: string@webhooks-on-message-updated-method-completer # The HTTP method to use when calling the `webhooks.on_message_updated.url`. (format: http-method)
  --webhooks-on-message-updated-url: string # The URL of the webhook to call in response to the `on_message_updated` event using the `webhooks.on_message_updated.method` HTTP method. (format: uri)
]: any -> record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string, webhooks: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}"))
  let req_body = {"ConsumptionReportInterval": $consumption_report_interval, "DefaultChannelCreatorRoleSid": $default_channel_creator_role_sid, "DefaultChannelRoleSid": $default_channel_role_sid, "DefaultServiceRoleSid": $default_service_role_sid, "FriendlyName": $friendly_name, "Limits.ChannelMembers": $limits_channel_members, "Limits.UserChannels": $limits_user_channels, "Notifications.AddedToChannel.Enabled": $notifications_added_to_channel_enabled, "Notifications.AddedToChannel.Template": $notifications_added_to_channel_template, "Notifications.InvitedToChannel.Enabled": $notifications_invited_to_channel_enabled, "Notifications.InvitedToChannel.Template": $notifications_invited_to_channel_template, "Notifications.NewMessage.Enabled": $notifications_new_message_enabled, "Notifications.NewMessage.Template": $notifications_new_message_template, "Notifications.RemovedFromChannel.Enabled": $notifications_removed_from_channel_enabled, "Notifications.RemovedFromChannel.Template": $notifications_removed_from_channel_template, "PostWebhookUrl": $post_webhook_url, "PreWebhookUrl": $pre_webhook_url, "ReachabilityEnabled": $reachability_enabled, "ReadStatusEnabled": $read_status_enabled, "TypingIndicatorTimeout": $typing_indicator_timeout, "WebhookFilters": $webhook_filters, "WebhookMethod": $webhook_method, "Webhooks.OnChannelAdd.Method": $webhooks_on_channel_add_method, "Webhooks.OnChannelAdd.Url": $webhooks_on_channel_add_url, "Webhooks.OnChannelAdded.Method": $webhooks_on_channel_added_method, "Webhooks.OnChannelAdded.Url": $webhooks_on_channel_added_url, "Webhooks.OnChannelDestroy.Method": $webhooks_on_channel_destroy_method, "Webhooks.OnChannelDestroy.Url": $webhooks_on_channel_destroy_url, "Webhooks.OnChannelDestroyed.Method": $webhooks_on_channel_destroyed_method, "Webhooks.OnChannelDestroyed.Url": $webhooks_on_channel_destroyed_url, "Webhooks.OnChannelUpdate.Method": $webhooks_on_channel_update_method, "Webhooks.OnChannelUpdate.Url": $webhooks_on_channel_update_url, "Webhooks.OnChannelUpdated.Method": $webhooks_on_channel_updated_method, "Webhooks.OnChannelUpdated.Url": $webhooks_on_channel_updated_url, "Webhooks.OnMemberAdd.Method": $webhooks_on_member_add_method, "Webhooks.OnMemberAdd.Url": $webhooks_on_member_add_url, "Webhooks.OnMemberAdded.Method": $webhooks_on_member_added_method, "Webhooks.OnMemberAdded.Url": $webhooks_on_member_added_url, "Webhooks.OnMemberRemove.Method": $webhooks_on_member_remove_method, "Webhooks.OnMemberRemove.Url": $webhooks_on_member_remove_url, "Webhooks.OnMemberRemoved.Method": $webhooks_on_member_removed_method, "Webhooks.OnMemberRemoved.Url": $webhooks_on_member_removed_url, "Webhooks.OnMessageRemove.Method": $webhooks_on_message_remove_method, "Webhooks.OnMessageRemove.Url": $webhooks_on_message_remove_url, "Webhooks.OnMessageRemoved.Method": $webhooks_on_message_removed_method, "Webhooks.OnMessageRemoved.Url": $webhooks_on_message_removed_url, "Webhooks.OnMessageSend.Method": $webhooks_on_message_send_method, "Webhooks.OnMessageSend.Url": $webhooks_on_message_send_url, "Webhooks.OnMessageSent.Method": $webhooks_on_message_sent_method, "Webhooks.OnMessageSent.Url": $webhooks_on_message_sent_url, "Webhooks.OnMessageUpdate.Method": $webhooks_on_message_update_method, "Webhooks.OnMessageUpdate.Url": $webhooks_on_message_update_url, "Webhooks.OnMessageUpdated.Method": $webhooks_on_message_updated_method, "Webhooks.OnMessageUpdated.Url": $webhooks_on_message_updated_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}
