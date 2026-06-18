# Auto-generated client for Twilio - Messaging v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_messaging_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_MESSAGING_TOKEN

const BASE_URL = "https://messaging.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_MESSAGING_TOKEN | default "" }
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
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://messaging.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def fallback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def inbound-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def scan-message-content-completer [] { ["disable" "enable" "inherit"] }
def status-completer [] { ["IN_REVIEW" "PENDING_REVIEW" "TWILIO_APPROVED" "TWILIO_REJECTED"] }
def opt-in-type-completer [] { ["MOBILE_QR_CODE" "PAPER_FORM" "VERBAL" "VIA_TEXT" "WEB_FORM"] }
def vetting-provider-completer [] { ["campaign-verify"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "deactivations get" } } | get name | first)
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

# Fetch a list of all United States numbers that have been deactivated on a specific date.
#
# GET /v1/Deactivations
# operationId: FetchDeactivation
export def "deactivations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The request will return a list of all United States Phone Numbers that were deactivated on the day specified by this parameter. This date should be specified in YYYY-MM-DD format. (format: date)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "Date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Deactivations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# DELETE /v1/LinkShortening/Domains/{DomainSid}/Certificate
#
# operationId: DeleteDomainCertV4
export def "link-shortening-domains-certificate delete-cert" [
  domain_sid: string
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({domain_sid: (encode-path-segment $domain_sid)} | format pattern "/v1/LinkShortening/Domains/{domain_sid}/Certificate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /v1/LinkShortening/Domains/{DomainSid}/Certificate
#
# operationId: FetchDomainCertV4
export def "link-shortening-domains-certificate get-cert" [
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cert_in_validation: any, certificate_sid: string, date_created: string, date_expires: string, date_updated: string, domain_name: string, domain_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({domain_sid: (encode-path-segment $domain_sid)} | format pattern "/v1/LinkShortening/Domains/{domain_sid}/Certificate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /v1/LinkShortening/Domains/{DomainSid}/Certificate
#
# operationId: UpdateDomainCertV4
export def "link-shortening-domains-certificate update-cert" [
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  tls_cert: string # Contains the full TLS certificate and private for this domain in PEM format: https://en.wikipedia.org/wiki/Privacy-Enhanced_Mail. Twilio uses this information to process HTTPS traffic sent to your domain.
]: any -> record<cert_in_validation: any, certificate_sid: string, date_created: string, date_expires: string, date_updated: string, domain_name: string, domain_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({domain_sid: (encode-path-segment $domain_sid)} | format pattern "/v1/LinkShortening/Domains/{domain_sid}/Certificate"))
  let req_body = {"TlsCert": $tls_cert} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# GET /v1/LinkShortening/Domains/{DomainSid}/Config
#
# operationId: FetchDomainConfig
export def "link-shortening-domains-config get" [
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callback_url: string, config_sid: string, date_created: string, date_updated: string, domain_sid: string, fallback_url: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({domain_sid: (encode-path-segment $domain_sid)} | format pattern "/v1/LinkShortening/Domains/{domain_sid}/Config"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /v1/LinkShortening/Domains/{DomainSid}/Config
#
# operationId: UpdateDomainConfig
export def "link-shortening-domains-config update" [
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-url: string # URL to receive click events to your webhook whenever the recipients click on the shortened links (format: uri)
  --fallback-url: string # Any requests we receive to this domain that do not match an existing shortened message will be redirected to the fallback url. These will likely be either expired messages, random misdirected traffic, or intentional scraping. (format: uri)
]: any -> record<callback_url: string, config_sid: string, date_created: string, date_updated: string, domain_sid: string, fallback_url: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({domain_sid: (encode-path-segment $domain_sid)} | format pattern "/v1/LinkShortening/Domains/{domain_sid}/Config"))
  let req_body = {"CallbackUrl": $callback_url, "FallbackUrl": $fallback_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# DELETE /v1/LinkShortening/Domains/{DomainSid}/MessagingServices/{MessagingServiceSid}
#
# operationId: DeleteLinkshorteningMessagingService
export def "link-shortening-domains-messaging-services delete-linkshortening" [
  domain_sid: string
  messaging_service_sid: string
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({domain_sid: (encode-path-segment $domain_sid), messaging_service_sid: (encode-path-segment $messaging_service_sid)} | format pattern "/v1/LinkShortening/Domains/{domain_sid}/MessagingServices/{messaging_service_sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /v1/LinkShortening/Domains/{DomainSid}/MessagingServices/{MessagingServiceSid}
#
# operationId: CreateLinkshorteningMessagingService
export def "link-shortening-domains-messaging-services create-linkshortening" [
  domain_sid: string
  messaging_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain_sid: string, messaging_service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({domain_sid: (encode-path-segment $domain_sid), messaging_service_sid: (encode-path-segment $messaging_service_sid)} | format pattern "/v1/LinkShortening/Domains/{domain_sid}/MessagingServices/{messaging_service_sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /v1/LinkShortening/MessagingService/{MessagingServiceSid}/DomainConfig
#
# operationId: FetchDomainConfigMessagingService
export def "link-shortening-messaging-service-domain-config get" [
  messaging_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callback_url: string, config_sid: string, date_created: string, date_updated: string, domain_sid: string, fallback_url: string, messaging_service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({messaging_service_sid: (encode-path-segment $messaging_service_sid)} | format pattern "/v1/LinkShortening/MessagingService/{messaging_service_sid}/DomainConfig"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  --area-code-geomatch: oneof<nothing, bool> # Whether to enable [Area Code Geomatch](https://www.twilio.com/docs/sms/services#area-code-geomatch) on the Service Instance.
  --fallback-method: string@fallback-method-completer # The HTTP method we should use to call `fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --fallback-to-long-code: oneof<nothing, bool> # Whether to enable [Fallback to Long Code](https://www.twilio.com/docs/sms/services#fallback-to-long-code) for messages sent through the Service instance.
  --fallback-url: string # The URL that we call using `fallback_method` if an error occurs while retrieving or executing the TwiML from the Inbound Request URL. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `fallback_url` defined for the Messaging Service. (format: uri)
  friendly_name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --inbound-method: string@inbound-method-completer # The HTTP method we should use to call `inbound_request_url`. Can be `GET` or `POST` and the default is `POST`. (format: http-method)
  --inbound-request-url: string # The URL we call using `inbound_method` when a message is received by any phone number or short code in the Service. When this property is `null`, receiving inbound messages is disabled. All messages sent to the Twilio phone number or short code will not be logged and received on the Account. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `inbound_request_url` defined for the Messaging Service. (format: uri)
  --mms-converter: oneof<nothing, bool> # Whether to enable the [MMS Converter](https://www.twilio.com/docs/sms/services#mms-converter) for messages sent through the Service instance.
  --scan-message-content: string@scan-message-content-completer
  --smart-encoding: oneof<nothing, bool> # Whether to enable [Smart Encoding](https://www.twilio.com/docs/sms/services#smart-encoding) for messages sent through the Service instance.
  --status-callback: string # The URL we should call to [pass status updates](https://www.twilio.com/docs/sms/api/message-resource#message-status-values) about message delivery. (format: uri)
  --sticky-sender: oneof<nothing, bool> # Whether to enable [Sticky Sender](https://www.twilio.com/docs/sms/services#sticky-sender) on the Service instance.
  --synchronous-validation: oneof<nothing, bool> # Reserved.
  --use-inbound-webhook-on-number: oneof<nothing, bool> # A boolean value that indicates either the webhook url configured on the phone number will be used or `inbound_request_url`/`fallback_url` url will be called when a message is received from the phone number. If this field is enabled then the webhook url defined on the phone number will override the `inbound_request_url`/`fallback_url` defined for the Messaging Service.
  --usecase: string # A string that describes the scenario in which the Messaging Service will be used. Examples: [notification, marketing, verification, poll ..].
  --validity-period: int # How long, in seconds, messages sent from the Service are valid. Can be an integer from `1` to `14,400`.
]: any -> record<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/Services")
  let req_body = {"AreaCodeGeomatch": $area_code_geomatch, "FallbackMethod": $fallback_method, "FallbackToLongCode": $fallback_to_long_code, "FallbackUrl": $fallback_url, "FriendlyName": $friendly_name, "InboundMethod": $inbound_method, "InboundRequestUrl": $inbound_request_url, "MmsConverter": $mms_converter, "ScanMessageContent": $scan_message_content, "SmartEncoding": $smart_encoding, "StatusCallback": $status_callback, "StickySender": $sticky_sender, "SynchronousValidation": $synchronous_validation, "UseInboundWebhookOnNumber": $use_inbound_webhook_on_number, "Usecase": $usecase, "ValidityPeriod": $validity_period} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# POST /v1/Services/PreregisteredUsa2p
#
# operationId: CreateExternalCampaign
export def "services-preregistered-usa2p create-external-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  campaign_id: string # ID of the preregistered campaign.
  messaging_service_sid: string # The SID of the [Messaging Service](https://www.twilio.com/docs/messaging/services/api) that the resource is associated with.
]: any -> record<account_sid: string, campaign_id: string, date_created: string, messaging_service_sid: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/Services/PreregisteredUsa2p")
  let req_body = {"CampaignId": $campaign_id, "MessagingServiceSid": $messaging_service_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# GET /v1/Services/Usecases
#
# operationId: FetchUsecase
export def "services-usecases get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<usecases: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/Services/Usecases")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /v1/Services/{MessagingServiceSid}/Compliance/Usa2p
#
# operationId: ListUsAppToPerson
export def "services-compliance-usa2p list-us-app-to-person" [
  messaging_service_sid: string
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
]: nothing -> record<compliance: table<account_sid: string, brand_registration_sid: string, campaign_id: string, campaign_status: string, date_created: string, date_updated: string, description: string, has_embedded_links: bool, has_embedded_phone: bool, help_keywords: list, help_message: string, is_externally_registered: bool, message_flow: string, message_samples: list, messaging_service_sid: string, mock: bool, opt_in_keywords: list, opt_in_message: string, opt_out_keywords: list, opt_out_message: string, rate_limits: any, sid: string, url: string, us_app_to_person_usecase: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({messaging_service_sid: (encode-path-segment $messaging_service_sid)} | format pattern "/v1/Services/{messaging_service_sid}/Compliance/Usa2p") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /v1/Services/{MessagingServiceSid}/Compliance/Usa2p
#
# operationId: CreateUsAppToPerson
export def "services-compliance-usa2p create-us-app-to-person" [
  messaging_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  brand_registration_sid: string # A2P Brand Registration SID
  description: string # A short description of what this SMS campaign does. Min length: 40 characters. Max length: 4096 characters.
  --has-embedded-links: oneof<nothing, bool> # Indicates that this SMS campaign will send messages that contain links.
  --has-embedded-phone: oneof<nothing, bool> # Indicates that this SMS campaign will send messages that contain phone numbers.
  --help-keywords: list<string> # End users should be able to text in a keyword to receive help. Those keywords must be provided as part of the campaign registration request. This field is required if managing help keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). Values must be alphanumeric. 255 character maximum.
  --help-message: string # When customers receive the help keywords from their end users, Twilio customers are expected to send back an auto-generated response; this may include the brand name and additional support contact information. This field is required if managing help keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). 20 character minimum. 320 character maximum.
  message_flow: string # Required for all Campaigns. Details around how a consumer opts-in to their campaign, therefore giving consent to receive their messages. If multiple opt-in methods can be used for the same campaign, they must all be listed. 40 character minimum. 2048 character maximum.
  message_samples: list<string> # Message samples, at least 1 and up to 5 sample messages (at least 2 for sole proprietor), >=20 chars, <=1024 chars each.
  --opt-in-keywords: list<string> # If end users can text in a keyword to start receiving messages from this campaign, those keywords must be provided. This field is required if end users can text in a keyword to start receiving messages from this campaign. Values must be alphanumeric. 255 character maximum.
  --opt-in-message: string # If end users can text in a keyword to start receiving messages from this campaign, the auto-reply messages sent to the end users must be provided. The opt-in response should include the Brand name, confirmation of opt-in enrollment to a recurring message campaign, how to get help, and clear description of how to opt-out. This field is required if end users can text in a keyword to start receiving messages from this campaign. 20 character minimum. 320 character maximum.
  --opt-out-keywords: list<string> # End users should be able to text in a keyword to stop receiving messages from this campaign. Those keywords must be provided. This field is required if managing opt out keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). Values must be alphanumeric. 255 character maximum.
  --opt-out-message: string # Upon receiving the opt-out keywords from the end users, Twilio customers are expected to send back an auto-generated response, which must provide acknowledgment of the opt-out request and confirmation that no further messages will be sent. It is also recommended that these opt-out messages include the brand name. This field is required if managing opt out keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). 20 character minimum. 320 character maximum.
  us_app_to_person_usecase: string # A2P Campaign Use Case. Examples: [ 2FA, EMERGENCY, MARKETING..]
]: any -> record<account_sid: string, brand_registration_sid: string, campaign_id: string, campaign_status: string, date_created: string, date_updated: string, description: string, has_embedded_links: bool, has_embedded_phone: bool, help_keywords: list<string>, help_message: string, is_externally_registered: bool, message_flow: string, message_samples: list<string>, messaging_service_sid: string, mock: bool, opt_in_keywords: list<string>, opt_in_message: string, opt_out_keywords: list<string>, opt_out_message: string, rate_limits: any, sid: string, url: string, us_app_to_person_usecase: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({messaging_service_sid: (encode-path-segment $messaging_service_sid)} | format pattern "/v1/Services/{messaging_service_sid}/Compliance/Usa2p"))
  let req_body = {"BrandRegistrationSid": $brand_registration_sid, "Description": $description, "HasEmbeddedLinks": $has_embedded_links, "HasEmbeddedPhone": $has_embedded_phone, "HelpKeywords": $help_keywords, "HelpMessage": $help_message, "MessageFlow": $message_flow, "MessageSamples": $message_samples, "OptInKeywords": $opt_in_keywords, "OptInMessage": $opt_in_message, "OptOutKeywords": $opt_out_keywords, "OptOutMessage": $opt_out_message, "UsAppToPersonUsecase": $us_app_to_person_usecase} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# GET /v1/Services/{MessagingServiceSid}/Compliance/Usa2p/Usecases
#
# operationId: FetchUsAppToPersonUsecase
export def "services-compliance-usa2p-usecases get-us-app-to-person" [
  messaging_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brand-registration-sid: string # The unique string to identify the A2P brand.
]: nothing -> record<us_app_to_person_usecases: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "BrandRegistrationSid" $brand_registration_sid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({messaging_service_sid: (encode-path-segment $messaging_service_sid)} | format pattern "/v1/Services/{messaging_service_sid}/Compliance/Usa2p/Usecases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# DELETE /v1/Services/{MessagingServiceSid}/Compliance/Usa2p/{Sid}
#
# operationId: DeleteUsAppToPerson
export def "services-compliance-usa2p delete-us-app-to-person" [
  messaging_service_sid: string
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({messaging_service_sid: (encode-path-segment $messaging_service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{messaging_service_sid}/Compliance/Usa2p/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /v1/Services/{MessagingServiceSid}/Compliance/Usa2p/{Sid}
#
# operationId: FetchUsAppToPerson
export def "services-compliance-usa2p get-us-app-to-person" [
  messaging_service_sid: string
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
]: nothing -> record<account_sid: string, brand_registration_sid: string, campaign_id: string, campaign_status: string, date_created: string, date_updated: string, description: string, has_embedded_links: bool, has_embedded_phone: bool, help_keywords: list<string>, help_message: string, is_externally_registered: bool, message_flow: string, message_samples: list<string>, messaging_service_sid: string, mock: bool, opt_in_keywords: list<string>, opt_in_message: string, opt_out_keywords: list<string>, opt_out_message: string, rate_limits: any, sid: string, url: string, us_app_to_person_usecase: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({messaging_service_sid: (encode-path-segment $messaging_service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{messaging_service_sid}/Compliance/Usa2p/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /v1/Services/{ServiceSid}/AlphaSenders
#
# operationId: ListAlphaSender
export def "services-alpha-senders list" [
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
]: nothing -> record<alpha_senders: table<account_sid: string, alpha_sender: string, capabilities: list, date_created: string, date_updated: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/AlphaSenders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /v1/Services/{ServiceSid}/AlphaSenders
#
# operationId: CreateAlphaSender
export def "services-alpha-senders create" [
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
  alpha_sender: string # The Alphanumeric Sender ID string. Can be up to 11 characters long. Valid characters are A-Z, a-z, 0-9, space, hyphen `-`, plus `+`, underscore `_` and ampersand `&`. This value cannot contain only numbers.
]: any -> record<account_sid: string, alpha_sender: string, capabilities: list<string>, date_created: string, date_updated: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/AlphaSenders"))
  let req_body = {"AlphaSender": $alpha_sender} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# DELETE /v1/Services/{ServiceSid}/AlphaSenders/{Sid}
#
# operationId: DeleteAlphaSender
export def "services-alpha-senders delete" [
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/AlphaSenders/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /v1/Services/{ServiceSid}/AlphaSenders/{Sid}
#
# operationId: FetchAlphaSender
export def "services-alpha-senders get" [
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
]: nothing -> record<account_sid: string, alpha_sender: string, capabilities: list<string>, date_created: string, date_updated: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/AlphaSenders/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /v1/Services/{ServiceSid}/PhoneNumbers
#
# operationId: ListPhoneNumber
export def "services-phone-numbers list" [
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, phone_numbers: table<account_sid: string, capabilities: list, country_code: string, date_created: string, date_updated: string, phone_number: string, service_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/PhoneNumbers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /v1/Services/{ServiceSid}/PhoneNumbers
#
# operationId: CreatePhoneNumber
export def "services-phone-numbers create" [
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
  phone_number_sid: string # The SID of the Phone Number being added to the Service.
]: any -> record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, phone_number: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/PhoneNumbers"))
  let req_body = {"PhoneNumberSid": $phone_number_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# DELETE /v1/Services/{ServiceSid}/PhoneNumbers/{Sid}
#
# operationId: DeletePhoneNumber
export def "services-phone-numbers delete" [
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/PhoneNumbers/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /v1/Services/{ServiceSid}/PhoneNumbers/{Sid}
#
# operationId: FetchPhoneNumber
export def "services-phone-numbers get" [
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
]: nothing -> record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, phone_number: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/PhoneNumbers/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /v1/Services/{ServiceSid}/ShortCodes
#
# operationId: ListShortCode
export def "services-short-codes list" [
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, short_codes: table<account_sid: string, capabilities: list, country_code: string, date_created: string, date_updated: string, service_sid: string, short_code: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/ShortCodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /v1/Services/{ServiceSid}/ShortCodes
#
# operationId: CreateShortCode
export def "services-short-codes create" [
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
  short_code_sid: string # The SID of the ShortCode resource being added to the Service.
]: any -> record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, service_sid: string, short_code: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v1/Services/{service_sid}/ShortCodes"))
  let req_body = {"ShortCodeSid": $short_code_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# DELETE /v1/Services/{ServiceSid}/ShortCodes/{Sid}
#
# operationId: DeleteShortCode
export def "services-short-codes delete" [
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/ShortCodes/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /v1/Services/{ServiceSid}/ShortCodes/{Sid}
#
# operationId: FetchShortCode
export def "services-short-codes get" [
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
]: nothing -> record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, service_sid: string, short_code: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{service_sid}/ShortCodes/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
]: nothing -> record<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  --area-code-geomatch: oneof<nothing, bool> # Whether to enable [Area Code Geomatch](https://www.twilio.com/docs/sms/services#area-code-geomatch) on the Service Instance.
  --fallback-method: string@fallback-method-completer # The HTTP method we should use to call `fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --fallback-to-long-code: oneof<nothing, bool> # Whether to enable [Fallback to Long Code](https://www.twilio.com/docs/sms/services#fallback-to-long-code) for messages sent through the Service instance.
  --fallback-url: string # The URL that we call using `fallback_method` if an error occurs while retrieving or executing the TwiML from the Inbound Request URL. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `fallback_url` defined for the Messaging Service. (format: uri)
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --inbound-method: string@inbound-method-completer # The HTTP method we should use to call `inbound_request_url`. Can be `GET` or `POST` and the default is `POST`. (format: http-method)
  --inbound-request-url: string # The URL we call using `inbound_method` when a message is received by any phone number or short code in the Service. When this property is `null`, receiving inbound messages is disabled. All messages sent to the Twilio phone number or short code will not be logged and received on the Account. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `inbound_request_url` defined for the Messaging Service. (format: uri)
  --mms-converter: oneof<nothing, bool> # Whether to enable the [MMS Converter](https://www.twilio.com/docs/sms/services#mms-converter) for messages sent through the Service instance.
  --scan-message-content: string@scan-message-content-completer
  --smart-encoding: oneof<nothing, bool> # Whether to enable [Smart Encoding](https://www.twilio.com/docs/sms/services#smart-encoding) for messages sent through the Service instance.
  --status-callback: string # The URL we should call to [pass status updates](https://www.twilio.com/docs/sms/api/message-resource#message-status-values) about message delivery. (format: uri)
  --sticky-sender: oneof<nothing, bool> # Whether to enable [Sticky Sender](https://www.twilio.com/docs/sms/services#sticky-sender) on the Service instance.
  --synchronous-validation: oneof<nothing, bool> # Reserved.
  --use-inbound-webhook-on-number: oneof<nothing, bool> # A boolean value that indicates either the webhook url configured on the phone number will be used or `inbound_request_url`/`fallback_url` url will be called when a message is received from the phone number. If this field is enabled then the webhook url defined on the phone number will override the `inbound_request_url`/`fallback_url` defined for the Messaging Service.
  --usecase: string # A string that describes the scenario in which the Messaging Service will be used. Examples: [notification, marketing, verification, poll ..]
  --validity-period: int # How long, in seconds, messages sent from the Service are valid. Can be an integer from `1` to `14,400`.
]: any -> record<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}"))
  let req_body = {"AreaCodeGeomatch": $area_code_geomatch, "FallbackMethod": $fallback_method, "FallbackToLongCode": $fallback_to_long_code, "FallbackUrl": $fallback_url, "FriendlyName": $friendly_name, "InboundMethod": $inbound_method, "InboundRequestUrl": $inbound_request_url, "MmsConverter": $mms_converter, "ScanMessageContent": $scan_message_content, "SmartEncoding": $smart_encoding, "StatusCallback": $status_callback, "StickySender": $sticky_sender, "SynchronousValidation": $synchronous_validation, "UseInboundWebhookOnNumber": $use_inbound_webhook_on_number, "Usecase": $usecase, "ValidityPeriod": $validity_period} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# GET /v1/Tollfree/Verifications
#
# operationId: ListTollfreeVerification
export def "tollfree-verifications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tollfree-phone-number-sid: string # The SID of the Phone Number associated with the Tollfree Verification.
  --status: string@status-completer # The compliance status of the Tollfree Verification record.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, verifications: table<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list, use_case_summary: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "TollfreePhoneNumberSid" $tollfree_phone_number_sid "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Tollfree/Verifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /v1/Tollfree/Verifications
#
# operationId: CreateTollfreeVerification
export def "tollfree-verifications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-information: string # Additional information to be provided for verification.
  --business-city: string # The city of the business or organization using the Tollfree number.
  --business-contact-email: string # The email address of the contact for the business or organization using the Tollfree number.
  --business-contact-first-name: string # The first name of the contact for the business or organization using the Tollfree number.
  --business-contact-last-name: string # The last name of the contact for the business or organization using the Tollfree number.
  --business-contact-phone: string # The phone number of the contact for the business or organization using the Tollfree number. (format: phone-number)
  --business-country: string # The country of the business or organization using the Tollfree number.
  business_name: string # The name of the business or organization using the Tollfree number.
  --business-postal-code: string # The postal code of the business or organization using the Tollfree number.
  --business-state-province-region: string # The state/province/region of the business or organization using the Tollfree number.
  --business-street-address: string # The address of the business or organization using the Tollfree number.
  --business-street-address2: string # The address of the business or organization using the Tollfree number.
  business_website: string # The website of the business or organization using the Tollfree number.
  --customer-profile-sid: string # Customer's Profile Bundle BundleSid.
  --external-reference-id: string # An optional external reference ID supplied by customer and echoed back on status retrieval.
  message_volume: string # Estimate monthly volume of messages from the Tollfree Number.
  notification_email: string # The email address to receive the notification about the verification result. .
  opt_in_image_urls: list<string> # Link to an image that shows the opt-in workflow. Multiple images allowed and must be a publicly hosted URL.
  opt_in_type: string@opt-in-type-completer
  production_message_sample: string # An example of message content, i.e. a sample message.
  tollfree_phone_number_sid: string # The SID of the Phone Number associated with the Tollfree Verification.
  use_case_categories: list<string> # The category of the use case for the Tollfree Number. List as many are applicable..
  use_case_summary: string # Use this to further explain how messaging is used by the business or organization.
]: any -> record<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list<string>, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list<string>, use_case_summary: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/Tollfree/Verifications")
  let req_body = {"AdditionalInformation": $additional_information, "BusinessCity": $business_city, "BusinessContactEmail": $business_contact_email, "BusinessContactFirstName": $business_contact_first_name, "BusinessContactLastName": $business_contact_last_name, "BusinessContactPhone": $business_contact_phone, "BusinessCountry": $business_country, "BusinessName": $business_name, "BusinessPostalCode": $business_postal_code, "BusinessStateProvinceRegion": $business_state_province_region, "BusinessStreetAddress": $business_street_address, "BusinessStreetAddress2": $business_street_address2, "BusinessWebsite": $business_website, "CustomerProfileSid": $customer_profile_sid, "ExternalReferenceId": $external_reference_id, "MessageVolume": $message_volume, "NotificationEmail": $notification_email, "OptInImageUrls": $opt_in_image_urls, "OptInType": $opt_in_type, "ProductionMessageSample": $production_message_sample, "TollfreePhoneNumberSid": $tollfree_phone_number_sid, "UseCaseCategories": $use_case_categories, "UseCaseSummary": $use_case_summary} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# GET /v1/Tollfree/Verifications/{Sid}
#
# operationId: FetchTollfreeVerification
export def "tollfree-verifications get" [
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
]: nothing -> record<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list<string>, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list<string>, use_case_summary: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Tollfree/Verifications/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /v1/Tollfree/Verifications/{Sid}
#
# operationId: UpdateTollfreeVerification
export def "tollfree-verifications update" [
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
  --additional-information: string # Additional information to be provided for verification.
  --business-city: string # The city of the business or organization using the Tollfree number.
  --business-contact-email: string # The email address of the contact for the business or organization using the Tollfree number.
  --business-contact-first-name: string # The first name of the contact for the business or organization using the Tollfree number.
  --business-contact-last-name: string # The last name of the contact for the business or organization using the Tollfree number.
  --business-contact-phone: string # The phone number of the contact for the business or organization using the Tollfree number. (format: phone-number)
  --business-country: string # The country of the business or organization using the Tollfree number.
  --business-name: string # The name of the business or organization using the Tollfree number.
  --business-postal-code: string # The postal code of the business or organization using the Tollfree number.
  --business-state-province-region: string # The state/province/region of the business or organization using the Tollfree number.
  --business-street-address: string # The address of the business or organization using the Tollfree number.
  --business-street-address2: string # The address of the business or organization using the Tollfree number.
  --business-website: string # The website of the business or organization using the Tollfree number.
  --message-volume: string # Estimate monthly volume of messages from the Tollfree Number.
  --notification-email: string # The email address to receive the notification about the verification result. .
  --opt-in-image-urls: list<string> # Link to an image that shows the opt-in workflow. Multiple images allowed and must be a publicly hosted URL.
  --opt-in-type: string@opt-in-type-completer
  --production-message-sample: string # An example of message content, i.e. a sample message.
  --use-case-categories: list<string> # The category of the use case for the Tollfree Number. List as many are applicable..
  --use-case-summary: string # Use this to further explain how messaging is used by the business or organization.
]: any -> record<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list<string>, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list<string>, use_case_summary: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Tollfree/Verifications/{sid}"))
  let req_body = {"AdditionalInformation": $additional_information, "BusinessCity": $business_city, "BusinessContactEmail": $business_contact_email, "BusinessContactFirstName": $business_contact_first_name, "BusinessContactLastName": $business_contact_last_name, "BusinessContactPhone": $business_contact_phone, "BusinessCountry": $business_country, "BusinessName": $business_name, "BusinessPostalCode": $business_postal_code, "BusinessStateProvinceRegion": $business_state_province_region, "BusinessStreetAddress": $business_street_address, "BusinessStreetAddress2": $business_street_address2, "BusinessWebsite": $business_website, "MessageVolume": $message_volume, "NotificationEmail": $notification_email, "OptInImageUrls": $opt_in_image_urls, "OptInType": $opt_in_type, "ProductionMessageSample": $production_message_sample, "UseCaseCategories": $use_case_categories, "UseCaseSummary": $use_case_summary} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# GET /v1/a2p/BrandRegistrations
#
# operationId: ListBrandRegistrations
export def "a2p-brand-registrations list" [
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
]: nothing -> record<data: table<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/a2p/BrandRegistrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /v1/a2p/BrandRegistrations
#
# operationId: CreateBrandRegistrations
export def "a2p-brand-registrations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  a2p_profile_bundle_sid: string # A2P Messaging Profile Bundle Sid.
  --brand-type: string # Type of brand being created. One of: "STANDARD", "SOLE_PROPRIETOR". SOLE_PROPRIETOR is for low volume, SOLE_PROPRIETOR use cases. STANDARD is for all other use cases.
  customer_profile_bundle_sid: string # Customer Profile Bundle Sid.
  --mock: oneof<nothing, bool> # A boolean that specifies whether brand should be a mock or not. If true, brand will be registered as a mock brand. Defaults to false if no value is provided.
  --skip-automatic-sec-vet: oneof<nothing, bool> # A flag to disable automatic secondary vetting for brands which it would otherwise be done.
]: any -> record<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list<string>, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/a2p/BrandRegistrations")
  let req_body = {"A2PProfileBundleSid": $a2p_profile_bundle_sid, "BrandType": $brand_type, "CustomerProfileBundleSid": $customer_profile_bundle_sid, "Mock": $mock, "SkipAutomaticSecVet": $skip_automatic_sec_vet} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# POST /v1/a2p/BrandRegistrations/{BrandRegistrationSid}/SmsOtp
#
# operationId: CreateBrandRegistrationOtp
export def "a2p-brand-registrations-sms-otp create" [
  brand_registration_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, brand_registration_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({brand_registration_sid: (encode-path-segment $brand_registration_sid)} | format pattern "/v1/a2p/BrandRegistrations/{brand_registration_sid}/SmsOtp"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /v1/a2p/BrandRegistrations/{BrandSid}/Vettings
#
# operationId: ListBrandVetting
export def "a2p-brand-registrations-vettings list" [
  brand_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vetting-provider: string@vetting-provider-completer # The third-party provider of the vettings to read
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<data: table<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_created: string, date_updated: string, url: string, vetting_class: string, vetting_id: string, vetting_provider: string, vetting_status: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "VettingProvider" $vetting_provider "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({brand_sid: (encode-path-segment $brand_sid)} | format pattern "/v1/a2p/BrandRegistrations/{brand_sid}/Vettings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /v1/a2p/BrandRegistrations/{BrandSid}/Vettings
#
# operationId: CreateBrandVetting
export def "a2p-brand-registrations-vettings create" [
  brand_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vetting-id: string # The unique ID of the vetting
  vetting_provider: string@vetting-provider-completer
]: any -> record<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_created: string, date_updated: string, url: string, vetting_class: string, vetting_id: string, vetting_provider: string, vetting_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({brand_sid: (encode-path-segment $brand_sid)} | format pattern "/v1/a2p/BrandRegistrations/{brand_sid}/Vettings"))
  let req_body = {"VettingId": $vetting_id, "VettingProvider": $vetting_provider} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# GET /v1/a2p/BrandRegistrations/{BrandSid}/Vettings/{BrandVettingSid}
#
# operationId: FetchBrandVetting
export def "a2p-brand-registrations-vettings get" [
  brand_sid: string
  brand_vetting_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_created: string, date_updated: string, url: string, vetting_class: string, vetting_id: string, vetting_provider: string, vetting_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({brand_sid: (encode-path-segment $brand_sid), brand_vetting_sid: (encode-path-segment $brand_vetting_sid)} | format pattern "/v1/a2p/BrandRegistrations/{brand_sid}/Vettings/{brand_vetting_sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /v1/a2p/BrandRegistrations/{Sid}
#
# operationId: FetchBrandRegistrations
export def "a2p-brand-registrations get" [
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
]: nothing -> record<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list<string>, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/a2p/BrandRegistrations/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /v1/a2p/BrandRegistrations/{Sid}
#
# operationId: UpdateBrandRegistrations
export def "a2p-brand-registrations update" [
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
]: nothing -> record<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list<string>, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/a2p/BrandRegistrations/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
