# Auto-generated client for Twilio - Chat v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_chat_v1/1.42.0/openapi.json
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
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def Type-completer [] { ["apn" "fcm" "gcm"] }
def Type-completer-1 [] { ["private" "public"] }
def Order-completer [] { ["asc" "desc"] }
def Type-completer-2 [] { ["channel" "deployment"] }
def WebhookMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnChannelAddMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnChannelAddedMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnChannelDestroyMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnChannelDestroyedMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnChannelUpdateMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnChannelUpdatedMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnMemberAddMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnMemberAddedMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnMemberRemoveMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnMemberRemovedMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnMessageRemoveMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnMessageRemovedMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnMessageSendMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnMessageSentMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnMessageUpdateMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def WebhooksOnMessageUpdatedMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "credentials ListCredential" } } | get name | first)
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
export def "credentials ListCredential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<credentials: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Credentials
#
# operationId: CreateCredential
export def "credentials CreateCredential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ApiKey: string # [GCM only] The API key for the project that was obtained from the Google Developer console for your GCM Service application credential.
  --Certificate: string # [APN only] The URL encoded representation of the certificate. For example,  `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEFBQAwgZYxCzAJBgNV.....A== -----END CERTIFICATE-----`
  --FriendlyName: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --PrivateKey: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fGgvCI1l9s+cmBY3WIz+cUDqmxiieR. -----END RSA PRIVATE KEY-----`
  --Sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --Secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
  Type: string@Type-completer
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base "/v1/Credentials")
  let body = {ApiKey: $ApiKey, Certificate: $Certificate, FriendlyName: $FriendlyName, PrivateKey: $PrivateKey, Sandbox: $Sandbox, Secret: $Secret, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Credentials/{Sid}
#
# operationId: DeleteCredential
export def "credentials DeleteCredential" [
  Sid: string
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
  let full_url = (build-url $base $"/v1/Credentials/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Credentials/{Sid}
#
# operationId: FetchCredential
export def "credentials FetchCredential" [
  Sid: string
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
  let full_url = (build-url $base $"/v1/Credentials/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Credentials/{Sid}
#
# operationId: UpdateCredential
export def "credentials UpdateCredential" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ApiKey: string # [GCM only] The API key for the project that was obtained from the Google Developer console for your GCM Service application credential.
  --Certificate: string # [APN only] The URL encoded representation of the certificate. For example,  `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEFBQAwgZYxCzAJBgNV.....A== -----END CERTIFICATE-----`
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --PrivateKey: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fGgvCI1l9s+cmBY3WIz+cUDqmxiieR. -----END RSA PRIVATE KEY-----`
  --Sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --Secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Credentials/($Sid)")
  let body = {ApiKey: $ApiKey, Certificate: $Certificate, FriendlyName: $FriendlyName, PrivateKey: $PrivateKey, Sandbox: $Sandbox, Secret: $Secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services
#
# operationId: ListService
export def "services ListService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list, webhook_method: string, webhooks: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services
#
# operationId: CreateService
export def "services CreateService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string, webhooks: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base "/v1/Services")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{ServiceSid}/Channels
#
# operationId: ListChannel
export def "services-channels ListChannel" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Type: list # The visibility of the Channels to read. Can be: `public` or `private` and defaults to `public`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<channels: table<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "Type" $Type "multi") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/Channels
#
# operationId: CreateChannel
export def "services-channels CreateChannel" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: string # A valid JSON string that contains application-specific data.
  --FriendlyName: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --Type: string@Type-completer-1
  --UniqueName: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL. This value must be 64 characters or less in length and be unique within the Service.
]: any -> record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName, Type: $Type, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites
#
# operationId: ListInvite
export def "services-channels-invites ListInvite" [
  ServiceSid: string
  ChannelSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Identity: list # The [User](https://www.twilio.com/docs/api/chat/rest/v1/user)'s `identity` value of the resources to read. See [access tokens](https://www.twilio.com/docs/api/chat/guides/create-tokens) for more details.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<invites: table<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "Identity" $Identity "multi") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Invites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites
#
# operationId: CreateInvite
export def "services-channels-invites CreateInvite" [
  ServiceSid: string
  ChannelSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Identity: string # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/api/chat/rest/v1/user) within the [Service](https://www.twilio.com/docs/api/chat/rest/v1/service). See [access tokens](https://www.twilio.com/docs/api/chat/guides/create-tokens) for more info.
  --RoleSid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) assigned to the new member.
]: any -> record<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Invites")
  let body = {Identity: $Identity, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites/{Sid}
#
# operationId: DeleteInvite
export def "services-channels-invites DeleteInvite" [
  ServiceSid: string
  ChannelSid: string
  Sid: string
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
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Invites/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Invites/{Sid}
#
# operationId: FetchInvite
export def "services-channels-invites FetchInvite" [
  ServiceSid: string
  ChannelSid: string
  Sid: string
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
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Invites/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members
#
# operationId: ListMember
export def "services-channels-members ListMember" [
  ServiceSid: string
  ChannelSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Identity: list # The [User](https://www.twilio.com/docs/api/chat/rest/v1/user)'s `identity` value of the resources to read. See [access tokens](https://www.twilio.com/docs/api/chat/guides/create-tokens) for more details.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<members: table<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "Identity" $Identity "multi") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members
#
# operationId: CreateMember
export def "services-channels-members CreateMember" [
  ServiceSid: string
  ChannelSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Identity: string # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/api/chat/rest/v1/user) within the [Service](https://www.twilio.com/docs/api/chat/rest/services). See [access tokens](https://www.twilio.com/docs/api/chat/guides/create-tokens) for more details.
  --RoleSid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) to assign to the member. The default roles are those specified on the [Service](https://www.twilio.com/docs/chat/api/services).
]: any -> record<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Members")
  let body = {Identity: $Identity, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
#
# operationId: DeleteMember
export def "services-channels-members DeleteMember" [
  ServiceSid: string
  ChannelSid: string
  Sid: string
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
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Members/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
#
# operationId: FetchMember
export def "services-channels-members FetchMember" [
  ServiceSid: string
  ChannelSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Members/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
#
# operationId: UpdateMember
export def "services-channels-members UpdateMember" [
  ServiceSid: string
  ChannelSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --LastConsumedMessageIndex: int # The index of the last [Message](https://www.twilio.com/docs/api/chat/rest/messages) that the Member has read within the [Channel](https://www.twilio.com/docs/api/chat/rest/channels). (nullable)
  --RoleSid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) to assign to the member. The default roles are those specified on the [Service](https://www.twilio.com/docs/chat/api/services).
]: any -> record<account_sid: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Members/($Sid)")
  let body = {LastConsumedMessageIndex: $LastConsumedMessageIndex, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages
#
# operationId: ListMessage
export def "services-channels-messages ListMessage" [
  ServiceSid: string
  ChannelSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Order: string@Order-completer # The sort order of the returned messages. Can be: `asc` (ascending) or `desc` (descending) with `asc` as the default.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<messages: table<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "Order" $Order "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages
#
# operationId: CreateMessage
export def "services-channels-messages CreateMessage" [
  ServiceSid: string
  ChannelSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: string # A valid JSON string that contains application-specific data.
  Body: string # The message to send to the channel. Can also be an empty string or `null`, which sets the value as an empty string. You can send structured data in the body by serializing it as a string.
  --From: string # The [identity](https://www.twilio.com/docs/api/chat/guides/identity) of the new message's author. The default value is `system`.
]: any -> record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Messages")
  let body = {Attributes: $Attributes, Body: $Body, From: $From} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
#
# operationId: DeleteMessage
export def "services-channels-messages DeleteMessage" [
  ServiceSid: string
  ChannelSid: string
  Sid: string
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
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Messages/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
#
# operationId: FetchMessage
export def "services-channels-messages FetchMessage" [
  ServiceSid: string
  ChannelSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Messages/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
#
# operationId: UpdateMessage
export def "services-channels-messages UpdateMessage" [
  ServiceSid: string
  ChannelSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: string # A valid JSON string that contains application-specific data.
  --Body: string # The message to send to the channel. Can also be an empty string or `null`, which sets the value as an empty string. You can send structured data in the body by serializing it as a string.
]: any -> record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, service_sid: string, sid: string, to: string, url: string, was_edited: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($ChannelSid)/Messages/($Sid)")
  let body = {Attributes: $Attributes, Body: $Body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Services/{ServiceSid}/Channels/{Sid}
#
# operationId: DeleteChannel
export def "services-channels DeleteChannel" [
  ServiceSid: string
  Sid: string
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
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/Channels/{Sid}
#
# operationId: FetchChannel
export def "services-channels FetchChannel" [
  ServiceSid: string
  Sid: string
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
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/Channels/{Sid}
#
# operationId: UpdateChannel
export def "services-channels UpdateChannel" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: string # A valid JSON string that contains application-specific data.
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --UniqueName: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL. This value must be 64 characters or less in length and be unique within the Service.
]: any -> record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Channels/($Sid)")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{ServiceSid}/Roles
#
# operationId: ListRole
export def "services-roles ListRole" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, roles: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list, service_sid: string, sid: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/Roles
#
# operationId: CreateRole
export def "services-roles CreateRole" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  FriendlyName: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  Permission: list # A permission that you grant to the new role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. The values for this parameter depend on the role's `type` and are described in the documentation.
  Type: string@Type-completer-2
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Roles")
  let body = {FriendlyName: $FriendlyName, Permission: $Permission, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Services/{ServiceSid}/Roles/{Sid}
#
# operationId: DeleteRole
export def "services-roles DeleteRole" [
  ServiceSid: string
  Sid: string
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
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Roles/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/Roles/{Sid}
#
# operationId: FetchRole
export def "services-roles FetchRole" [
  ServiceSid: string
  Sid: string
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
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Roles/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/Roles/{Sid}
#
# operationId: UpdateRole
export def "services-roles UpdateRole" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Permission: list # A permission that you grant to the role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. The values for this parameter depend on the role's `type` and are described in the documentation.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Roles/($Sid)")
  let body = {Permission: $Permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{ServiceSid}/Users
#
# operationId: ListUser
export def "services-users ListUser" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, users: table<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/Users
#
# operationId: CreateUser
export def "services-users CreateUser" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: string # A valid JSON string that contains application-specific data.
  --FriendlyName: string # A descriptive string that you create to describe the new resource. This value is often used for display purposes.
  Identity: string # The `identity` value that uniquely identifies the new resource's [User](https://www.twilio.com/docs/api/chat/rest/v1/user) within the [Service](https://www.twilio.com/docs/api/chat/rest/v1/service). This value is often a username or email address. See the Identity documentation for more details.
  --RoleSid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) assigned to the new User.
]: any -> record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Users")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName, Identity: $Identity, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Services/{ServiceSid}/Users/{Sid}
#
# operationId: DeleteUser
export def "services-users DeleteUser" [
  ServiceSid: string
  Sid: string
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
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Users/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/Users/{Sid}
#
# operationId: FetchUser
export def "services-users FetchUser" [
  ServiceSid: string
  Sid: string
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
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Users/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/Users/{Sid}
#
# operationId: UpdateUser
export def "services-users UpdateUser" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: string # A valid JSON string that contains application-specific data.
  --FriendlyName: string # A descriptive string that you create to describe the resource. It is often used for display purposes.
  --RoleSid: string # The SID of the [Role](https://www.twilio.com/docs/api/chat/rest/roles) assigned to this user.
]: any -> record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Users/($Sid)")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List all Channels for a given User.
#
# GET /v1/Services/{ServiceSid}/Users/{UserSid}/Channels
# operationId: ListUserChannel
export def "services-users-channels ListUserChannel" [
  ServiceSid: string
  UserSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<channels: table<account_sid: string, channel_sid: string, last_consumed_message_index: int, links: record, member_sid: string, service_sid: string, status: string, unread_messages_count: int>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Users/($UserSid)/Channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/Services/{Sid}
#
# operationId: DeleteService
export def "services DeleteService" [
  Sid: string
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
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{Sid}
#
# operationId: FetchService
export def "services FetchService" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string, webhooks: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{Sid}
#
# operationId: UpdateService
export def "services UpdateService" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ConsumptionReportInterval: int # DEPRECATED. The interval in seconds between consumption reports submission batches from client endpoints.
  --DefaultChannelCreatorRoleSid: string # The channel role assigned to a channel creator when they join a new channel. See the [Roles endpoint](https://www.twilio.com/docs/chat/api/roles) for more details.
  --DefaultChannelRoleSid: string # The channel role assigned to users when they are added to a channel. See the [Roles endpoint](https://www.twilio.com/docs/chat/api/roles) for more details.
  --DefaultServiceRoleSid: string # The service role assigned to users when they are added to the service. See the [Roles endpoint](https://www.twilio.com/docs/chat/api/roles) for more details.
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --LimitsChannelMembers: int # The maximum number of Members that can be added to Channels within this Service. Can be up to 1,000.
  --LimitsUserChannels: int # The maximum number of Channels Users can be a Member of within this Service. Can be up to 1,000.
  --NotificationsAddedToChannelEnabled: oneof<nothing, bool> # Whether to send a notification when a member is added to a channel. Can be: `true` or `false` and the default is `false`.
  --NotificationsAddedToChannelTemplate: string # The template to use to create the notification text displayed when a member is added to a channel and `notifications.added_to_channel.enabled` is `true`.
  --NotificationsInvitedToChannelEnabled: oneof<nothing, bool> # Whether to send a notification when a user is invited to a channel. Can be: `true` or `false` and the default is `false`.
  --NotificationsInvitedToChannelTemplate: string # The template to use to create the notification text displayed when a user is invited to a channel and `notifications.invited_to_channel.enabled` is `true`.
  --NotificationsNewMessageEnabled: oneof<nothing, bool> # Whether to send a notification when a new message is added to a channel. Can be: `true` or `false` and the default is `false`.
  --NotificationsNewMessageTemplate: string # The template to use to create the notification text displayed when a new message is added to a channel and `notifications.new_message.enabled` is `true`.
  --NotificationsRemovedFromChannelEnabled: oneof<nothing, bool> # Whether to send a notification to a user when they are removed from a channel. Can be: `true` or `false` and the default is `false`.
  --NotificationsRemovedFromChannelTemplate: string # The template to use to create the notification text displayed to a user when they are removed from a channel and `notifications.removed_from_channel.enabled` is `true`.
  --PostWebhookUrl: string # The URL for post-event webhooks, which are called by using the `webhook_method`. See [Webhook Events](https://www.twilio.com/docs/api/chat/webhooks) for more details. (format: uri)
  --PreWebhookUrl: string # The URL for pre-event webhooks, which are called by using the `webhook_method`. See [Webhook Events](https://www.twilio.com/docs/api/chat/webhooks) for more details. (format: uri)
  --ReachabilityEnabled: oneof<nothing, bool> # Whether to enable the [Reachability Indicator](https://www.twilio.com/docs/chat/reachability-indicator) for this Service instance. The default is `false`.
  --ReadStatusEnabled: oneof<nothing, bool> # Whether to enable the [Message Consumption Horizon](https://www.twilio.com/docs/chat/consumption-horizon) feature. The default is `true`.
  --TypingIndicatorTimeout: int # How long in seconds after a `started typing` event until clients should assume that user is no longer typing, even if no `ended typing` message was received.  The default is 5 seconds.
  --WebhookFilters: list # The list of WebHook events that are enabled for this Service instance. See [Webhook Events](https://www.twilio.com/docs/chat/webhook-events) for more details.
  --WebhookMethod: string@WebhookMethod-completer # The HTTP method to use for calls to the `pre_webhook_url` and `post_webhook_url` webhooks.  Can be: `POST` or `GET` and the default is `POST`. See [Webhook Events](https://www.twilio.com/docs/chat/webhook-events) for more details. (format: http-method)
  --WebhooksOnChannelAddMethod: string@WebhooksOnChannelAddMethod-completer # The HTTP method to use when calling the `webhooks.on_channel_add.url`. (format: http-method)
  --WebhooksOnChannelAddUrl: string # The URL of the webhook to call in response to the `on_channel_add` event using the `webhooks.on_channel_add.method` HTTP method. (format: uri)
  --WebhooksOnChannelAddedMethod: string@WebhooksOnChannelAddedMethod-completer # The URL of the webhook to call in response to the `on_channel_added` event`. (format: http-method)
  --WebhooksOnChannelAddedUrl: string # The URL of the webhook to call in response to the `on_channel_added` event using the `webhooks.on_channel_added.method` HTTP method. (format: uri)
  --WebhooksOnChannelDestroyMethod: string@WebhooksOnChannelDestroyMethod-completer # The HTTP method to use when calling the `webhooks.on_channel_destroy.url`. (format: http-method)
  --WebhooksOnChannelDestroyUrl: string # The URL of the webhook to call in response to the `on_channel_destroy` event using the `webhooks.on_channel_destroy.method` HTTP method. (format: uri)
  --WebhooksOnChannelDestroyedMethod: string@WebhooksOnChannelDestroyedMethod-completer # The HTTP method to use when calling the `webhooks.on_channel_destroyed.url`. (format: http-method)
  --WebhooksOnChannelDestroyedUrl: string # The URL of the webhook to call in response to the `on_channel_added` event using the `webhooks.on_channel_destroyed.method` HTTP method. (format: uri)
  --WebhooksOnChannelUpdateMethod: string@WebhooksOnChannelUpdateMethod-completer # The HTTP method to use when calling the `webhooks.on_channel_update.url`. (format: http-method)
  --WebhooksOnChannelUpdateUrl: string # The URL of the webhook to call in response to the `on_channel_update` event using the `webhooks.on_channel_update.method` HTTP method. (format: uri)
  --WebhooksOnChannelUpdatedMethod: string@WebhooksOnChannelUpdatedMethod-completer # The HTTP method to use when calling the `webhooks.on_channel_updated.url`. (format: http-method)
  --WebhooksOnChannelUpdatedUrl: string # The URL of the webhook to call in response to the `on_channel_updated` event using the `webhooks.on_channel_updated.method` HTTP method. (format: uri)
  --WebhooksOnMemberAddMethod: string@WebhooksOnMemberAddMethod-completer # The HTTP method to use when calling the `webhooks.on_member_add.url`. (format: http-method)
  --WebhooksOnMemberAddUrl: string # The URL of the webhook to call in response to the `on_member_add` event using the `webhooks.on_member_add.method` HTTP method. (format: uri)
  --WebhooksOnMemberAddedMethod: string@WebhooksOnMemberAddedMethod-completer # The HTTP method to use when calling the `webhooks.on_channel_updated.url`. (format: http-method)
  --WebhooksOnMemberAddedUrl: string # The URL of the webhook to call in response to the `on_channel_updated` event using the `webhooks.on_channel_updated.method` HTTP method. (format: uri)
  --WebhooksOnMemberRemoveMethod: string@WebhooksOnMemberRemoveMethod-completer # The HTTP method to use when calling the `webhooks.on_member_remove.url`. (format: http-method)
  --WebhooksOnMemberRemoveUrl: string # The URL of the webhook to call in response to the `on_member_remove` event using the `webhooks.on_member_remove.method` HTTP method. (format: uri)
  --WebhooksOnMemberRemovedMethod: string@WebhooksOnMemberRemovedMethod-completer # The HTTP method to use when calling the `webhooks.on_member_removed.url`. (format: http-method)
  --WebhooksOnMemberRemovedUrl: string # The URL of the webhook to call in response to the `on_member_removed` event using the `webhooks.on_member_removed.method` HTTP method. (format: uri)
  --WebhooksOnMessageRemoveMethod: string@WebhooksOnMessageRemoveMethod-completer # The HTTP method to use when calling the `webhooks.on_message_remove.url`. (format: http-method)
  --WebhooksOnMessageRemoveUrl: string # The URL of the webhook to call in response to the `on_message_remove` event using the `webhooks.on_message_remove.method` HTTP method. (format: uri)
  --WebhooksOnMessageRemovedMethod: string@WebhooksOnMessageRemovedMethod-completer # The HTTP method to use when calling the `webhooks.on_message_removed.url`. (format: http-method)
  --WebhooksOnMessageRemovedUrl: string # The URL of the webhook to call in response to the `on_message_removed` event using the `webhooks.on_message_removed.method` HTTP method. (format: uri)
  --WebhooksOnMessageSendMethod: string@WebhooksOnMessageSendMethod-completer # The HTTP method to use when calling the `webhooks.on_message_send.url`. (format: http-method)
  --WebhooksOnMessageSendUrl: string # The URL of the webhook to call in response to the `on_message_send` event using the `webhooks.on_message_send.method` HTTP method. (format: uri)
  --WebhooksOnMessageSentMethod: string@WebhooksOnMessageSentMethod-completer # The URL of the webhook to call in response to the `on_message_sent` event`. (format: http-method)
  --WebhooksOnMessageSentUrl: string # The URL of the webhook to call in response to the `on_message_sent` event using the `webhooks.on_message_sent.method` HTTP method. (format: uri)
  --WebhooksOnMessageUpdateMethod: string@WebhooksOnMessageUpdateMethod-completer # The HTTP method to use when calling the `webhooks.on_message_update.url`. (format: http-method)
  --WebhooksOnMessageUpdateUrl: string # The URL of the webhook to call in response to the `on_message_update` event using the `webhooks.on_message_update.method` HTTP method. (format: uri)
  --WebhooksOnMessageUpdatedMethod: string@WebhooksOnMessageUpdatedMethod-completer # The HTTP method to use when calling the `webhooks.on_message_updated.url`. (format: http-method)
  --WebhooksOnMessageUpdatedUrl: string # The URL of the webhook to call in response to the `on_message_updated` event using the `webhooks.on_message_updated.method` HTTP method. (format: uri)
]: any -> record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, notifications: any, post_webhook_url: string, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string, webhooks: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://chat.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let body = {ConsumptionReportInterval: $ConsumptionReportInterval, DefaultChannelCreatorRoleSid: $DefaultChannelCreatorRoleSid, DefaultChannelRoleSid: $DefaultChannelRoleSid, DefaultServiceRoleSid: $DefaultServiceRoleSid, FriendlyName: $FriendlyName, Limits.ChannelMembers: $LimitsChannelMembers, Limits.UserChannels: $LimitsUserChannels, Notifications.AddedToChannel.Enabled: $NotificationsAddedToChannelEnabled, Notifications.AddedToChannel.Template: $NotificationsAddedToChannelTemplate, Notifications.InvitedToChannel.Enabled: $NotificationsInvitedToChannelEnabled, Notifications.InvitedToChannel.Template: $NotificationsInvitedToChannelTemplate, Notifications.NewMessage.Enabled: $NotificationsNewMessageEnabled, Notifications.NewMessage.Template: $NotificationsNewMessageTemplate, Notifications.RemovedFromChannel.Enabled: $NotificationsRemovedFromChannelEnabled, Notifications.RemovedFromChannel.Template: $NotificationsRemovedFromChannelTemplate, PostWebhookUrl: $PostWebhookUrl, PreWebhookUrl: $PreWebhookUrl, ReachabilityEnabled: $ReachabilityEnabled, ReadStatusEnabled: $ReadStatusEnabled, TypingIndicatorTimeout: $TypingIndicatorTimeout, WebhookFilters: $WebhookFilters, WebhookMethod: $WebhookMethod, Webhooks.OnChannelAdd.Method: $WebhooksOnChannelAddMethod, Webhooks.OnChannelAdd.Url: $WebhooksOnChannelAddUrl, Webhooks.OnChannelAdded.Method: $WebhooksOnChannelAddedMethod, Webhooks.OnChannelAdded.Url: $WebhooksOnChannelAddedUrl, Webhooks.OnChannelDestroy.Method: $WebhooksOnChannelDestroyMethod, Webhooks.OnChannelDestroy.Url: $WebhooksOnChannelDestroyUrl, Webhooks.OnChannelDestroyed.Method: $WebhooksOnChannelDestroyedMethod, Webhooks.OnChannelDestroyed.Url: $WebhooksOnChannelDestroyedUrl, Webhooks.OnChannelUpdate.Method: $WebhooksOnChannelUpdateMethod, Webhooks.OnChannelUpdate.Url: $WebhooksOnChannelUpdateUrl, Webhooks.OnChannelUpdated.Method: $WebhooksOnChannelUpdatedMethod, Webhooks.OnChannelUpdated.Url: $WebhooksOnChannelUpdatedUrl, Webhooks.OnMemberAdd.Method: $WebhooksOnMemberAddMethod, Webhooks.OnMemberAdd.Url: $WebhooksOnMemberAddUrl, Webhooks.OnMemberAdded.Method: $WebhooksOnMemberAddedMethod, Webhooks.OnMemberAdded.Url: $WebhooksOnMemberAddedUrl, Webhooks.OnMemberRemove.Method: $WebhooksOnMemberRemoveMethod, Webhooks.OnMemberRemove.Url: $WebhooksOnMemberRemoveUrl, Webhooks.OnMemberRemoved.Method: $WebhooksOnMemberRemovedMethod, Webhooks.OnMemberRemoved.Url: $WebhooksOnMemberRemovedUrl, Webhooks.OnMessageRemove.Method: $WebhooksOnMessageRemoveMethod, Webhooks.OnMessageRemove.Url: $WebhooksOnMessageRemoveUrl, Webhooks.OnMessageRemoved.Method: $WebhooksOnMessageRemovedMethod, Webhooks.OnMessageRemoved.Url: $WebhooksOnMessageRemovedUrl, Webhooks.OnMessageSend.Method: $WebhooksOnMessageSendMethod, Webhooks.OnMessageSend.Url: $WebhooksOnMessageSendUrl, Webhooks.OnMessageSent.Method: $WebhooksOnMessageSentMethod, Webhooks.OnMessageSent.Url: $WebhooksOnMessageSentUrl, Webhooks.OnMessageUpdate.Method: $WebhooksOnMessageUpdateMethod, Webhooks.OnMessageUpdate.Url: $WebhooksOnMessageUpdateUrl, Webhooks.OnMessageUpdated.Method: $WebhooksOnMessageUpdatedMethod, Webhooks.OnMessageUpdated.Url: $WebhooksOnMessageUpdatedUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
