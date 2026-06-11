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
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://messaging.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def FallbackMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def InboundMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def ScanMessageContent-completer [] { ["disable" "enable" "inherit"] }
def OptInType-completer [] { ["MOBILE_QR_CODE" "PAPER_FORM" "VERBAL" "VIA_TEXT" "WEB_FORM"] }
def VettingProvider-completer [] { ["campaign-verify"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "deactivations FetchDeactivation" } } | get name | first)
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
export def "deactivations FetchDeactivation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Date: string # The request will return a list of all United States Phone Numbers that were deactivated on the day specified by this parameter. This date should be specified in YYYY-MM-DD format. (format: date)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "Date" $Date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Deactivations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /v1/LinkShortening/Domains/{DomainSid}/Certificate
#
# operationId: DeleteDomainCertV4
export def "link-shortening-domains-certificate DeleteDomainCertV4" [
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/Certificate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/LinkShortening/Domains/{DomainSid}/Certificate
#
# operationId: FetchDomainCertV4
export def "link-shortening-domains-certificate FetchDomainCertV4" [
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cert_in_validation: any, certificate_sid: string, date_created: string, date_expires: string, date_updated: string, domain_name: string, domain_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/Certificate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/LinkShortening/Domains/{DomainSid}/Certificate
#
# operationId: UpdateDomainCertV4
export def "link-shortening-domains-certificate UpdateDomainCertV4" [
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  TlsCert: string # Contains the full TLS certificate and private for this domain in PEM format: https://en.wikipedia.org/wiki/Privacy-Enhanced_Mail. Twilio uses this information to process HTTPS traffic sent to your domain.
]: any -> record<cert_in_validation: any, certificate_sid: string, date_created: string, date_expires: string, date_updated: string, domain_name: string, domain_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/Certificate")
  let body = {TlsCert: $TlsCert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/LinkShortening/Domains/{DomainSid}/Config
#
# operationId: FetchDomainConfig
export def "link-shortening-domains-config FetchDomainConfig" [
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<callback_url: string, config_sid: string, date_created: string, date_updated: string, domain_sid: string, fallback_url: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/Config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/LinkShortening/Domains/{DomainSid}/Config
#
# operationId: UpdateDomainConfig
export def "link-shortening-domains-config UpdateDomainConfig" [
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --CallbackUrl: string # URL to receive click events to your webhook whenever the recipients click on the shortened links (format: uri)
  --FallbackUrl: string # Any requests we receive to this domain that do not match an existing shortened message will be redirected to the fallback url. These will likely be either expired messages, random misdirected traffic, or intentional scraping. (format: uri)
]: any -> record<callback_url: string, config_sid: string, date_created: string, date_updated: string, domain_sid: string, fallback_url: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/Config")
  let body = {CallbackUrl: $CallbackUrl, FallbackUrl: $FallbackUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/LinkShortening/Domains/{DomainSid}/MessagingServices/{MessagingServiceSid}
#
# operationId: DeleteLinkshorteningMessagingService
export def "link-shortening-domains-messaging-services DeleteLinkshorteningMessagingService" [
  DomainSid: string
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/MessagingServices/($MessagingServiceSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/LinkShortening/Domains/{DomainSid}/MessagingServices/{MessagingServiceSid}
#
# operationId: CreateLinkshorteningMessagingService
export def "link-shortening-domains-messaging-services CreateLinkshorteningMessagingService" [
  DomainSid: string
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<domain_sid: string, messaging_service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/MessagingServices/($MessagingServiceSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/LinkShortening/MessagingService/{MessagingServiceSid}/DomainConfig
#
# operationId: FetchDomainConfigMessagingService
export def "link-shortening-messaging-service-domain-config FetchDomainConfigMessagingService" [
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<callback_url: string, config_sid: string, date_created: string, date_updated: string, domain_sid: string, fallback_url: string, messaging_service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/MessagingService/($MessagingServiceSid)/DomainConfig")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --AreaCodeGeomatch: string@bool-completer # Whether to enable [Area Code Geomatch](https://www.twilio.com/docs/sms/services#area-code-geomatch) on the Service Instance.
  --FallbackMethod: string@FallbackMethod-completer # The HTTP method we should use to call `fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --FallbackToLongCode: string@bool-completer # Whether to enable [Fallback to Long Code](https://www.twilio.com/docs/sms/services#fallback-to-long-code) for messages sent through the Service instance.
  --FallbackUrl: string # The URL that we call using `fallback_method` if an error occurs while retrieving or executing the TwiML from the Inbound Request URL. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `fallback_url` defined for the Messaging Service. (format: uri)
  FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --InboundMethod: string@InboundMethod-completer # The HTTP method we should use to call `inbound_request_url`. Can be `GET` or `POST` and the default is `POST`. (format: http-method)
  --InboundRequestUrl: string # The URL we call using `inbound_method` when a message is received by any phone number or short code in the Service. When this property is `null`, receiving inbound messages is disabled. All messages sent to the Twilio phone number or short code will not be logged and received on the Account. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `inbound_request_url` defined for the Messaging Service. (format: uri)
  --MmsConverter: string@bool-completer # Whether to enable the [MMS Converter](https://www.twilio.com/docs/sms/services#mms-converter) for messages sent through the Service instance.
  --ScanMessageContent: string@ScanMessageContent-completer
  --SmartEncoding: string@bool-completer # Whether to enable [Smart Encoding](https://www.twilio.com/docs/sms/services#smart-encoding) for messages sent through the Service instance.
  --StatusCallback: string # The URL we should call to [pass status updates](https://www.twilio.com/docs/sms/api/message-resource#message-status-values) about message delivery. (format: uri)
  --StickySender: string@bool-completer # Whether to enable [Sticky Sender](https://www.twilio.com/docs/sms/services#sticky-sender) on the Service instance.
  --SynchronousValidation: string@bool-completer # Reserved.
  --UseInboundWebhookOnNumber: string@bool-completer # A boolean value that indicates either the webhook url configured on the phone number will be used or `inbound_request_url`/`fallback_url` url will be called when a message is received from the phone number. If this field is enabled then the webhook url defined on the phone number will override the `inbound_request_url`/`fallback_url` defined for the Messaging Service.
  --Usecase: string # A string that describes the scenario in which the Messaging Service will be used. Examples: [notification, marketing, verification, poll ..].
  --ValidityPeriod: int # How long, in seconds, messages sent from the Service are valid. Can be an integer from `1` to `14,400`.
]: any -> record<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/Services")
  let body = {AreaCodeGeomatch: $AreaCodeGeomatch, FallbackMethod: $FallbackMethod, FallbackToLongCode: $FallbackToLongCode, FallbackUrl: $FallbackUrl, FriendlyName: $FriendlyName, InboundMethod: $InboundMethod, InboundRequestUrl: $InboundRequestUrl, MmsConverter: $MmsConverter, ScanMessageContent: $ScanMessageContent, SmartEncoding: $SmartEncoding, StatusCallback: $StatusCallback, StickySender: $StickySender, SynchronousValidation: $SynchronousValidation, UseInboundWebhookOnNumber: $UseInboundWebhookOnNumber, Usecase: $Usecase, ValidityPeriod: $ValidityPeriod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# POST /v1/Services/PreregisteredUsa2p
#
# operationId: CreateExternalCampaign
export def "services-preregistered-usa2p CreateExternalCampaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  CampaignId: string # ID of the preregistered campaign.
  MessagingServiceSid: string # The SID of the [Messaging Service](https://www.twilio.com/docs/messaging/services/api) that the resource is associated with.
]: any -> record<account_sid: string, campaign_id: string, date_created: string, messaging_service_sid: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/Services/PreregisteredUsa2p")
  let body = {CampaignId: $CampaignId, MessagingServiceSid: $MessagingServiceSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/Usecases
#
# operationId: FetchUsecase
export def "services-usecases FetchUsecase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usecases: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/Services/Usecases")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/Services/{MessagingServiceSid}/Compliance/Usa2p
#
# operationId: ListUsAppToPerson
export def "services-compliance-usa2p ListUsAppToPerson" [
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<compliance: table<account_sid: string, brand_registration_sid: string, campaign_id: string, campaign_status: string, date_created: string, date_updated: string, description: string, has_embedded_links: bool, has_embedded_phone: bool, help_keywords: list, help_message: string, is_externally_registered: bool, message_flow: string, message_samples: list, messaging_service_sid: string, mock: bool, opt_in_keywords: list, opt_in_message: string, opt_out_keywords: list, opt_out_message: string, rate_limits: any, sid: string, url: string, us_app_to_person_usecase: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/Compliance/Usa2p" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/Services/{MessagingServiceSid}/Compliance/Usa2p
#
# operationId: CreateUsAppToPerson
export def "services-compliance-usa2p CreateUsAppToPerson" [
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  BrandRegistrationSid: string # A2P Brand Registration SID
  Description: string # A short description of what this SMS campaign does. Min length: 40 characters. Max length: 4096 characters.
  --HasEmbeddedLinks: string@bool-completer # Indicates that this SMS campaign will send messages that contain links.
  --HasEmbeddedPhone: string@bool-completer # Indicates that this SMS campaign will send messages that contain phone numbers.
  --HelpKeywords: list # End users should be able to text in a keyword to receive help. Those keywords must be provided as part of the campaign registration request. This field is required if managing help keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). Values must be alphanumeric. 255 character maximum.
  --HelpMessage: string # When customers receive the help keywords from their end users, Twilio customers are expected to send back an auto-generated response; this may include the brand name and additional support contact information. This field is required if managing help keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). 20 character minimum. 320 character maximum.
  MessageFlow: string # Required for all Campaigns. Details around how a consumer opts-in to their campaign, therefore giving consent to receive their messages. If multiple opt-in methods can be used for the same campaign, they must all be listed. 40 character minimum. 2048 character maximum.
  MessageSamples: list # Message samples, at least 1 and up to 5 sample messages (at least 2 for sole proprietor), >=20 chars, <=1024 chars each.
  --OptInKeywords: list # If end users can text in a keyword to start receiving messages from this campaign, those keywords must be provided. This field is required if end users can text in a keyword to start receiving messages from this campaign. Values must be alphanumeric. 255 character maximum.
  --OptInMessage: string # If end users can text in a keyword to start receiving messages from this campaign, the auto-reply messages sent to the end users must be provided. The opt-in response should include the Brand name, confirmation of opt-in enrollment to a recurring message campaign, how to get help, and clear description of how to opt-out. This field is required if end users can text in a keyword to start receiving messages from this campaign. 20 character minimum. 320 character maximum.
  --OptOutKeywords: list # End users should be able to text in a keyword to stop receiving messages from this campaign. Those keywords must be provided. This field is required if managing opt out keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). Values must be alphanumeric. 255 character maximum.
  --OptOutMessage: string # Upon receiving the opt-out keywords from the end users, Twilio customers are expected to send back an auto-generated response, which must provide acknowledgment of the opt-out request and confirmation that no further messages will be sent. It is also recommended that these opt-out messages include the brand name. This field is required if managing opt out keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). 20 character minimum. 320 character maximum.
  UsAppToPersonUsecase: string # A2P Campaign Use Case. Examples: [ 2FA, EMERGENCY, MARKETING..]
]: any -> record<account_sid: string, brand_registration_sid: string, campaign_id: string, campaign_status: string, date_created: string, date_updated: string, description: string, has_embedded_links: bool, has_embedded_phone: bool, help_keywords: list<string>, help_message: string, is_externally_registered: bool, message_flow: string, message_samples: list<string>, messaging_service_sid: string, mock: bool, opt_in_keywords: list<string>, opt_in_message: string, opt_out_keywords: list<string>, opt_out_message: string, rate_limits: any, sid: string, url: string, us_app_to_person_usecase: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/Compliance/Usa2p")
  let body = {BrandRegistrationSid: $BrandRegistrationSid, Description: $Description, HasEmbeddedLinks: $HasEmbeddedLinks, HasEmbeddedPhone: $HasEmbeddedPhone, HelpKeywords: $HelpKeywords, HelpMessage: $HelpMessage, MessageFlow: $MessageFlow, MessageSamples: $MessageSamples, OptInKeywords: $OptInKeywords, OptInMessage: $OptInMessage, OptOutKeywords: $OptOutKeywords, OptOutMessage: $OptOutMessage, UsAppToPersonUsecase: $UsAppToPersonUsecase} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{MessagingServiceSid}/Compliance/Usa2p/Usecases
#
# operationId: FetchUsAppToPersonUsecase
export def "services-compliance-usa2p-usecases FetchUsAppToPersonUsecase" [
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --BrandRegistrationSid: string # The unique string to identify the A2P brand.
]: nothing -> record<us_app_to_person_usecases: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "BrandRegistrationSid" $BrandRegistrationSid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/Compliance/Usa2p/Usecases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /v1/Services/{MessagingServiceSid}/Compliance/Usa2p/{Sid}
#
# operationId: DeleteUsAppToPerson
export def "services-compliance-usa2p DeleteUsAppToPerson" [
  MessagingServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/Compliance/Usa2p/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/Services/{MessagingServiceSid}/Compliance/Usa2p/{Sid}
#
# operationId: FetchUsAppToPerson
export def "services-compliance-usa2p FetchUsAppToPerson" [
  MessagingServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, brand_registration_sid: string, campaign_id: string, campaign_status: string, date_created: string, date_updated: string, description: string, has_embedded_links: bool, has_embedded_phone: bool, help_keywords: list<string>, help_message: string, is_externally_registered: bool, message_flow: string, message_samples: list<string>, messaging_service_sid: string, mock: bool, opt_in_keywords: list<string>, opt_in_message: string, opt_out_keywords: list<string>, opt_out_message: string, rate_limits: any, sid: string, url: string, us_app_to_person_usecase: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/Compliance/Usa2p/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/AlphaSenders
#
# operationId: ListAlphaSender
export def "services-alpha-senders ListAlphaSender" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<alpha_senders: table<account_sid: string, alpha_sender: string, capabilities: list, date_created: string, date_updated: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/AlphaSenders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/AlphaSenders
#
# operationId: CreateAlphaSender
export def "services-alpha-senders CreateAlphaSender" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  AlphaSender: string # The Alphanumeric Sender ID string. Can be up to 11 characters long. Valid characters are A-Z, a-z, 0-9, space, hyphen `-`, plus `+`, underscore `_` and ampersand `&`. This value cannot contain only numbers.
]: any -> record<account_sid: string, alpha_sender: string, capabilities: list<string>, date_created: string, date_updated: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/AlphaSenders")
  let body = {AlphaSender: $AlphaSender} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Services/{ServiceSid}/AlphaSenders/{Sid}
#
# operationId: DeleteAlphaSender
export def "services-alpha-senders DeleteAlphaSender" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/AlphaSenders/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/AlphaSenders/{Sid}
#
# operationId: FetchAlphaSender
export def "services-alpha-senders FetchAlphaSender" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, alpha_sender: string, capabilities: list<string>, date_created: string, date_updated: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/AlphaSenders/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/PhoneNumbers
#
# operationId: ListPhoneNumber
export def "services-phone-numbers ListPhoneNumber" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, phone_numbers: table<account_sid: string, capabilities: list, country_code: string, date_created: string, date_updated: string, phone_number: string, service_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/PhoneNumbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/PhoneNumbers
#
# operationId: CreatePhoneNumber
export def "services-phone-numbers CreatePhoneNumber" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  PhoneNumberSid: string # The SID of the Phone Number being added to the Service.
]: any -> record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, phone_number: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/PhoneNumbers")
  let body = {PhoneNumberSid: $PhoneNumberSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Services/{ServiceSid}/PhoneNumbers/{Sid}
#
# operationId: DeletePhoneNumber
export def "services-phone-numbers DeletePhoneNumber" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/PhoneNumbers/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/PhoneNumbers/{Sid}
#
# operationId: FetchPhoneNumber
export def "services-phone-numbers FetchPhoneNumber" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, phone_number: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/PhoneNumbers/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/ShortCodes
#
# operationId: ListShortCode
export def "services-short-codes ListShortCode" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, short_codes: table<account_sid: string, capabilities: list, country_code: string, date_created: string, date_updated: string, service_sid: string, short_code: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/ShortCodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/ShortCodes
#
# operationId: CreateShortCode
export def "services-short-codes CreateShortCode" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ShortCodeSid: string # The SID of the ShortCode resource being added to the Service.
]: any -> record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, service_sid: string, short_code: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/ShortCodes")
  let body = {ShortCodeSid: $ShortCodeSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Services/{ServiceSid}/ShortCodes/{Sid}
#
# operationId: DeleteShortCode
export def "services-short-codes DeleteShortCode" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/ShortCodes/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/ShortCodes/{Sid}
#
# operationId: FetchShortCode
export def "services-short-codes FetchShortCode" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, capabilities: list<string>, country_code: string, date_created: string, date_updated: string, service_sid: string, short_code: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/ShortCodes/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --AreaCodeGeomatch: string@bool-completer # Whether to enable [Area Code Geomatch](https://www.twilio.com/docs/sms/services#area-code-geomatch) on the Service Instance.
  --FallbackMethod: string@FallbackMethod-completer # The HTTP method we should use to call `fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --FallbackToLongCode: string@bool-completer # Whether to enable [Fallback to Long Code](https://www.twilio.com/docs/sms/services#fallback-to-long-code) for messages sent through the Service instance.
  --FallbackUrl: string # The URL that we call using `fallback_method` if an error occurs while retrieving or executing the TwiML from the Inbound Request URL. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `fallback_url` defined for the Messaging Service. (format: uri)
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --InboundMethod: string@InboundMethod-completer # The HTTP method we should use to call `inbound_request_url`. Can be `GET` or `POST` and the default is `POST`. (format: http-method)
  --InboundRequestUrl: string # The URL we call using `inbound_method` when a message is received by any phone number or short code in the Service. When this property is `null`, receiving inbound messages is disabled. All messages sent to the Twilio phone number or short code will not be logged and received on the Account. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `inbound_request_url` defined for the Messaging Service. (format: uri)
  --MmsConverter: string@bool-completer # Whether to enable the [MMS Converter](https://www.twilio.com/docs/sms/services#mms-converter) for messages sent through the Service instance.
  --ScanMessageContent: string@ScanMessageContent-completer
  --SmartEncoding: string@bool-completer # Whether to enable [Smart Encoding](https://www.twilio.com/docs/sms/services#smart-encoding) for messages sent through the Service instance.
  --StatusCallback: string # The URL we should call to [pass status updates](https://www.twilio.com/docs/sms/api/message-resource#message-status-values) about message delivery. (format: uri)
  --StickySender: string@bool-completer # Whether to enable [Sticky Sender](https://www.twilio.com/docs/sms/services#sticky-sender) on the Service instance.
  --SynchronousValidation: string@bool-completer # Reserved.
  --UseInboundWebhookOnNumber: string@bool-completer # A boolean value that indicates either the webhook url configured on the phone number will be used or `inbound_request_url`/`fallback_url` url will be called when a message is received from the phone number. If this field is enabled then the webhook url defined on the phone number will override the `inbound_request_url`/`fallback_url` defined for the Messaging Service.
  --Usecase: string # A string that describes the scenario in which the Messaging Service will be used. Examples: [notification, marketing, verification, poll ..]
  --ValidityPeriod: int # How long, in seconds, messages sent from the Service are valid. Can be an integer from `1` to `14,400`.
]: any -> record<account_sid: string, area_code_geomatch: bool, date_created: string, date_updated: string, fallback_method: string, fallback_to_long_code: bool, fallback_url: string, friendly_name: string, inbound_method: string, inbound_request_url: string, links: record, mms_converter: bool, scan_message_content: string, sid: string, smart_encoding: bool, status_callback: string, sticky_sender: bool, synchronous_validation: bool, url: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool, usecase: string, validity_period: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let body = {AreaCodeGeomatch: $AreaCodeGeomatch, FallbackMethod: $FallbackMethod, FallbackToLongCode: $FallbackToLongCode, FallbackUrl: $FallbackUrl, FriendlyName: $FriendlyName, InboundMethod: $InboundMethod, InboundRequestUrl: $InboundRequestUrl, MmsConverter: $MmsConverter, ScanMessageContent: $ScanMessageContent, SmartEncoding: $SmartEncoding, StatusCallback: $StatusCallback, StickySender: $StickySender, SynchronousValidation: $SynchronousValidation, UseInboundWebhookOnNumber: $UseInboundWebhookOnNumber, Usecase: $Usecase, ValidityPeriod: $ValidityPeriod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Tollfree/Verifications
#
# operationId: ListTollfreeVerification
export def "tollfree-verifications ListTollfreeVerification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --TollfreePhoneNumberSid: string # The SID of the Phone Number associated with the Tollfree Verification.
  --Status: string # The compliance status of the Tollfree Verification record.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, verifications: table<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list, use_case_summary: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "TollfreePhoneNumberSid" $TollfreePhoneNumberSid "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Tollfree/Verifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/Tollfree/Verifications
#
# operationId: CreateTollfreeVerification
export def "tollfree-verifications CreateTollfreeVerification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --AdditionalInformation: string # Additional information to be provided for verification.
  --BusinessCity: string # The city of the business or organization using the Tollfree number.
  --BusinessContactEmail: string # The email address of the contact for the business or organization using the Tollfree number.
  --BusinessContactFirstName: string # The first name of the contact for the business or organization using the Tollfree number.
  --BusinessContactLastName: string # The last name of the contact for the business or organization using the Tollfree number.
  --BusinessContactPhone: string # The phone number of the contact for the business or organization using the Tollfree number. (format: phone-number)
  --BusinessCountry: string # The country of the business or organization using the Tollfree number.
  BusinessName: string # The name of the business or organization using the Tollfree number.
  --BusinessPostalCode: string # The postal code of the business or organization using the Tollfree number.
  --BusinessStateProvinceRegion: string # The state/province/region of the business or organization using the Tollfree number.
  --BusinessStreetAddress: string # The address of the business or organization using the Tollfree number.
  --BusinessStreetAddress2: string # The address of the business or organization using the Tollfree number.
  BusinessWebsite: string # The website of the business or organization using the Tollfree number.
  --CustomerProfileSid: string # Customer's Profile Bundle BundleSid.
  --ExternalReferenceId: string # An optional external reference ID supplied by customer and echoed back on status retrieval.
  MessageVolume: string # Estimate monthly volume of messages from the Tollfree Number.
  NotificationEmail: string # The email address to receive the notification about the verification result. .
  OptInImageUrls: list # Link to an image that shows the opt-in workflow. Multiple images allowed and must be a publicly hosted URL.
  OptInType: string@OptInType-completer
  ProductionMessageSample: string # An example of message content, i.e. a sample message.
  TollfreePhoneNumberSid: string # The SID of the Phone Number associated with the Tollfree Verification.
  UseCaseCategories: list # The category of the use case for the Tollfree Number. List as many are applicable..
  UseCaseSummary: string # Use this to further explain how messaging is used by the business or organization.
]: any -> record<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list<string>, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list<string>, use_case_summary: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/Tollfree/Verifications")
  let body = {AdditionalInformation: $AdditionalInformation, BusinessCity: $BusinessCity, BusinessContactEmail: $BusinessContactEmail, BusinessContactFirstName: $BusinessContactFirstName, BusinessContactLastName: $BusinessContactLastName, BusinessContactPhone: $BusinessContactPhone, BusinessCountry: $BusinessCountry, BusinessName: $BusinessName, BusinessPostalCode: $BusinessPostalCode, BusinessStateProvinceRegion: $BusinessStateProvinceRegion, BusinessStreetAddress: $BusinessStreetAddress, BusinessStreetAddress2: $BusinessStreetAddress2, BusinessWebsite: $BusinessWebsite, CustomerProfileSid: $CustomerProfileSid, ExternalReferenceId: $ExternalReferenceId, MessageVolume: $MessageVolume, NotificationEmail: $NotificationEmail, OptInImageUrls: $OptInImageUrls, OptInType: $OptInType, ProductionMessageSample: $ProductionMessageSample, TollfreePhoneNumberSid: $TollfreePhoneNumberSid, UseCaseCategories: $UseCaseCategories, UseCaseSummary: $UseCaseSummary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Tollfree/Verifications/{Sid}
#
# operationId: FetchTollfreeVerification
export def "tollfree-verifications FetchTollfreeVerification" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list<string>, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list<string>, use_case_summary: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Tollfree/Verifications/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/Tollfree/Verifications/{Sid}
#
# operationId: UpdateTollfreeVerification
export def "tollfree-verifications UpdateTollfreeVerification" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --AdditionalInformation: string # Additional information to be provided for verification.
  --BusinessCity: string # The city of the business or organization using the Tollfree number.
  --BusinessContactEmail: string # The email address of the contact for the business or organization using the Tollfree number.
  --BusinessContactFirstName: string # The first name of the contact for the business or organization using the Tollfree number.
  --BusinessContactLastName: string # The last name of the contact for the business or organization using the Tollfree number.
  --BusinessContactPhone: string # The phone number of the contact for the business or organization using the Tollfree number. (format: phone-number)
  --BusinessCountry: string # The country of the business or organization using the Tollfree number.
  --BusinessName: string # The name of the business or organization using the Tollfree number.
  --BusinessPostalCode: string # The postal code of the business or organization using the Tollfree number.
  --BusinessStateProvinceRegion: string # The state/province/region of the business or organization using the Tollfree number.
  --BusinessStreetAddress: string # The address of the business or organization using the Tollfree number.
  --BusinessStreetAddress2: string # The address of the business or organization using the Tollfree number.
  --BusinessWebsite: string # The website of the business or organization using the Tollfree number.
  --MessageVolume: string # Estimate monthly volume of messages from the Tollfree Number.
  --NotificationEmail: string # The email address to receive the notification about the verification result. .
  --OptInImageUrls: list # Link to an image that shows the opt-in workflow. Multiple images allowed and must be a publicly hosted URL.
  --OptInType: string@OptInType-completer
  --ProductionMessageSample: string # An example of message content, i.e. a sample message.
  --UseCaseCategories: list # The category of the use case for the Tollfree Number. List as many are applicable..
  --UseCaseSummary: string # Use this to further explain how messaging is used by the business or organization.
]: any -> record<account_sid: string, additional_information: string, business_city: string, business_contact_email: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_phone: string, business_country: string, business_name: string, business_postal_code: string, business_state_province_region: string, business_street_address: string, business_street_address2: string, business_website: string, customer_profile_sid: string, date_created: string, date_updated: string, error_code: int, external_reference_id: string, message_volume: string, notification_email: string, opt_in_image_urls: list<string>, opt_in_type: string, production_message_sample: string, regulated_item_sid: string, rejection_reason: string, resource_links: any, sid: string, status: string, tollfree_phone_number_sid: string, trust_product_sid: string, url: string, use_case_categories: list<string>, use_case_summary: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Tollfree/Verifications/($Sid)")
  let body = {AdditionalInformation: $AdditionalInformation, BusinessCity: $BusinessCity, BusinessContactEmail: $BusinessContactEmail, BusinessContactFirstName: $BusinessContactFirstName, BusinessContactLastName: $BusinessContactLastName, BusinessContactPhone: $BusinessContactPhone, BusinessCountry: $BusinessCountry, BusinessName: $BusinessName, BusinessPostalCode: $BusinessPostalCode, BusinessStateProvinceRegion: $BusinessStateProvinceRegion, BusinessStreetAddress: $BusinessStreetAddress, BusinessStreetAddress2: $BusinessStreetAddress2, BusinessWebsite: $BusinessWebsite, MessageVolume: $MessageVolume, NotificationEmail: $NotificationEmail, OptInImageUrls: $OptInImageUrls, OptInType: $OptInType, ProductionMessageSample: $ProductionMessageSample, UseCaseCategories: $UseCaseCategories, UseCaseSummary: $UseCaseSummary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/a2p/BrandRegistrations
#
# operationId: ListBrandRegistrations
export def "a2p-brand-registrations ListBrandRegistrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<data: table<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/a2p/BrandRegistrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/a2p/BrandRegistrations
#
# operationId: CreateBrandRegistrations
export def "a2p-brand-registrations CreateBrandRegistrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  A2PProfileBundleSid: string # A2P Messaging Profile Bundle Sid.
  --BrandType: string # Type of brand being created. One of: "STANDARD", "SOLE_PROPRIETOR". SOLE_PROPRIETOR is for low volume, SOLE_PROPRIETOR use cases. STANDARD is for all other use cases.
  CustomerProfileBundleSid: string # Customer Profile Bundle Sid.
  --Mock: string@bool-completer # A boolean that specifies whether brand should be a mock or not. If true, brand will be registered as a mock brand. Defaults to false if no value is provided.
  --SkipAutomaticSecVet: string@bool-completer # A flag to disable automatic secondary vetting for brands which it would otherwise be done.
]: any -> record<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list<string>, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/a2p/BrandRegistrations")
  let body = {A2PProfileBundleSid: $A2PProfileBundleSid, BrandType: $BrandType, CustomerProfileBundleSid: $CustomerProfileBundleSid, Mock: $Mock, SkipAutomaticSecVet: $SkipAutomaticSecVet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# POST /v1/a2p/BrandRegistrations/{BrandRegistrationSid}/SmsOtp
#
# operationId: CreateBrandRegistrationOtp
export def "a2p-brand-registrations-sms-otp CreateBrandRegistrationOtp" [
  BrandRegistrationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, brand_registration_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/a2p/BrandRegistrations/($BrandRegistrationSid)/SmsOtp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/a2p/BrandRegistrations/{BrandSid}/Vettings
#
# operationId: ListBrandVetting
export def "a2p-brand-registrations-vettings ListBrandVetting" [
  BrandSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --VettingProvider: string # The third-party provider of the vettings to read
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<data: table<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_created: string, date_updated: string, url: string, vetting_class: string, vetting_id: string, vetting_provider: string, vetting_status: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "VettingProvider" $VettingProvider "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/a2p/BrandRegistrations/($BrandSid)/Vettings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/a2p/BrandRegistrations/{BrandSid}/Vettings
#
# operationId: CreateBrandVetting
export def "a2p-brand-registrations-vettings CreateBrandVetting" [
  BrandSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --VettingId: string # The unique ID of the vetting
  VettingProvider: string@VettingProvider-completer
]: any -> record<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_created: string, date_updated: string, url: string, vetting_class: string, vetting_id: string, vetting_provider: string, vetting_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/a2p/BrandRegistrations/($BrandSid)/Vettings")
  let body = {VettingId: $VettingId, VettingProvider: $VettingProvider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/a2p/BrandRegistrations/{BrandSid}/Vettings/{BrandVettingSid}
#
# operationId: FetchBrandVetting
export def "a2p-brand-registrations-vettings FetchBrandVetting" [
  BrandSid: string
  BrandVettingSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_created: string, date_updated: string, url: string, vetting_class: string, vetting_id: string, vetting_provider: string, vetting_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/a2p/BrandRegistrations/($BrandSid)/Vettings/($BrandVettingSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/a2p/BrandRegistrations/{Sid}
#
# operationId: FetchBrandRegistrations
export def "a2p-brand-registrations FetchBrandRegistrations" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list<string>, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/a2p/BrandRegistrations/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/a2p/BrandRegistrations/{Sid}
#
# operationId: UpdateBrandRegistrations
export def "a2p-brand-registrations UpdateBrandRegistrations" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<a2p_profile_bundle_sid: string, account_sid: string, brand_feedback: list<string>, brand_score: int, brand_type: string, customer_profile_bundle_sid: string, date_created: string, date_updated: string, failure_reason: string, government_entity: bool, identity_status: string, links: record, mock: bool, russell_3000: bool, sid: string, skip_automatic_sec_vet: bool, status: string, tax_exempt_status: string, tcr_id: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/a2p/BrandRegistrations/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
