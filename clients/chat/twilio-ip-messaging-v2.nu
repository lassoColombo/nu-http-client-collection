# Auto-generated client for Twilio - Ip_messaging v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_ip_messaging_v2/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_IP_MESSAGING_TOKEN

const BASE_URL = "https://ip-messaging.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_IP_MESSAGING_TOKEN | default "" }
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

def base-url-completer [] { ["https://ip-messaging.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def Type-completer [] { ["apn" "fcm" "gcm"] }
def Type-completer-1 [] { ["private" "public"] }
def X-Twilio-Webhook-Enabled-completer [] { ["false" "true"] }
def Order-completer [] { ["asc" "desc"] }
def ConfigurationMethod-completer [] { ["GET" "POST"] }
def Type-completer-2 [] { ["studio" "trigger" "webhook"] }
def Type-completer-3 [] { ["channel" "deployment"] }
def NotificationLevel-completer [] { ["default" "muted"] }
def WebhookMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

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

# GET /v2/Credentials
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/Credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Credentials
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
  --ApiKey: string
  --Certificate: string
  --FriendlyName: string
  --PrivateKey: string
  --Sandbox: oneof<nothing, bool>
  --Secret: string
  Type: string@Type-completer
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base "/v2/Credentials")
  let body = {ApiKey: $ApiKey, Certificate: $Certificate, FriendlyName: $FriendlyName, PrivateKey: $PrivateKey, Sandbox: $Sandbox, Secret: $Secret, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v2/Credentials/{Sid}
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Credentials/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Credentials/{Sid}
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Credentials/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Credentials/{Sid}
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
  --ApiKey: string
  --Certificate: string
  --FriendlyName: string
  --PrivateKey: string
  --Sandbox: oneof<nothing, bool>
  --Secret: string
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Credentials/($Sid)")
  let body = {ApiKey: $ApiKey, Certificate: $Certificate, FriendlyName: $FriendlyName, PrivateKey: $PrivateKey, Sandbox: $Sandbox, Secret: $Secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v2/Services
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, media: any, notifications: any, post_webhook_retry_count: int, post_webhook_url: string, pre_webhook_retry_count: int, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list, webhook_method: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services
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
  FriendlyName: string
]: any -> record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, media: any, notifications: any, post_webhook_retry_count: int, post_webhook_url: string, pre_webhook_retry_count: int, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base "/v2/Services")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v2/Services/{ServiceSid}/Bindings
#
# operationId: ListBinding
export def "services-bindings ListBinding" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BindingType: list
  --Identity: list
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<bindings: table<account_sid: string, binding_type: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, links: record, message_types: list, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let qp = [(serialize-qp "BindingType" $BindingType "multi") (serialize-qp "Identity" $Identity "multi") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Bindings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v2/Services/{ServiceSid}/Bindings/{Sid}
#
# operationId: DeleteBinding
export def "services-bindings DeleteBinding" [
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Bindings/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Bindings/{Sid}
#
# operationId: FetchBinding
export def "services-bindings FetchBinding" [
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
]: nothing -> record<account_sid: string, binding_type: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, links: record, message_types: list<string>, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Bindings/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels
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
  --Type: list
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<channels: table<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let qp = [(serialize-qp "Type" $Type "multi") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels
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
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Attributes: string
  --CreatedBy: string
  --DateCreated: string # format: date-time
  --DateUpdated: string # format: date-time
  --FriendlyName: string
  --Type: string@Type-completer-1
  --UniqueName: string
]: any -> record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels")
  let body = {Attributes: $Attributes, CreatedBy: $CreatedBy, DateCreated: $DateCreated, DateUpdated: $DateUpdated, FriendlyName: $FriendlyName, Type: $Type, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Invites
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
  --Identity: list
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<invites: table<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let qp = [(serialize-qp "Identity" $Identity "multi") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Invites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Invites
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
  Identity: string
  --RoleSid: string
]: any -> record<account_sid: string, channel_sid: string, created_by: string, date_created: string, date_updated: string, identity: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Invites")
  let body = {Identity: $Identity, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Invites/{Sid}
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Invites/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Invites/{Sid}
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Invites/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Members
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
  --Identity: list
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<members: table<account_sid: string, attributes: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let qp = [(serialize-qp "Identity" $Identity "multi") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Members
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
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Attributes: string
  --DateCreated: string # format: date-time
  --DateUpdated: string # format: date-time
  Identity: string
  --LastConsumedMessageIndex: int # nullable
  --LastConsumptionTimestamp: string # format: date-time
  --RoleSid: string
]: any -> record<account_sid: string, attributes: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Members")
  let body = {Attributes: $Attributes, DateCreated: $DateCreated, DateUpdated: $DateUpdated, Identity: $Identity, LastConsumedMessageIndex: $LastConsumedMessageIndex, LastConsumptionTimestamp: $LastConsumptionTimestamp, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
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
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Members/($Sid)")
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
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
]: nothing -> record<account_sid: string, attributes: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Members/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Members/{Sid}
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
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Attributes: string
  --DateCreated: string # format: date-time
  --DateUpdated: string # format: date-time
  --LastConsumedMessageIndex: int # nullable
  --LastConsumptionTimestamp: string # format: date-time
  --RoleSid: string
]: any -> record<account_sid: string, attributes: string, channel_sid: string, date_created: string, date_updated: string, identity: string, last_consumed_message_index: int, last_consumption_timestamp: string, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Members/($Sid)")
  let body = {Attributes: $Attributes, DateCreated: $DateCreated, DateUpdated: $DateUpdated, LastConsumedMessageIndex: $LastConsumedMessageIndex, LastConsumptionTimestamp: $LastConsumptionTimestamp, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Messages
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
  --Order: string@Order-completer
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<messages: table<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, last_updated_by: string, media: any, service_sid: string, sid: string, to: string, type: string, url: string, was_edited: bool>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let qp = [(serialize-qp "Order" $Order "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Messages
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
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Attributes: string
  --Body: string
  --DateCreated: string # format: date-time
  --DateUpdated: string # format: date-time
  --From: string
  --LastUpdatedBy: string
  --MediaSid: string
]: any -> record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, last_updated_by: string, media: any, service_sid: string, sid: string, to: string, type: string, url: string, was_edited: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Messages")
  let body = {Attributes: $Attributes, Body: $Body, DateCreated: $DateCreated, DateUpdated: $DateUpdated, From: $From, LastUpdatedBy: $LastUpdatedBy, MediaSid: $MediaSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
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
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Messages/($Sid)")
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
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
]: nothing -> record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, last_updated_by: string, media: any, service_sid: string, sid: string, to: string, type: string, url: string, was_edited: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Messages/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Messages/{Sid}
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
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Attributes: string
  --Body: string
  --DateCreated: string # format: date-time
  --DateUpdated: string # format: date-time
  --From: string
  --LastUpdatedBy: string
]: any -> record<account_sid: string, attributes: string, body: string, channel_sid: string, date_created: string, date_updated: string, from: string, index: int, last_updated_by: string, media: any, service_sid: string, sid: string, to: string, type: string, url: string, was_edited: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Messages/($Sid)")
  let body = {Attributes: $Attributes, Body: $Body, DateCreated: $DateCreated, DateUpdated: $DateUpdated, From: $From, LastUpdatedBy: $LastUpdatedBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Webhooks
#
# operationId: ListChannelWebhook
export def "services-channels-webhooks ListChannelWebhook" [
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
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, channel_sid: string, configuration: any, date_created: string, date_updated: string, service_sid: string, sid: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Webhooks
#
# operationId: CreateChannelWebhook
export def "services-channels-webhooks CreateChannelWebhook" [
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
  --ConfigurationFilters: list
  --ConfigurationFlowSid: string
  --ConfigurationMethod: string@ConfigurationMethod-completer
  --ConfigurationRetryCount: int
  --ConfigurationTriggers: list
  --ConfigurationUrl: string
  Type: string@Type-completer-2
]: any -> record<account_sid: string, channel_sid: string, configuration: any, date_created: string, date_updated: string, service_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Webhooks")
  let body = {Configuration.Filters: $ConfigurationFilters, Configuration.FlowSid: $ConfigurationFlowSid, Configuration.Method: $ConfigurationMethod, Configuration.RetryCount: $ConfigurationRetryCount, Configuration.Triggers: $ConfigurationTriggers, Configuration.Url: $ConfigurationUrl, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Webhooks/{Sid}
#
# operationId: DeleteChannelWebhook
export def "services-channels-webhooks DeleteChannelWebhook" [
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Webhooks/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Webhooks/{Sid}
#
# operationId: FetchChannelWebhook
export def "services-channels-webhooks FetchChannelWebhook" [
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
]: nothing -> record<account_sid: string, channel_sid: string, configuration: any, date_created: string, date_updated: string, service_sid: string, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Webhooks/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{ChannelSid}/Webhooks/{Sid}
#
# operationId: UpdateChannelWebhook
export def "services-channels-webhooks UpdateChannelWebhook" [
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
  --ConfigurationFilters: list
  --ConfigurationFlowSid: string
  --ConfigurationMethod: string@ConfigurationMethod-completer
  --ConfigurationRetryCount: int
  --ConfigurationTriggers: list
  --ConfigurationUrl: string
]: any -> record<account_sid: string, channel_sid: string, configuration: any, date_created: string, date_updated: string, service_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($ChannelSid)/Webhooks/($Sid)")
  let body = {Configuration.Filters: $ConfigurationFilters, Configuration.FlowSid: $ConfigurationFlowSid, Configuration.Method: $ConfigurationMethod, Configuration.RetryCount: $ConfigurationRetryCount, Configuration.Triggers: $ConfigurationTriggers, Configuration.Url: $ConfigurationUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v2/Services/{ServiceSid}/Channels/{Sid}
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
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($Sid)")
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Channels/{Sid}
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Channels/{Sid}
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
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Attributes: string
  --CreatedBy: string
  --DateCreated: string # format: date-time
  --DateUpdated: string # format: date-time
  --FriendlyName: string
  --UniqueName: string
]: any -> record<account_sid: string, attributes: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, links: record, members_count: int, messages_count: int, service_sid: string, sid: string, type: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Channels/($Sid)")
  let body = {Attributes: $Attributes, CreatedBy: $CreatedBy, DateCreated: $DateCreated, DateUpdated: $DateUpdated, FriendlyName: $FriendlyName, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v2/Services/{ServiceSid}/Roles
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Roles
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
  FriendlyName: string
  Permission: list
  Type: string@Type-completer-3
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Roles")
  let body = {FriendlyName: $FriendlyName, Permission: $Permission, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v2/Services/{ServiceSid}/Roles/{Sid}
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Roles/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Roles/{Sid}
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Roles/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Roles/{Sid}
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
  Permission: list
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, service_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Roles/($Sid)")
  let body = {Permission: $Permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v2/Services/{ServiceSid}/Users
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Users
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
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Attributes: string
  --FriendlyName: string
  Identity: string
  --RoleSid: string
]: any -> record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Users")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName, Identity: $Identity, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v2/Services/{ServiceSid}/Users/{Sid}
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Users/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Users/{Sid}
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Users/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Users/{Sid}
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
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Attributes: string
  --FriendlyName: string
  --RoleSid: string
]: any -> record<account_sid: string, attributes: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, joined_channels_count: int, links: record, role_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Users/($Sid)")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v2/Services/{ServiceSid}/Users/{UserSid}/Bindings
#
# operationId: ListUserBinding
export def "services-users-bindings ListUserBinding" [
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
  --BindingType: list
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<bindings: table<account_sid: string, binding_type: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, message_types: list, service_sid: string, sid: string, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let qp = [(serialize-qp "BindingType" $BindingType "multi") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Users/($UserSid)/Bindings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v2/Services/{ServiceSid}/Users/{UserSid}/Bindings/{Sid}
#
# operationId: DeleteUserBinding
export def "services-users-bindings DeleteUserBinding" [
  ServiceSid: string
  UserSid: string
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Users/($UserSid)/Bindings/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Users/{UserSid}/Bindings/{Sid}
#
# operationId: FetchUserBinding
export def "services-users-bindings FetchUserBinding" [
  ServiceSid: string
  UserSid: string
  Sid: string
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Users/($UserSid)/Bindings/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Users/{UserSid}/Channels
#
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
]: nothing -> record<channels: table<account_sid: string, channel_sid: string, last_consumed_message_index: int, links: record, member_sid: string, notification_level: string, service_sid: string, status: string, unread_messages_count: int, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Users/($UserSid)/Channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v2/Services/{ServiceSid}/Users/{UserSid}/Channels/{ChannelSid}
#
# operationId: DeleteUserChannel
export def "services-users-channels DeleteUserChannel" [
  ServiceSid: string
  UserSid: string
  ChannelSid: string
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Users/($UserSid)/Channels/($ChannelSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{ServiceSid}/Users/{UserSid}/Channels/{ChannelSid}
#
# operationId: FetchUserChannel
export def "services-users-channels FetchUserChannel" [
  ServiceSid: string
  UserSid: string
  ChannelSid: string
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Users/($UserSid)/Channels/($ChannelSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Users/{UserSid}/Channels/{ChannelSid}
#
# operationId: UpdateUserChannel
export def "services-users-channels UpdateUserChannel" [
  ServiceSid: string
  UserSid: string
  ChannelSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --LastConsumedMessageIndex: int # nullable
  --LastConsumptionTimestamp: string # format: date-time
  --NotificationLevel: string@NotificationLevel-completer
]: any -> record<account_sid: string, channel_sid: string, last_consumed_message_index: int, links: record, member_sid: string, notification_level: string, service_sid: string, status: string, unread_messages_count: int, url: string, user_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($ServiceSid)/Users/($UserSid)/Channels/($ChannelSid)")
  let body = {LastConsumedMessageIndex: $LastConsumedMessageIndex, LastConsumptionTimestamp: $LastConsumptionTimestamp, NotificationLevel: $NotificationLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v2/Services/{Sid}
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
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v2/Services/{Sid}
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
]: nothing -> record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, media: any, notifications: any, post_webhook_retry_count: int, post_webhook_url: string, pre_webhook_retry_count: int, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{Sid}
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
  --ConsumptionReportInterval: int
  --DefaultChannelCreatorRoleSid: string
  --DefaultChannelRoleSid: string
  --DefaultServiceRoleSid: string
  --FriendlyName: string
  --LimitsChannelMembers: int
  --LimitsUserChannels: int
  --MediaCompatibilityMessage: string
  --NotificationsAddedToChannelEnabled: oneof<nothing, bool>
  --NotificationsAddedToChannelSound: string
  --NotificationsAddedToChannelTemplate: string
  --NotificationsInvitedToChannelEnabled: oneof<nothing, bool>
  --NotificationsInvitedToChannelSound: string
  --NotificationsInvitedToChannelTemplate: string
  --NotificationsLogEnabled: oneof<nothing, bool>
  --NotificationsNewMessageBadgeCountEnabled: oneof<nothing, bool>
  --NotificationsNewMessageEnabled: oneof<nothing, bool>
  --NotificationsNewMessageSound: string
  --NotificationsNewMessageTemplate: string
  --NotificationsRemovedFromChannelEnabled: oneof<nothing, bool>
  --NotificationsRemovedFromChannelSound: string
  --NotificationsRemovedFromChannelTemplate: string
  --PostWebhookRetryCount: int
  --PostWebhookUrl: string # format: uri
  --PreWebhookRetryCount: int
  --PreWebhookUrl: string # format: uri
  --ReachabilityEnabled: oneof<nothing, bool>
  --ReadStatusEnabled: oneof<nothing, bool>
  --TypingIndicatorTimeout: int
  --WebhookFilters: list
  --WebhookMethod: string@WebhookMethod-completer # format: http-method
]: any -> record<account_sid: string, consumption_report_interval: int, date_created: string, date_updated: string, default_channel_creator_role_sid: string, default_channel_role_sid: string, default_service_role_sid: string, friendly_name: string, limits: any, links: record, media: any, notifications: any, post_webhook_retry_count: int, post_webhook_url: string, pre_webhook_retry_count: int, pre_webhook_url: string, reachability_enabled: bool, read_status_enabled: bool, sid: string, typing_indicator_timeout: int, url: string, webhook_filters: list<string>, webhook_method: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://ip-messaging.twilio.com")
  let full_url = (build-url $base $"/v2/Services/($Sid)")
  let body = {ConsumptionReportInterval: $ConsumptionReportInterval, DefaultChannelCreatorRoleSid: $DefaultChannelCreatorRoleSid, DefaultChannelRoleSid: $DefaultChannelRoleSid, DefaultServiceRoleSid: $DefaultServiceRoleSid, FriendlyName: $FriendlyName, Limits.ChannelMembers: $LimitsChannelMembers, Limits.UserChannels: $LimitsUserChannels, Media.CompatibilityMessage: $MediaCompatibilityMessage, Notifications.AddedToChannel.Enabled: $NotificationsAddedToChannelEnabled, Notifications.AddedToChannel.Sound: $NotificationsAddedToChannelSound, Notifications.AddedToChannel.Template: $NotificationsAddedToChannelTemplate, Notifications.InvitedToChannel.Enabled: $NotificationsInvitedToChannelEnabled, Notifications.InvitedToChannel.Sound: $NotificationsInvitedToChannelSound, Notifications.InvitedToChannel.Template: $NotificationsInvitedToChannelTemplate, Notifications.LogEnabled: $NotificationsLogEnabled, Notifications.NewMessage.BadgeCountEnabled: $NotificationsNewMessageBadgeCountEnabled, Notifications.NewMessage.Enabled: $NotificationsNewMessageEnabled, Notifications.NewMessage.Sound: $NotificationsNewMessageSound, Notifications.NewMessage.Template: $NotificationsNewMessageTemplate, Notifications.RemovedFromChannel.Enabled: $NotificationsRemovedFromChannelEnabled, Notifications.RemovedFromChannel.Sound: $NotificationsRemovedFromChannelSound, Notifications.RemovedFromChannel.Template: $NotificationsRemovedFromChannelTemplate, PostWebhookRetryCount: $PostWebhookRetryCount, PostWebhookUrl: $PostWebhookUrl, PreWebhookRetryCount: $PreWebhookRetryCount, PreWebhookUrl: $PreWebhookUrl, ReachabilityEnabled: $ReachabilityEnabled, ReadStatusEnabled: $ReadStatusEnabled, TypingIndicatorTimeout: $TypingIndicatorTimeout, WebhookFilters: $WebhookFilters, WebhookMethod: $WebhookMethod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
