# Auto-generated client for Twilio - Chat v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_chat_v2/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_CHAT_TOKEN

const BASE_URL = "https://chat.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_CHAT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def base-url-completer [] { ["https://chat.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def type-completer [] { ["apn" "fcm" "gcm"] }
def type-completer-1 [] { ["private" "public"] }
def x-twilio-webhook-enabled-completer [] { ["false" "true"] }
def order-completer [] { ["asc" "desc"] }
def configuration-method-completer [] { ["GET" "POST"] }
def type-completer-2 [] { ["studio" "trigger" "webhook"] }
def type-completer-3 [] { ["channel" "deployment"] }
def notification-level-completer [] { ["default" "muted"] }
def webhook-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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

# GET /v2/Credentials
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<credentials: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/Credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Credentials
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # [GCM only] The API key for the project that was obtained from the Google Developer console for your GCM Service application credential.
  --certificate: string # [APN only] The URL encoded representation of the certificate. For example, `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEF.....A== -----END CERTIFICATE-----`
  --friendly-name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --private-key: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fG... -----END RSA PRIVATE KEY-----`
  --sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
  type: string@type-completer
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base "/v2/Credentials")
  let req_body = {"ApiKey": $api_key, "Certificate": $certificate, "FriendlyName": $friendly_name, "PrivateKey": $private_key, "Sandbox": $sandbox, "Secret": $secret, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# DELETE /v2/Credentials/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Credentials/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Credentials/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Credentials/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Credentials/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # [GCM only] The API key for the project that was obtained from the Google Developer console for your GCM Service application credential.
  --certificate: string # [APN only] The URL encoded representation of the certificate. For example, `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEF.....A== -----END CERTIFICATE-----`
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --private-key: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fG... -----END RSA PRIVATE KEY-----`
  --sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Credentials/{sid}"))
  let req_body = {"ApiKey": $api_key, "Certificate": $certificate, "FriendlyName": $friendly_name, "PrivateKey": $private_key, "Sandbox": $sandbox, "Secret": $secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# GET /v2/Services
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, media: any, notifications: any, post_webhook_retry_count: int, post_webhook_url: string, pre_webhook_retry_count: int, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list, webhook_method: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services
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
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A descriptive string that you create to describe the new resource.
]: any -> record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, media: any, notifications: any, post_webhook_retry_count: int, post_webhook_url: string, pre_webhook_retry_count: int, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base "/v2/Services")
  let req_body = {"FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# GET /v2/Services/{ServiceSid}/Bindings
#
# operationId: ListBinding
export def "services-bindings list" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --binding-type: list<string> # The push technology used by the Binding resources to read. Can be: `apn`, `gcm`, or `fcm`. See [push notification configuration](https://www.twilio.com/docs/chat/push-notification-configuration) for more info.
  --identity: list<string> # The [User](https://www.twilio.com/docs/chat/rest/user-resource)'s `identity` value of the resources to read. See [access tokens](https://www.twilio.com/docs/chat/create-tokens) for more details.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<bindings: table<account_sid: string, binding_type: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, links: record, message_types: list, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "BindingType" $binding_type "multi") (serialize-qp "Identity" $identity "multi") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/Bindings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v2/Services/{ServiceSid}/Bindings/{Sid}
#
# operationId: DeleteBinding
export def "services-bindings delete" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Bindings/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Bindings/{Sid}
#
# operationId: FetchBinding
export def "services-bindings get" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, binding_type: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, links: record, message_types: list<string>, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Bindings/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: list<string> # The visibility of the Channels to read. Can be: `public` or `private` and defaults to `public`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<channels: table<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "Type" $type "multi") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/Channels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A valid JSON string that contains application-specific data.
  --created-by: string # The `identity` of the User that created the channel. Default is: `system`.
  --date-created: string # The date, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, to assign to the resource as the date it was created. The default value is the current time set by the Chat service. Note that this should only be used in cases where a Channel is being recreated from a backup/separate source. (format: date-time)
  --date-updated: string # The date, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, to assign to the resource as the date it was last updated. The default value is `null`. Note that this parameter should only be used in cases where a Channel is being recreated from a backup/separate source and where a Message was previously updated. (format: date-time)
  --friendly-name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --type: string@type-completer-1
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the Channel resource's `sid` in the URL. This value must be 64 characters or less in length and be unique within the Service.
]: any -> record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/Channels"))
  let req_body = {"Attributes": $attributes, "CreatedBy": $created_by, "DateCreated": $date_created, "DateUpdated": $date_updated, "FriendlyName": $friendly_name, "Type": $type, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Invites
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: list<string> # The [User](https://www.twilio.com/docs/chat/rest/user-resource)'s `identity` value of the resources to read. See [access tokens](https://www.twilio.com/docs/chat/create-tokens) for more details.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<invites: table<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "Identity" $identity "multi") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Invites") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Invites
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
  --dry-run(-n) # Return the request that would be sent without executing it
  identity: string # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/chat/rest/user-resource) within the [Service](https://www.twilio.com/docs/chat/rest/service-resource). See [access tokens](https://www.twilio.com/docs/chat/create-tokens) for more info.
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/chat/rest/role-resource) assigned to the new member.
]: any -> record<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Invites"))
  let req_body = {"Identity": $identity, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# DELETE /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Invites/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Invites/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Invites/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Invites/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Members
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: list<string> # The [User](https://www.twilio.com/docs/chat/rest/user-resource)'s `identity` value of the Member resources to read. See [access tokens](https://www.twilio.com/docs/chat/create-tokens) for more details.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<members: table<account_sid: string, attributes: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "Identity" $identity "multi") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Members
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A valid JSON string that contains application-specific data.
  --date-created: string # The date, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, to assign to the resource as the date it was created. The default value is the current time set by the Chat service. Note that this parameter should only be used when a Member is being recreated from a backup/separate source. (format: date-time)
  --date-updated: string # The date, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, to assign to the resource as the date it was last updated. The default value is `null`. Note that this parameter should only be used when a Member is being recreated from a backup/separate source and where a Member was previously updated. (format: date-time)
  identity: string # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/chat/rest/user-resource) within the [Service](https://www.twilio.com/docs/chat/rest/service-resource). See [access tokens](https://www.twilio.com/docs/chat/create-tokens) for more info.
  --last-consumed-message-index: int # The index of the last [Message](https://www.twilio.com/docs/chat/rest/message-resource) in the [Channel](https://www.twilio.com/docs/chat/channels) that the Member has read. This parameter should only be used when recreating a Member from a backup/separate source. (nullable)
  --last-consumption-timestamp: string # The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) timestamp of the last [Message](https://www.twilio.com/docs/chat/rest/message-resource) read event for the Member within the [Channel](https://www.twilio.com/docs/chat/channels). (format: date-time)
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/chat/rest/role-resource) to assign to the member. The default roles are those specified on the [Service](https://www.twilio.com/docs/chat/rest/service-resource).
]: any -> record<account_sid: string, attributes: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Members"))
  let req_body = {"Attributes": $attributes, "DateCreated": $date_created, "DateUpdated": $date_updated, "Identity": $identity, "LastConsumedMessageIndex": $last_consumed_message_index, "LastConsumptionTimestamp": $last_consumption_timestamp, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# DELETE /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Members/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Members/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A valid JSON string that contains application-specific data.
  --date-created: string # The date, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, to assign to the resource as the date it was created. The default value is the current time set by the Chat service. Note that this parameter should only be used when a Member is being recreated from a backup/separate source. (format: date-time)
  --date-updated: string # The date, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, to assign to the resource as the date it was last updated. (format: date-time)
  --last-consumed-message-index: int # The index of the last [Message](https://www.twilio.com/docs/chat/rest/message-resource) that the Member has read within the [Channel](https://www.twilio.com/docs/chat/channels). (nullable)
  --last-consumption-timestamp: string # The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) timestamp of the last [Message](https://www.twilio.com/docs/chat/rest/message-resource) read event for the Member within the [Channel](https://www.twilio.com/docs/chat/channels). (format: date-time)
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/chat/rest/role-resource) to assign to the member. The default roles are those specified on the [Service](https://www.twilio.com/docs/chat/rest/service-resource).
]: any -> record<account_sid: string, attributes: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Members/{sid}"))
  let req_body = {"Attributes": $attributes, "DateCreated": $date_created, "DateUpdated": $date_updated, "LastConsumedMessageIndex": $last_consumed_message_index, "LastConsumptionTimestamp": $last_consumption_timestamp, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Messages
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer # The sort order of the returned messages. Can be: `asc` (ascending) or `desc` (descending) with `asc` as the default.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<messages: table<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, last_updated_by: string, media: any, service_sid: string, sid: string, to: string, type: string, url: string, was_edited: bool>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "Order" $order "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Messages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Messages
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A valid JSON string that contains application-specific data.
  --body: string # The message to send to the channel. Can be an empty string or `null`, which sets the value as an empty string. You can send structured data in the body by serializing it as a string.
  --date-created: string # The date, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, to assign to the resource as the date it was created. The default value is the current time set by the Chat service. This parameter should only be used when a Chat's history is being recreated from a backup/separate source. (format: date-time)
  --date-updated: string # The date, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, to assign to the resource as the date it was last updated. (format: date-time)
  --body-from: string # The [Identity](https://www.twilio.com/docs/chat/identity) of the new message's author. The default value is `system`.
  --last-updated-by: string # The [Identity](https://www.twilio.com/docs/chat/identity) of the User who last updated the Message, if applicable.
  --media-sid: string # The SID of the [Media](https://www.twilio.com/docs/chat/rest/media) to attach to the new Message.
]: any -> record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, last_updated_by: string, media: any, service_sid: string, sid: string, to: string, type: string, url: string, was_edited: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Messages"))
  let req_body = {"Attributes": $attributes, "Body": $body, "DateCreated": $date_created, "DateUpdated": $date_updated, "From": $body_from, "LastUpdatedBy": $last_updated_by, "MediaSid": $media_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# DELETE /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Messages/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, last_updated_by: string, media: any, service_sid: string, sid: string, to: string, type: string, url: string, was_edited: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Messages/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A valid JSON string that contains application-specific data.
  --body: string # The message to send to the channel. Can be an empty string or `null`, which sets the value as an empty string. You can send structured data in the body by serializing it as a string.
  --date-created: string # The date, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, to assign to the resource as the date it was created. The default value is the current time set by the Chat service. This parameter should only be used when a Chat's history is being recreated from a backup/separate source. (format: date-time)
  --date-updated: string # The date, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, to assign to the resource as the date it was last updated. (format: date-time)
  --body-from: string # The [Identity](https://www.twilio.com/docs/chat/identity) of the message's author.
  --last-updated-by: string # The [Identity](https://www.twilio.com/docs/chat/identity) of the User who last updated the Message, if applicable.
]: any -> record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, last_updated_by: string, media: any, service_sid: string, sid: string, to: string, type: string, url: string, was_edited: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Messages/{sid}"))
  let req_body = {"Attributes": $attributes, "Body": $body, "DateCreated": $date_created, "DateUpdated": $date_updated, "From": $body_from, "LastUpdatedBy": $last_updated_by} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Webhooks
#
# operationId: ListChannelWebhook
export def "services-channels-webhooks list" [
  service_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, channel_sid: string, configuration: any, date_created: string, date_updated: string, service_sid: string, sid: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Webhooks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Webhooks
#
# operationId: CreateChannelWebhook
export def "services-channels-webhooks create" [
  service_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration-filters: list<string> # The events that cause us to call the Channel Webhook. Used when `type` is `webhook`. This parameter takes only one event. To specify more than one event, repeat this parameter for each event. For the list of possible events, see [Webhook Event Triggers](https://www.twilio.com/docs/chat/webhook-events#webhook-event-trigger).
  --configuration-flow-sid: string # The SID of the Studio [Flow](https://www.twilio.com/docs/studio/rest-api/flow) to call when an event in `configuration.filters` occurs. Used only when `type` is `studio`.
  --configuration-method: string@configuration-method-completer
  --configuration-retry-count: int # The number of times to retry the webhook if the first attempt fails. Can be an integer between 0 and 3, inclusive, and the default is 0.
  --configuration-triggers: list<string> # A string that will cause us to call the webhook when it is present in a message body. This parameter takes only one trigger string. To specify more than one, repeat this parameter for each trigger string up to a total of 5 trigger strings. Used only when `type` = `trigger`.
  --configuration-url: string # The URL of the webhook to call using the `configuration.method`.
  type: string@type-completer-2
]: any -> record<account_sid: string, channel_sid: string, configuration: any, date_created: string, date_updated: string, service_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Webhooks"))
  let req_body = {"Configuration.Filters": $configuration_filters, "Configuration.FlowSid": $configuration_flow_sid, "Configuration.Method": $configuration_method, "Configuration.RetryCount": $configuration_retry_count, "Configuration.Triggers": $configuration_triggers, "Configuration.Url": $configuration_url, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# DELETE /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Webhooks/{Sid}
#
# operationId: DeleteChannelWebhook
export def "services-channels-webhooks delete" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Webhooks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Webhooks/{Sid}
#
# operationId: FetchChannelWebhook
export def "services-channels-webhooks get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel_sid: string, configuration: any, date_created: string, date_updated: string, service_sid: string, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Webhooks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Webhooks/{Sid}
#
# operationId: UpdateChannelWebhook
export def "services-channels-webhooks update" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration-filters: list<string> # The events that cause us to call the Channel Webhook. Used when `type` is `webhook`. This parameter takes only one event. To specify more than one event, repeat this parameter for each event. For the list of possible events, see [Webhook Event Triggers](https://www.twilio.com/docs/chat/webhook-events#webhook-event-trigger).
  --configuration-flow-sid: string # The SID of the Studio [Flow](https://www.twilio.com/docs/studio/rest-api/flow) to call when an event in `configuration.filters` occurs. Used only when `type` = `studio`.
  --configuration-method: string@configuration-method-completer
  --configuration-retry-count: int # The number of times to retry the webhook if the first attempt fails. Can be an integer between 0 and 3, inclusive, and the default is 0.
  --configuration-triggers: list<string> # A string that will cause us to call the webhook when it is present in a message body. This parameter takes only one trigger string. To specify more than one, repeat this parameter for each trigger string up to a total of 5 trigger strings. Used only when `type` = `trigger`.
  --configuration-url: string # The URL of the webhook to call using the `configuration.method`.
]: any -> record<account_sid: string, channel_sid: string, configuration: any, date_created: string, date_updated: string, service_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{channel_sid}/Webhooks/{sid}"))
  let req_body = {"Configuration.Filters": $configuration_filters, "Configuration.FlowSid": $configuration_flow_sid, "Configuration.Method": $configuration_method, "Configuration.RetryCount": $configuration_retry_count, "Configuration.Triggers": $configuration_triggers, "Configuration.Url": $configuration_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# DELETE /v2/Services/{ServiceSid}/Channels/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A valid JSON string that contains application-specific data.
  --created-by: string # The `identity` of the User that created the channel. Default is: `system`.
  --date-created: string # The date, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, to assign to the resource as the date it was created. The default value is the current time set by the Chat service. Note that this should only be used in cases where a Channel is being recreated from a backup/separate source. (format: date-time)
  --date-updated: string # The date, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, to assign to the resource as the date it was last updated. (format: date-time)
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 256 characters long.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL. This value must be 256 characters or less in length and unique within the Service.
]: any -> record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Channels/{sid}"))
  let req_body = {"Attributes": $attributes, "CreatedBy": $created_by, "DateCreated": $date_created, "DateUpdated": $date_updated, "FriendlyName": $friendly_name, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# GET /v2/Services/{ServiceSid}/Roles
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, roles: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list, service_sid: string, sid: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/Roles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Roles
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
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  permission: list<string> # A permission that you grant to the new role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. The values for this parameter depend on the role's `type`.
  type: string@type-completer-3
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/Roles"))
  let req_body = {"FriendlyName": $friendly_name, "Permission": $permission, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# DELETE /v2/Services/{ServiceSid}/Roles/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Roles/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Roles/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Roles/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Roles/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
  permission: list<string> # A permission that you grant to the role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. Note that the update action replaces all previously assigned permissions with those defined in the update action. To remove a permission, do not include it in the subsequent update action. The values for this parameter depend on the role's `type`.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Roles/{sid}"))
  let req_body = {"Permission": $permission} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# GET /v2/Services/{ServiceSid}/Users
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, users: table<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/Users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Users
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A valid JSON string that contains application-specific data.
  --friendly-name: string # A descriptive string that you create to describe the new resource. This value is often used for display purposes.
  identity: string # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/chat/rest/user-resource) within the [Service](https://www.twilio.com/docs/chat/rest/service-resource). This value is often a username or email address. See the Identity documentation for more info.
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/chat/rest/role-resource) to assign to the new User.
]: any -> record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/Users"))
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name, "Identity": $identity, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# DELETE /v2/Services/{ServiceSid}/Users/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Users/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Users/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Users/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Users/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A valid JSON string that contains application-specific data.
  --friendly-name: string # A descriptive string that you create to describe the resource. It is often used for display purposes.
  --role-sid: string # The SID of the [Role](https://www.twilio.com/docs/chat/rest/role-resource) to assign to the User.
]: any -> record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Users/{sid}"))
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# GET /v2/Services/{ServiceSid}/Users/{UserSid}/Bindings
#
# operationId: ListUserBinding
export def "services-users-bindings list" [
  service_sid: string
  user_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --binding-type: list<string> # The push technology used by the User Binding resources to read. Can be: `apn`, `gcm`, or `fcm`. See [push notification configuration](https://www.twilio.com/docs/chat/push-notification-configuration) for more info.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<bindings: table<account_sid: string, binding_type: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, message_types: list, service_sid: string, sid: string, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "BindingType" $binding_type "multi") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), user_sid: (encode-path-segment $user_sid)} | format pattern "/v2/Services/{service_sid}/Users/{user_sid}/Bindings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v2/Services/{ServiceSid}/Users/{UserSid}/Bindings/{Sid}
#
# operationId: DeleteUserBinding
export def "services-users-bindings delete" [
  service_sid: string
  user_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), user_sid: (encode-path-segment $user_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Users/{user_sid}/Bindings/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Users/{UserSid}/Bindings/{Sid}
#
# operationId: FetchUserBinding
export def "services-users-bindings get" [
  service_sid: string
  user_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, binding_type: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, message_types: list<string>, service_sid: string, sid: string, url: string, user_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), user_sid: (encode-path-segment $user_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Users/{user_sid}/Bindings/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Channels for a given User.
#
# GET /v2/Services/{ServiceSid}/Users/{UserSid}/Channels
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<channels: table<account_sid: string, channel_sid: string, last_consumed_message_index: int, links: record, member_sid: string, notification_level: string, service_sid: string, status: string, unread_messages_count: int, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), user_sid: (encode-path-segment $user_sid)} | format pattern "/v2/Services/{service_sid}/Users/{user_sid}/Channels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes User from selected Channel.
#
# DELETE /v2/Services/{ServiceSid}/Users/{UserSid}/Channels/{ChannelSid}
# operationId: DeleteUserChannel
export def "services-users-channels delete" [
  service_sid: string
  user_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), user_sid: (encode-path-segment $user_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v2/Services/{service_sid}/Users/{user_sid}/Channels/{channel_sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Users/{UserSid}/Channels/{ChannelSid}
#
# operationId: FetchUserChannel
export def "services-users-channels get" [
  service_sid: string
  user_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel_sid: string, last_consumed_message_index: int, links: record, member_sid: string, notification_level: string, service_sid: string, status: string, unread_messages_count: int, url: string, user_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), user_sid: (encode-path-segment $user_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v2/Services/{service_sid}/Users/{user_sid}/Channels/{channel_sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Users/{UserSid}/Channels/{ChannelSid}
#
# operationId: UpdateUserChannel
export def "services-users-channels update" [
  service_sid: string
  user_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-consumed-message-index: int # The index of the last [Message](https://www.twilio.com/docs/chat/rest/message-resource) in the [Channel](https://www.twilio.com/docs/chat/channels) that the Member has read. (nullable)
  --last-consumption-timestamp: string # The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) timestamp of the last [Message](https://www.twilio.com/docs/chat/rest/message-resource) read event for the Member within the [Channel](https://www.twilio.com/docs/chat/channels). (format: date-time)
  --notification-level: string@notification-level-completer
]: any -> record<account_sid: string, channel_sid: string, last_consumed_message_index: int, links: record, member_sid: string, notification_level: string, service_sid: string, status: string, unread_messages_count: int, url: string, user_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), user_sid: (encode-path-segment $user_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v2/Services/{service_sid}/Users/{user_sid}/Channels/{channel_sid}"))
  let req_body = {"LastConsumedMessageIndex": $last_consumed_message_index, "LastConsumptionTimestamp": $last_consumption_timestamp, "NotificationLevel": $notification_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# DELETE /v2/Services/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, media: any, notifications: any, post_webhook_retry_count: int, post_webhook_url: string, pre_webhook_retry_count: int, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{Sid}
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --consumption-report-interval: int # DEPRECATED. The interval in seconds between consumption reports submission batches from client endpoints.
  --default-channel-creator-role-sid: string # The channel role assigned to a channel creator when they join a new channel. See the [Role resource](https://www.twilio.com/docs/chat/rest/role-resource) for more info about roles.
  --default-channel-role-sid: string # The channel role assigned to users when they are added to a channel. See the [Role resource](https://www.twilio.com/docs/chat/rest/role-resource) for more info about roles.
  --default-service-role-sid: string # The service role assigned to users when they are added to the service. See the [Role resource](https://www.twilio.com/docs/chat/rest/role-resource) for more info about roles.
  --friendly-name: string # A descriptive string that you create to describe the resource.
  --limits-channel-members: int # The maximum number of Members that can be added to Channels within this Service. Can be up to 1,000.
  --limits-user-channels: int # The maximum number of Channels Users can be a Member of within this Service. Can be up to 1,000.
  --media-compatibility-message: string # The message to send when a media message has no text. Can be used as placeholder message.
  --notifications-added-to-channel-enabled: oneof<nothing, bool> # Whether to send a notification when a member is added to a channel. The default is `false`.
  --notifications-added-to-channel-sound: string # The name of the sound to play when a member is added to a channel and `notifications.added_to_channel.enabled` is `true`.
  --notifications-added-to-channel-template: string # The template to use to create the notification text displayed when a member is added to a channel and `notifications.added_to_channel.enabled` is `true`.
  --notifications-invited-to-channel-enabled: oneof<nothing, bool> # Whether to send a notification when a user is invited to a channel. The default is `false`.
  --notifications-invited-to-channel-sound: string # The name of the sound to play when a user is invited to a channel and `notifications.invited_to_channel.enabled` is `true`.
  --notifications-invited-to-channel-template: string # The template to use to create the notification text displayed when a user is invited to a channel and `notifications.invited_to_channel.enabled` is `true`.
  --notifications-log-enabled: oneof<nothing, bool> # Whether to log notifications. The default is `false`.
  --notifications-new-message-badge-count-enabled: oneof<nothing, bool> # Whether the new message badge is enabled. The default is `false`.
  --notifications-new-message-enabled: oneof<nothing, bool> # Whether to send a notification when a new message is added to a channel. The default is `false`.
  --notifications-new-message-sound: string # The name of the sound to play when a new message is added to a channel and `notifications.new_message.enabled` is `true`.
  --notifications-new-message-template: string # The template to use to create the notification text displayed when a new message is added to a channel and `notifications.new_message.enabled` is `true`.
  --notifications-removed-from-channel-enabled: oneof<nothing, bool> # Whether to send a notification to a user when they are removed from a channel. The default is `false`.
  --notifications-removed-from-channel-sound: string # The name of the sound to play to a user when they are removed from a channel and `notifications.removed_from_channel.enabled` is `true`.
  --notifications-removed-from-channel-template: string # The template to use to create the notification text displayed to a user when they are removed from a channel and `notifications.removed_from_channel.enabled` is `true`.
  --post-webhook-retry-count: int # The number of times to retry a call to the `post_webhook_url` if the request times out (after 5 seconds) or it receives a 429, 503, or 504 HTTP response. The default is 0, which means the call won't be retried.
  --post-webhook-url: string # The URL for post-event webhooks, which are called by using the `webhook_method`. See [Webhook Events](https://www.twilio.com/docs/chat/webhook-events) for more details. (format: uri)
  --pre-webhook-retry-count: int # The number of times to retry a call to the `pre_webhook_url` if the request times out (after 5 seconds) or it receives a 429, 503, or 504 HTTP response. Default retry count is 0 times, which means the call won't be retried.
  --pre-webhook-url: string # The URL for pre-event webhooks, which are called by using the `webhook_method`. See [Webhook Events](https://www.twilio.com/docs/chat/webhook-events) for more details. (format: uri)
  --reachability-enabled: oneof<nothing, bool> # Whether to enable the [Reachability Indicator](https://www.twilio.com/docs/chat/reachability-indicator) for this Service instance. The default is `false`.
  --read-status-enabled: oneof<nothing, bool> # Whether to enable the [Message Consumption Horizon](https://www.twilio.com/docs/chat/consumption-horizon) feature. The default is `true`.
  --typing-indicator-timeout: int # How long in seconds after a `started typing` event until clients should assume that user is no longer typing, even if no `ended typing` message was received. The default is 5 seconds.
  --webhook-filters: list<string> # The list of webhook events that are enabled for this Service instance. See [Webhook Events](https://www.twilio.com/docs/chat/webhook-events) for more details.
  --webhook-method: string@webhook-method-completer # The HTTP method to use for calls to the `pre_webhook_url` and `post_webhook_url` webhooks. Can be: `POST` or `GET` and the default is `POST`. See [Webhook Events](https://www.twilio.com/docs/chat/webhook-events) for more details. (format: http-method)
]: any -> record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, media: any, notifications: any, post_webhook_retry_count: int, post_webhook_url: string, pre_webhook_retry_count: int, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{sid}"))
  let req_body = {"ConsumptionReportInterval": $consumption_report_interval, "DefaultChannelCreatorRoleSid": $default_channel_creator_role_sid, "DefaultChannelRoleSid": $default_channel_role_sid, "DefaultServiceRoleSid": $default_service_role_sid, "FriendlyName": $friendly_name, "Limits.ChannelMembers": $limits_channel_members, "Limits.UserChannels": $limits_user_channels, "Media.CompatibilityMessage": $media_compatibility_message, "Notifications.AddedToChannel.Enabled": $notifications_added_to_channel_enabled, "Notifications.AddedToChannel.Sound": $notifications_added_to_channel_sound, "Notifications.AddedToChannel.Template": $notifications_added_to_channel_template, "Notifications.InvitedToChannel.Enabled": $notifications_invited_to_channel_enabled, "Notifications.InvitedToChannel.Sound": $notifications_invited_to_channel_sound, "Notifications.InvitedToChannel.Template": $notifications_invited_to_channel_template, "Notifications.LogEnabled": $notifications_log_enabled, "Notifications.NewMessage.BadgeCountEnabled": $notifications_new_message_badge_count_enabled, "Notifications.NewMessage.Enabled": $notifications_new_message_enabled, "Notifications.NewMessage.Sound": $notifications_new_message_sound, "Notifications.NewMessage.Template": $notifications_new_message_template, "Notifications.RemovedFromChannel.Enabled": $notifications_removed_from_channel_enabled, "Notifications.RemovedFromChannel.Sound": $notifications_removed_from_channel_sound, "Notifications.RemovedFromChannel.Template": $notifications_removed_from_channel_template, "PostWebhookRetryCount": $post_webhook_retry_count, "PostWebhookUrl": $post_webhook_url, "PreWebhookRetryCount": $pre_webhook_retry_count, "PreWebhookUrl": $pre_webhook_url, "ReachabilityEnabled": $reachability_enabled, "ReadStatusEnabled": $read_status_enabled, "TypingIndicatorTimeout": $typing_indicator_timeout, "WebhookFilters": $webhook_filters, "WebhookMethod": $webhook_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}
